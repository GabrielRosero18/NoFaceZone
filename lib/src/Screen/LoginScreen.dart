import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'RegisterScreen.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AuthWidgets.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/PlatformUI.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Services/UserService.dart';
import 'package:nofacezone/src/Custom/Library.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/PreferencesService.dart';
import 'package:nofacezone/src/auth/auth_form_validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.initialEmail,
    this.justRegistered = false,
  });

  /// Email opcional (p. ej. tras registrarse).
  final String? initialEmail;

  /// Muestra un mensaje de cuenta creada al abrir la pantalla.
  final bool justRegistered;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _passwordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.trim();
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
    if (widget.justRegistered) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final loc = AppLocalizations.of(context);
        if (loc == null) return;
        CustomSnackBar.showSuccess(
          context,
          loc.accountCreatedMessage,
          icon: Icons.check_circle_rounded,
          duration: const Duration(milliseconds: 3500),
        );
      });
    }
  }

  void _hapticTap() => HapticFeedback.selectionClick();
  void _hapticSuccess() => HapticFeedback.mediumImpact();

  /// Función para iniciar sesión con Supabase
  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) return;
    final loc = AppLocalizations.of(context)!;

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
          _showErrorDialog(loc.loginErrorLoadUser);
          return;
        }
        
        // Verificar que el widget sigue montado antes de usar context
        if (!mounted) return;
        
        // Mostrar mensaje de éxito con el nombre real del usuario
        final userName = result['user']['nombre'] ?? loc.user;
        CustomSnackBar.showSuccess(
          context,
          loc.loginWelcomeWithName(userName),
          icon: Icons.celebration_rounded,
          duration: const Duration(milliseconds: 2000),
        );
        
        // Primera vez con esta cuenta en el dispositivo → configuración inicial; si no, inicio.
        if (!mounted) return;
        await PreferencesService.init();
        if (!mounted) return;
        await Provider.of<AppProvider>(context, listen: false).refreshUsageLimits();
        if (!mounted) return;
        final authId = userProvider.token;
        if (PreferencesService.needsInitialAppSetup(authId)) {
          navigate(context, CustomScreen.firstTimeSetup, finishCurrent: true);
        } else {
          navigate(context, CustomScreen.home, finishCurrent: true);
        }
      } else {
        if (!mounted) return;
        
        // Mostrar error
        _showErrorDialog(result['error'] ?? loc.unknownError);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(loc.loginUnexpectedError(e.toString()));
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
    final loc = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text(loc.loginErrorTitle),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              _hapticTap();
              Navigator.of(ctx).pop();
            },
            child: Text(loc.ok),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final backLabel = MaterialLocalizations.of(context).backButtonTooltip;
    final isWebDesktop = PlatformUI.isWebDesktop(context);

    return Selector<AppProvider, String>(
      selector: (_, p) => '${p.colorTheme}|${p.language}',
      builder: (context, _, __) {
        final appProvider = Provider.of<AppProvider>(context, listen: false);
        AppColors.setTheme(appProvider.colorTheme);

        return AuthScaffold(
      title: loc.signIn,
      backTooltip: backLabel,
      onBackPressed: () {
        _hapticTap();
        Navigator.of(context).pop();
      },
      child: ProEntrance(
                delayMs: 80,
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(isWebDesktop ? 36 : 24, 18, isWebDesktop ? 36 : 24, 24),
                  child: PlatformUI.centeredContent(
                    context: context,
                    maxWidth: isWebDesktop ? 1120 : 760,
                    child: Form(
                  key: _formKey,
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (!isWebDesktop)
                      AuthHeaderChip(
                      icon: Icons.shield_moon_rounded,
                      text: loc.loginFocusChip,
                    ),
                    if (!isWebDesktop) const SizedBox(height: 20),
                    if (!isWebDesktop)
                      AuthSectionTitle(
                        title: loc.loginWelcomeBackTitle,
                        subtitle: loc.loginWelcomeBackSubtitle,
                      ),
                    if (!isWebDesktop) const SizedBox(height: 20),
                    if (isWebDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 10,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 24, top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AuthHeaderChip(
                                    icon: Icons.shield_moon_rounded,
                                    text: loc.loginFocusChip,
                                  ),
                                  const SizedBox(height: 20),
                                  AuthSectionTitle(
                                    title: loc.loginWelcomeBackTitle,
                                    subtitle: loc.loginWelcomeBackSubtitle,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    loc.loginTipBody,
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      height: 1.5,
                                      color: AppColors.textLight.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 11,
                            child: _buildLoginCard(loc),
                          ),
                        ],
                      )
                    else
                      _buildLoginCard(loc),
                if (!isWebDesktop) const SizedBox(height: 24),
                if (!isWebDesktop)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.textLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.textLight.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.loginTipTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            loc.loginTipBody,
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
    );
      },
    );
  }

  Widget _buildLoginCard(AppLocalizations loc) {
    return AuthGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            loc.loginAccessAccount,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 18),
          AuthInputField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: loc.email,
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
            validator: (v) => AuthFormValidators.loginEmail(v, loc),
          ),
          const SizedBox(height: 16),
          AuthInputField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            label: loc.password,
            icon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              tooltip: _passwordVisible ? loc.hidePasswordA11y : loc.showPasswordA11y,
              icon: Icon(
                _passwordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: AppColors.textLight.withValues(alpha: 0.72),
              ),
              onPressed: () {
                _hapticTap();
                setState(() => _passwordVisible = !_passwordVisible);
              },
            ),
            obscureText: !_passwordVisible,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              FocusManager.instance.primaryFocus?.unfocus();
              _loginUser();
            },
            validator: (v) => AuthFormValidators.loginPassword(v, loc),
          ),
          const SizedBox(height: 8),
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
                style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.82)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          AuthPrimaryButton(
            text: loc.signIn,
            isLoading: _isLoading,
            onPressed: () {
              _hapticTap();
              _loginUser();
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  loc.loginSeparatorOr,
                  style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.7)),
                ),
              ),
              Expanded(child: Divider(color: AppColors.textLight.withValues(alpha: 0.3))),
            ],
          ),
          const SizedBox(height: 24),
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
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                loc.loginCreateNewAccount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
