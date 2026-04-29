import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'RegisterScreen.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Services/UserService.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _passwordVisible = false;
  bool _isLoading = false;

  void _hapticTap() => HapticFeedback.selectionClick();
  void _hapticSuccess() => HapticFeedback.mediumImpact();

  String? _validateEmail(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'El email es obligatorio';
    if (!v.contains('@')) return 'Debe ingresar un email válido';
    final RegExp emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Formato de email no válido';
    return null;
  }

  String? _validatePassword(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'La contraseña es requerida';
    return null;
  }

  /// Función para iniciar sesión con Supabase
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService.loginUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (result['success'] == true) {
        _hapticSuccess();
        if (!mounted) return;
        
        // Actualizar el UserProvider con los datos del usuario desde Supabase
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final loginSuccess = await userProvider.login(
          _emailController.text.trim(),
          _passwordController.text,
          userData: result['user'],
          authUser: result['authUser'] != null 
              ? {
                  'id': result['authUser'].id,
                  'email': result['authUser'].email,
                  'email_confirmed_at': result['authUser'].emailConfirmedAt?.toString(),
                }
              : null,
        );
        
        if (!loginSuccess) {
          if (!mounted) return;
          _showErrorDialog('Error al cargar los datos del usuario');
          return;
        }
        
        // Verificar que el widget sigue montado antes de usar context
        if (!mounted) return;
        
        // Mostrar mensaje de éxito con el nombre real del usuario
        final userName = result['user']['nombre'] ?? 'Usuario';
        CustomSnackBar.showSuccess(
          context,
          '¡Bienvenido $userName!',
          icon: Icons.celebration_rounded,
          duration: const Duration(milliseconds: 2000),
        );
        
        // Navegar a la pantalla principal (Home)
        if (mounted) {
          navigate(context, CustomScreen.home, finishCurrent: true);
        }
      } else {
        if (!mounted) return;
        
        // Mostrar error
        _showErrorDialog(result['error'] ?? 'Error desconocido');
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Mostrar diálogo de error
  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Error en el login'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _hapticTap();
              Navigator.of(ctx).pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;

    return Selector<AppProvider, String>(
      selector: (_, p) => '${p.colorTheme}|${p.language}',
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        AppColors.setTheme(appProvider.colorTheme);

        return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: backLabel,
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () {
            _hapticTap();
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Iniciar Sesión',
          style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: ProEntrance(
            delayMs: 80,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 32),
                // Título de bienvenida
                Text(
                  '¡Bienvenido de vuelta!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Inicia sesión para continuar con tu control de adicción',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textLight.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 32),
                // Campo de email
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.textLight.withValues(alpha: 0.1),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                ),
                const SizedBox(height: 16),
                // Campo de contraseña
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    labelStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.accentBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.textLight.withValues(alpha: 0.1),
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? loc.hidePasswordA11y : loc.showPasswordA11y,
                      icon: Icon(
                        _passwordVisible ? Icons.lock_open : Icons.lock,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        _hapticTap();
                        setState(() => _passwordVisible = !_passwordVisible);
                      },
                    ),
                  ),
                  obscureText: !_passwordVisible,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 8),
                // Enlace de "¿Olvidaste tu contraseña?"
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      _hapticTap();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.passwordRecoveryNotImplemented)),
                      );
                    },
                    child: Text(
                      AppLocalizations.of(context)!.forgotPasswordText,
                      style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botón de iniciar sesión
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.accentGradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: FilledButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _hapticTap();
                            _loginUser();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                            ),
                          )
                        : const Text(
                            'Iniciar Sesión',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'o',
                        style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.textLight.withValues(alpha: 0.3)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Enlace a registro
                SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      _hapticTap();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.textLight.withValues(alpha: 0.8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Crear cuenta nueva',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Información adicional
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.textLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💡 Consejo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Una vez que inicies sesión, podrás configurar límites de tiempo y recibir recordatorios para un uso más saludable de Facebook.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textLight.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
          ),
        ),
      ),
    );
      },
    );
  }
}
