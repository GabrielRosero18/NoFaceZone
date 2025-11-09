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

    _animationController.forward();
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
      
      // Obtener la fecha del registro actual (puede ser de ayer si es temprano)
      final today = DateTime.now();
      final todayString = today.toIso8601String().split('T')[0];
      final fechaRegistro = todayUsage['fecha'] as String?;
      final fechaAUsar = fechaRegistro ?? todayString;

      debugPrint('➕ Agregando 10 minutos:');
      debugPrint('   Límite actual: $currentLimit minutos');
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
      await Future.delayed(const Duration(milliseconds: 1000));

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
        final verifyRemaining = verifyLimit - verifyUsed;
        debugPrint('🔍 Verificación DIRECTA después de agregar tiempo:');
        debugPrint('   Límite del día: $verifyLimit minutos');
        debugPrint('   Tiempo usado: $verifyUsed minutos');
        debugPrint('   Tiempo restante: $verifyRemaining minutos');
        
        if (verifyLimit != newLimit) {
          debugPrint('⚠️ ADVERTENCIA: El límite no se actualizó correctamente!');
          debugPrint('   Esperado: $newLimit minutos');
          debugPrint('   Obtenido: $verifyLimit minutos');
        }
      } else {
        debugPrint('❌ Error: No se encontró el registro después de actualizar');
      }

      // Recargar datos DESPUÉS de verificar
      await appProvider.updateTodayUsage();
      await appProvider.refreshUsageLimits();

      // Llamar callback si existe (esto recargará datos en HomeScreen)
      if (widget.onTimeAdded != null) {
        widget.onTimeAdded!();
      }

      // Esperar un poco más antes de cerrar para asegurar que todo se actualizó
      await Future.delayed(const Duration(milliseconds: 300));

      // Cerrar la pantalla de bloqueo
      if (mounted) {
        Navigator.of(context).pop();
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
    return WillPopScope(
      onWillPop: () async => false, // Prevenir que se cierre con el botón atrás
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

