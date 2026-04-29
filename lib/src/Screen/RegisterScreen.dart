import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Services/UserService.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';

/// Text input formatter para capitalizar la primera letra de cada palabra
class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Convertir a minúsculas primero
    String text = newValue.text.toLowerCase();
    
    // Capitalizar la primera letra de cada palabra
    List<String> words = text.split(' ');
    for (int i = 0; i < words.length; i++) {
      if (words[i].isNotEmpty) {
        words[i] = words[i][0].toUpperCase() + words[i].substring(1);
      }
    }
    
    String capitalizedText = words.join(' ');
    
    return TextEditingValue(
      text: capitalizedText,
      selection: TextSelection.collapsed(offset: capitalizedText.length),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Helper para crear el estilo de los campos de formulario
  InputDecoration _getInputDecoration(String labelText, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: labelText,
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
      suffixIcon: suffixIcon,
    );
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _selectedLanguage;
  String? _selectedAge; // Rango de edad (18+ para autocontrol)

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;
  bool _autoValidate = false; // Controla si se muestra la validación automática

  void _hapticTap() => HapticFeedback.selectionClick();
  void _hapticSuccess() => HapticFeedback.mediumImpact();

  // Validators
    final RegExp nameRegex = RegExp(r'^[A-Za-zÀ-ÿ]+( [A-Za-zÀ-ÿ]+)*?$', unicode: true);

  String? _validateName(String? value, AppLocalizations localizations) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return localizations.nameRequired;
    if (v.length < 3) return localizations.nameMinLength;
    if (v.length > 50) return localizations.nameMaxLength;
    // No números ni caracteres especiales
    final RegExp allowed = RegExp(r'^[A-Za-zÀ-ÿ]+( [A-Za-zÀ-ÿ]+)*$');
    if (!allowed.hasMatch(v)) {
      return localizations.nameInvalid;
    }
    // Evitar espacios múltiples
    if (v.contains('  ')) return 'Usa un solo espacio entre nombres';
    // Evitar nombres que sean solo espacios
    if (v.trim().isEmpty) return 'El nombre no puede ser solo espacios';
    // Evitar caracteres repetidos excesivos (más de 2 seguidos)
    if (RegExp(r'(.)\1{2,}').hasMatch(v)) {
      return 'El nombre no puede tener caracteres repetidos más de 2 veces';
    }
    // Evitar nombres que sean solo un carácter repetido
    if (RegExp(r'^(.)\1+$').hasMatch(v)) {
      return 'El nombre no puede ser solo un carácter repetido';
    }
    // Evitar nombres que sean solo vocales o consonantes repetidas
    if (RegExp(r'^[aeiouAEIOU]+$').hasMatch(v) || RegExp(r'^[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]+$').hasMatch(v)) {
      if (v.length <= 4) {
        return 'El nombre debe ser más significativo';
      }
    }
    return null;
  }

  String? _validateAge(String? value, AppLocalizations localizations) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return localizations.ageRequired;
    
    // Validar que sea un rango válido (formato: "18-25" o "66+")
    final RegExp rangeRegex = RegExp(r'^(\d+)-(\d+)$|^(\d+)\+$');
    if (!rangeRegex.hasMatch(v)) {
      return localizations.ageInvalid;
    }
    
    // Extraer el valor mínimo del rango
    final Match? match = rangeRegex.firstMatch(v);
    if (match == null) return localizations.ageInvalid;
    
    final int minAge = match.group(1) != null 
        ? int.parse(match.group(1)!) 
        : int.parse(match.group(3)!);
    
    // Validar que sea mayor de 18 años (autocontrol)
    if (minAge < 18) {
      return localizations.ageMin18;
    }
    
    return null;
  }
  
  /// Extraer el valor mínimo del rango de edad para enviar al servicio
  int _extractMinAgeFromRange(String? range) {
    if (range == null || range.isEmpty) return 18;
    
    final RegExp rangeRegex = RegExp(r'^(\d+)-(\d+)$|^(\d+)\+$');
    final Match? match = rangeRegex.firstMatch(range);
    
    if (match == null) return 18;
    
    return match.group(1) != null 
        ? int.parse(match.group(1)!) 
        : int.parse(match.group(3)!);
  }

  String? _validateLanguage(String? value, AppLocalizations localizations) {
    if (value == null || value.trim().isEmpty || (value != 'es' && value != 'en')) {
      return localizations.selectLanguageField;
    }
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations localizations) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return localizations.emailRequired;
    if (v.contains(' ')) return localizations.emailNoSpaces;
    if (v.length > 254) return localizations.emailInvalid;
    
    final RegExp emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(v)) return localizations.emailInvalid;
    
    // Lista de dominios de email temporales comunes
    final List<String> tempEmailDomains = [
      '10minutemail.com', 'tempmail.org', 'guerrillamail.com', 'mailinator.com',
      'temp-mail.org', 'throwaway.email', 'getnada.com', 'yopmail.com'
    ];
    
    final String domain = v.split('@')[1].toLowerCase();
    if (tempEmailDomains.contains(domain)) {
      return localizations.emailTempNotAllowed;
    }
    
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations localizations) {
    final String v = (value ?? '');
    if (v.isEmpty) return localizations.passwordRequired;
    if (v.contains(' ')) return localizations.passwordNoSpaces;
    if (v.length < 6) return localizations.passwordMin;
    if (v.length > 128) return localizations.passwordMin; // Usar el mismo mensaje
    
    // Validaciones de seguridad comentadas (pueden reactivarse si es necesario)
    // Lista de contraseñas comunes débiles
    // final List<String> commonPasswords = [
    //   'password', '123456', '123456789', 'qwerty', 'abc123', 'password123',
    //   'admin', 'letmein', 'welcome', 'monkey', '1234567890', 'password1',
    //   'qwerty123', 'dragon', 'master', 'hello', 'freedom', 'whatever'
    // ];
    // 
    // if (commonPasswords.contains(v.toLowerCase())) {
    //   return 'Esta contraseña es muy común. Elige una más segura.';
    // }
    // 
    // Verificar requisitos de seguridad
    // bool hasUppercase = v.contains(RegExp(r'[A-Z]'));
    // bool hasNumber = v.contains(RegExp(r'[0-9]'));
    // bool hasSpecialChar = v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    // 
    // if (!hasUppercase) return 'Debe contener al menos una mayúscula';
    // if (!hasNumber) return 'Debe contener al menos un número';
    // if (!hasSpecialChar) return 'Debe contener al menos un carácter especial (!@#\$%^&*)';
    
    return null;
  }

  String? _validateConfirmPassword(String? value, AppLocalizations localizations) {
    final String v = (value ?? '');
    if (v.isEmpty) return localizations.passwordConfirm;
    if (v != _passwordController.text) return localizations.passwordMismatch;
    return null;
  }

  // Función para calcular la fortaleza de la contraseña
  int _calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int strength = 0;
    if (password.length >= 6) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;
    
    return strength;
  }

  String _getPasswordStrengthText(int strength, AppLocalizations localizations) {
    switch (strength) {
      case 0:
      case 1:
        return localizations.veryWeak;
      case 2:
        return localizations.weak;
      case 3:
        return localizations.regular;
      case 4:
        return localizations.strong;
      case 5:
        return localizations.veryStrong;
      default:
        return '';
    }
  }

  Color _getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Función para registrar usuario en Supabase
  Future<void> _registerUser() async {
    final localizations = AppLocalizations.of(context)!;
    
    // Activar validación automática para mostrar todos los errores
    setState(() {
      _autoValidate = true;
    });
    
    // Validar todos los campos
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserService.registerUser(
        name: _nameController.text.trim(),
        age: _extractMinAgeFromRange(_selectedAge),
        gender: localizations.preferNotSay,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        language: _selectedLanguage ?? '',
        frequency: localizations.moderate,
      );

      if (result['success'] == true) {
        _hapticSuccess();
        if (!mounted) return;
        
        // Mostrar diálogo de éxito mejorado
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext ctx) => Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.backgroundGradient,
              ),
            ),
            child: AlertDialog(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: AppColors.accentGradient),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.textLight,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      localizations.registrationSuccess,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🎉 ${localizations.welcomeToApp}',
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    localizations.accountCreatedMessage,
                    style: TextStyle(
                      color: AppColors.textLight.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.accentGradient),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: FilledButton(
                    onPressed: () {
                      _hapticTap();
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      localizations.signIn,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        if (!mounted) return;
        
        // Mostrar error
        _showErrorDialog(result['error'] ?? localizations.unknownError);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('${localizations.unknownError}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Mostrar diálogo de error mejorado
  void _showErrorDialog(String message) {
    final localizations = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.backgroundGradient,
          ),
        ),
        child: AlertDialog(
          backgroundColor: AppColors.darkSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                localizations.registrationError,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.8),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          actions: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  localizations.ok,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del AppProvider para actualizar el tema
    final appProvider = Provider.of<AppProvider>(context);
    final localizations = AppLocalizations.of(context)!;
    AppColors.setTheme(appProvider.colorTheme);
    
    // Obtener traducciones dinámicamente según el idioma actual
    // Usar códigos de idioma para el valor del dropdown, pero mostrar las traducciones
    final Map<String, String> languageMap = {
      'es': localizations.spanish,
      'en': localizations.english,
    };
    final List<String> languageCodes = ['es', 'en'];
    // Rangos de edad para mayores de 18 años (autocontrol)
    final List<String> ageRanges = <String>[
      '18-25',
      '26-35',
      '36-45',
      '46-55',
      '56-65',
      '66-75',
      '76-85',
      '86+'
    ];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () {
            _hapticTap();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          localizations.register,
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w600),
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
              autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: _getInputDecoration(localizations.fullName),
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateName(value, localizations),
                  inputFormatters: [NameCapitalizationFormatter()],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAge,
                  dropdownColor: AppColors.darkSurface,
                  style: const TextStyle(color: AppColors.textLight),
                  items: ageRanges
                      .map((String e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(
                              '$e ${localizations.years}',
                              style: const TextStyle(color: AppColors.textLight),
                            ),
                          ))
                      .toList(),
                  onChanged: (String? v) {
                    _hapticTap();
                    setState(() {
                      _selectedAge = v;
                      _ageController.text = v ?? '';
                    });
                  },
                  decoration: _getInputDecoration(localizations.ageOver18),
                  validator: (String? v) => _validateAge(v ?? '', localizations),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: _getInputDecoration(localizations.email),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) => _validateEmail(value, localizations),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage ?? appProvider.language,
                  dropdownColor: AppColors.darkSurface,
                  style: const TextStyle(color: AppColors.textLight),
                  items: languageCodes
                      .map((String code) => DropdownMenuItem<String>(
                            value: code,
                            child: Text(languageMap[code]!, style: const TextStyle(color: AppColors.textLight)),
                          ))
                      .toList(),
                  onChanged: (String? v) async {
                    if (v != null) {
                      _hapticTap();
                      setState(() => _selectedLanguage = v);
                      // Cambiar el idioma de la app cuando se selecciona
                      await appProvider.setLanguage(v);
                      // Forzar reconstrucción de la pantalla para actualizar todos los textos
                      if (mounted) {
                        setState(() {});
                      }
                    }
                  },
                  decoration: _getInputDecoration(localizations.language),
                  validator: (value) => _validateLanguage(value, localizations),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  style: const TextStyle(color: AppColors.textLight),
                  onChanged: (value) => setState(() {}), // Para actualizar la barra de fortaleza
                  decoration: _getInputDecoration(
                    localizations.password,
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? localizations.hidePasswordA11y : localizations.showPasswordA11y,
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
                  validator: (value) => _validatePassword(value, localizations),
                ),
                // Barra de fortaleza de contraseña
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(
                                begin: 0,
                                end: _calculatePasswordStrength(_passwordController.text) / 5,
                              ),
                              builder: (context, value, _) => LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getPasswordStrengthColor(_calculatePasswordStrength(_passwordController.text)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getPasswordStrengthText(_calculatePasswordStrength(_passwordController.text), localizations),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getPasswordStrengthColor(_calculatePasswordStrength(_passwordController.text)),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        localizations.minimum6Characters,
                        // Texto alternativo comentado (puede reactivarse si es necesario):
                        // 'Requisitos: 6+ caracteres, mayúscula, número, carácter especial',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textLight.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: const TextStyle(color: AppColors.textLight),
                  decoration: _getInputDecoration(
                    localizations.confirmPassword,
                    suffixIcon: IconButton(
                      tooltip: _confirmPasswordVisible ? localizations.hidePasswordA11y : localizations.showPasswordA11y,
                      icon: Icon(
                        _confirmPasswordVisible ? Icons.lock_open : Icons.lock,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        _hapticTap();
                        setState(() => _confirmPasswordVisible = !_confirmPasswordVisible);
                      },
                    ),
                  ),
                  obscureText: !_confirmPasswordVisible,
                  validator: (value) => _validateConfirmPassword(value, localizations),
                ),
                const SizedBox(height: 24),
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
                            _registerUser();
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
                        : Text(
                            localizations.register,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textLight,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    _hapticTap();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    '${localizations.alreadyHaveAccount} ${localizations.signIn}',
                    style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.8)),
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
  }
}


