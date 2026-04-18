import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Services/UsageLimitsService.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

/// Pantalla de bloqueo que se muestra cuando se alcanza el límite diario
class UsageLimitBlockedScreen extends StatefulWidget {
  final VoidCallback? onTimeAdded;
  final VoidCallback? onBlockRemoved;

  const UsageLimitBlockedScreen({
    super.key,
    this.onTimeAdded,
    this.onBlockRemoved,
  });

  @override
  State<UsageLimitBlockedScreen> createState() => _UsageLimitBlockedScreenState();
}

class _UsageLimitBlockedScreenState extends State<UsageLimitBlockedScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isAddingTime = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _animationController.value = 1.0;
      } else {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Agregar 10 minutos más al límite del día actual
  Future<void> _addExtraTime() async {
    if (_isAddingTime) return;

    setState(() {
      _isAddingTime = true;
    });

    try {
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final supabase = Supabase.instance.client;
      
      // Obtener el usuario actual
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ Error: Usuario no autenticado');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: Usuario no autenticado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() {
          _isAddingTime = false;
        });
        return;
      }

      // Obtener el límite actual del día
      final todayUsage = await UsageLimitsService.getOrCreateTodayUsage();
      if (todayUsage == null) {
        debugPrint('❌ Error: No se pudo obtener el registro del día');
        setState(() {
          _isAddingTime = false;
        });
        return;
      }

      final currentLimit = todayUsage['limite_del_dia_minutos'] as int? ?? 0;
      final newLimit = currentLimit + 10;
      final limiteAnterior = currentLimit; // Guardar el límite anterior para verificación
      
      // Obtener la fecha del registro actual (puede ser de ayer si es temprano)
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      final fechaRegistro = todayUsage['fecha'] as String?;
      final fechaAUsar = fechaRegistro ?? todayString;

      debugPrint('➕ Agregando 10 minutos:');
      debugPrint('   Límite actual: $limiteAnterior minutos');
      debugPrint('   Nuevo límite: $newLimit minutos');
      debugPrint('   Fecha del registro: $fechaRegistro');
      debugPrint('   Fecha a usar para actualizar: $fechaAUsar');

      // Actualizar el límite del día actual en registros_uso_diario
      // Usar la fecha del registro actual, no la fecha de hoy (puede ser de ayer)
      final updateResult = await supabase
          .from('registros_uso_diario')
          .update({
            'limite_del_dia_minutos': newLimit,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('usuario_id', userId)
          .eq('fecha', fechaAUsar) // Usar la fecha del registro, no la fecha de hoy
          .select();
      
      debugPrint('📅 Actualizando registro con fecha: $fechaAUsar');

      debugPrint('✅ Actualización en BD: $updateResult');

      // Esperar un momento para que se actualice en la BD
      await Future.delayed(const Duration(milliseconds: 1500));

      // Leer DIRECTAMENTE de la tabla sin usar la función RPC (para evitar caché)
      // Usar la misma fecha que se usó para actualizar
      final verifyUsage = await supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .eq('fecha', fechaAUsar) // Usar la misma fecha que se actualizó
          .maybeSingle();

      if (verifyUsage != null) {
        final verifyLimit = verifyUsage['limite_del_dia_minutos'] as int? ?? 0;
        final verifyUsed = verifyUsage['tiempo_usado_minutos'] as int? ?? 0;
        debugPrint('🔍 Verificación DIRECTA después de agregar tiempo:');
        debugPrint('   Límite del día: $verifyLimit minutos');
        debugPrint('   Tiempo usado (BD): $verifyUsed minutos');
        
        if (verifyLimit != newLimit) {
          debugPrint('⚠️ ADVERTENCIA: El límite no se actualizó correctamente!');
          debugPrint('   Esperado: $newLimit minutos');
          debugPrint('   Obtenido: $verifyLimit minutos');
        }
      } else {
        debugPrint('❌ Error: No se encontró el registro después de actualizar');
      }

      // Verificar que el límite se actualizó correctamente
      bool limiteActualizado = false;
      if (verifyUsage != null) {
        final verifyLimit = verifyUsage['limite_del_dia_minutos'] as int? ?? 0;
        final verifyUsed = verifyUsage['tiempo_usado_minutos'] as int? ?? 0;
        if (verifyLimit == newLimit) {
          limiteActualizado = true;
          debugPrint('✅ Límite actualizado correctamente en BD: $newLimit minutos');
          debugPrint('   Tiempo usado en BD: $verifyUsed minutos');
          
          // Si el tiempo usado es mayor que el nuevo límite, puede ser por sesiones activas
          if (verifyUsed > newLimit) {
            debugPrint('⚠️ ADVERTENCIA: Tiempo usado ($verifyUsed min) es mayor que el nuevo límite ($newLimit min)');
            debugPrint('   Esto puede deberse a sesiones activas que están sumando tiempo');
            
            // Verificar sesiones activas
            final activeSessions = await UsageLimitsService.getActiveSessions();
            if (activeSessions.isNotEmpty) {
              debugPrint('   Sesiones activas encontradas: ${activeSessions.length}');
              for (var session in activeSessions) {
                final inicioSesion = session['inicio_sesion'] as String?;
                if (inicioSesion != null) {
                  try {
                    final inicio = DateTime.parse(inicioSesion);
                    final tiempoTranscurrido = DateTime.now().difference(inicio).inMinutes;
                    debugPrint('     - Sesión activa: $tiempoTranscurrido minutos transcurridos');
                  } catch (e) {
                    debugPrint('     - Error al calcular tiempo de sesión: $e');
                  }
                }
              }
            }
          }
        } else {
          debugPrint('⚠️ El límite no se actualizó. Esperado: $newLimit, Obtenido: $verifyLimit');
        }
      }

      // Si el límite no se actualizó, mostrar error
      if (!limiteActualizado) {
        debugPrint('❌ Error: El límite no se actualizó en la BD');
        if (mounted) {
          setState(() {
            _isAddingTime = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo actualizar el límite. Intenta de nuevo.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Forzar recarga completa de datos DESPUÉS de verificar
      // Esperar un momento adicional para que Supabase se sincronice completamente
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Recargar datos desde Supabase directamente (esto actualiza el límite del día)
      await appProvider.refreshUsageLimits();
      await appProvider.updateTodayUsage();
      
      // Esperar un poco más antes de verificar el tiempo restante
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Calcular tiempo restante manualmente usando los datos actualizados
      // Esto nos da más control sobre el cálculo
      final updatedUsage = await supabase
          .from('registros_uso_diario')
          .select()
          .eq('usuario_id', userId)
          .eq('fecha', fechaAUsar)
          .maybeSingle();

      int verifyRemaining = 0;
      if (updatedUsage != null) {
        final updatedLimit = updatedUsage['limite_del_dia_minutos'] as int? ?? 0;
        final updatedUsed = updatedUsage['tiempo_usado_minutos'] as int? ?? 0;
        
        // Obtener tiempo de sesión activa
        final activeSessions = await UsageLimitsService.getActiveSessions();
        var tiempoSesionActiva = 0;
        if (activeSessions.isNotEmpty) {
          debugPrint('🔍 Sesiones activas encontradas: ${activeSessions.length}');
          for (var session in activeSessions) {
            final inicioSesion = session['inicio_sesion'] as String?;
            if (inicioSesion != null) {
              try {
                final inicio = DateTime.parse(inicioSesion);
                final tiempoTranscurrido = DateTime.now().difference(inicio).inMinutes;
                tiempoSesionActiva += tiempoTranscurrido;
                debugPrint('   - Sesión: $tiempoTranscurrido minutos transcurridos');
              } catch (e) {
                debugPrint('⚠️ Error al calcular tiempo de sesión activa: $e');
              }
            }
          }
        }
        
        final tiempoUsadoTotal = updatedUsed + tiempoSesionActiva;
        
        // Calcular tiempo restante basado en el nuevo límite
        verifyRemaining = (updatedLimit - tiempoUsadoTotal).clamp(0, updatedLimit);
        
        // Si el tiempo usado excede el límite, el tiempo restante es 0
        // PERO si acabamos de agregar tiempo, podemos considerar que el tiempo agregado
        // es tiempo "disponible" que se puede usar. Sin embargo, si el tiempo usado
        // ya excedía el límite anterior, técnicamente no hay tiempo restante.
        
        // Si el límite aumentó y el tiempo usado excede el nuevo límite,
        // el tiempo restante es 0, pero el límite se actualizó correctamente
        // Cuando las sesiones activas se finalicen, el tiempo usado se actualizará
        // y el tiempo restante se calculará correctamente
        
        // IMPORTANTE: Si el tiempo usado excede el límite, pero acabamos de agregar tiempo,
        // debemos considerar que el tiempo agregado es tiempo "disponible" que se puede usar
        // antes de que se bloquee de nuevo. Sin embargo, si el tiempo usado ya excede el límite,
        // técnicamente no hay tiempo restante.
        
        // Si el tiempo usado es mayor que el límite, significa que ya se excedió el límite
        // En este caso, el tiempo restante es 0, pero el límite aumentó, así que cuando
        // se finalice la sesión activa o se actualice el tiempo usado, habrá tiempo disponible
        
        debugPrint('🔍 Cálculo manual después de agregar tiempo:');
        debugPrint('   Límite anterior: $limiteAnterior minutos');
        debugPrint('   Límite actualizado: $updatedLimit minutos');
        debugPrint('   Tiempo usado (BD): $updatedUsed minutos');
        debugPrint('   Tiempo sesión activa: $tiempoSesionActiva minutos');
        debugPrint('   Tiempo usado TOTAL: $tiempoUsadoTotal minutos');
        debugPrint('   Tiempo restante: $verifyRemaining minutos');
        
        // Si el tiempo usado excede el límite, verificar si hay sesiones activas que deben finalizarse
        if (tiempoUsadoTotal > updatedLimit && activeSessions.isNotEmpty) {
          debugPrint('⚠️ El tiempo usado ($tiempoUsadoTotal min) excede el límite ($updatedLimit min)');
          debugPrint('   Esto puede deberse a sesiones activas que no se han finalizado');
          debugPrint('   El tiempo restante es 0, pero el límite se actualizó correctamente');
          debugPrint('   Cuando las sesiones se finalicen, el tiempo restante se calculará correctamente');
        }
      } else {
        debugPrint('⚠️ No se pudo obtener el registro actualizado');
        // Si el límite se actualizó pero no podemos calcular el tiempo restante,
        // al menos verificar usando el método normal
        verifyRemaining = await UsageLimitsService.getRemainingTimeToday();
        debugPrint('   Tiempo restante (método normal): $verifyRemaining minutos');
      }

      // Si el límite se actualizó correctamente, considerar éxito
      // Incluso si el tiempo restante es 0 (puede ser por sesión activa larga)
      // El límite se actualizó correctamente, así que cerrar la pantalla
      if (limiteActualizado) {
        debugPrint('✅ Límite aumentó de $limiteAnterior a $newLimit minutos');
        debugPrint('   Tiempo restante calculado: $verifyRemaining minutos');
        
        // Si el tiempo restante es 0, puede ser por una sesión activa que está sumando tiempo
        // Pero el límite se actualizó correctamente, así que el usuario puede seguir usando la app
        if (verifyRemaining <= 0) {
          debugPrint('⚠️ Tiempo restante es 0, pero el límite se actualizó correctamente');
          debugPrint('   Esto puede deberse a una sesión activa que está sumando tiempo');
          debugPrint('   El límite aumentó, así que cuando la sesión se finalice habrá más tiempo disponible');
        }
        
        // Cerrar la pantalla de bloqueo ya que el límite se actualizó correctamente
        if (mounted) {
          debugPrint('✅ Cerrando pantalla de bloqueo. Límite actualizado correctamente.');
          
          // Llamar callback ANTES de cerrar para que HomeScreen actualice sus datos
          // Pasar información de que el límite se actualizó correctamente
          if (widget.onTimeAdded != null) {
            widget.onTimeAdded!();
          }
          
          // Esperar un momento para que el callback se ejecute
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;
          Navigator.of(context).pop();
          return;
        }
      } else {
        // Si el límite no se actualizó, ya se mostró el error antes
        // Pero por si acaso, verificar una vez más
        debugPrint('❌ El límite no se actualizó correctamente después de todos los intentos');
        if (mounted) {
          setState(() {
            _isAddingTime = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: No se pudo actualizar el límite. Verifica tu conexión e intenta de nuevo.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error al agregar tiempo extra: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar tiempo: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTime = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevenir que se cierre con el botón atrás
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.9),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icono de bloqueo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.withValues(alpha: 0.3),
                              Colors.orange.withValues(alpha: 0.2),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.6),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_clock,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título
                      Text(
                        '⏰ Límite Alcanzado',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Mensaje motivacional
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.accentPurple.withValues(alpha: 0.3),
                              AppColors.accentBlue.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '¡Has alcanzado tu límite diario de uso! 🌟',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Es un gran logro mantenerte dentro de tus límites. Cada momento que pasas sin redes sociales te acerca más a tus objetivos. 💪',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Si necesitas un poco más de tiempo hoy, puedes agregar 10 minutos adicionales solo para este día.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Botones: Quitar bloqueo y Agregar 10 minutos
                      Row(
                        children: [
                          // Botón para quitar el bloqueo
                          Expanded(
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.grey.shade700,
                                    Colors.grey.shade900,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Semantics(
                                  button: true,
                                  label: 'Quitar bloqueo y cerrar',
                                  child: InkWell(
                                  onTap: () {
                                    // Llamar callback si existe
                                    if (widget.onBlockRemoved != null) {
                                      widget.onBlockRemoved!();
                                    }
                                    Navigator.of(context).pop();
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Quitar bloqueo',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón para agregar 10 minutos
                          Expanded(
                            child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: Semantics(
                                  button: true,
                                  label: 'Agregar diez minutos al límite de hoy',
                                  child: InkWell(
                                  onTap: _isAddingTime ? null : _addExtraTime,
                                  borderRadius: BorderRadius.circular(16),
                                  child: Center(
                                    child: _isAddingTime
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.add_circle_outline,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 8),
                                              const Text(
                                                '+10 min',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Texto informativo
                      Text(
                        'Este tiempo extra solo aplica para hoy',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

