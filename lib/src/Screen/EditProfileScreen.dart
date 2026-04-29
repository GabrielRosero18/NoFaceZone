import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Custom/AuthTheme.dart';
import 'package:nofacezone/src/Custom/AuthWidgets.dart';
import 'package:nofacezone/src/Custom/AppLocalizations.dart';
import 'package:nofacezone/src/Custom/CustomSnackBar.dart';
import 'package:nofacezone/src/Custom/ProAnimations.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/UserService.dart';
import 'package:nofacezone/src/Services/PointsService.dart';
import 'package:nofacezone/src/Custom/AppImageProviders.dart';

/// Text input formatter para capitalizar la primera letra de cada palabra
class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.toLowerCase();
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedGender;
  String? _selectedLanguage;
  String? _selectedFrequency;
  String? _selectedAge;
  
  File? _profileImage;
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _autoValidate = false;
  String? _lastLanguage; // Para detectar cambios de idioma
  final List<String> ageRanges = [
    '18-25',
    '26-35',
    '36-45',
    '46-55',
    '56-65',
    '66-75',
    '76-85',
    '86+'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user != null) {
      _nameController.text = user.name;
      _emailController.text = user.email;
      _profileImageUrl = user.profileImage;
      
      // Cargar datos adicionales del usuario desde la base de datos
      _loadUserDetails();
    }
  }

  Future<void> _loadUserDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = userProvider.user;
    
    if (user == null) return;
    
    try {
      // Obtener datos completos del usuario desde la base de datos
      final userData = await UserService.getUserByEmail(user.email);
      
      if (userData != null && mounted) {
        final localizations = AppLocalizations.of(context)!;
        
        setState(() {
          // Mapear edad a rango
          final age = userData['edad'] as int?;
          if (age != null) {
            _selectedAge = _getAgeRange(age);
            _ageController.text = _selectedAge ?? '';
          }
          
          // Mapear género de la BD a la traducción actual
          final genderFromDb = userData['genero'] as String?;
          if (genderFromDb != null) {
            _selectedGender = _mapGenderFromDatabase(genderFromDb, localizations);
          }
          
          // Mapear idioma - si viene como código, usarlo directamente
          final languageFromDb = userData['idioma_preferido'] as String?;
          if (languageFromDb != null) {
            // Si es un código de idioma (es/en), usarlo directamente
            if (languageFromDb == 'es' || languageFromDb == 'en') {
              _selectedLanguage = languageFromDb;
            } else {
              // Si viene como texto, mapearlo
              _selectedLanguage = languageFromDb.toLowerCase().contains('español') || languageFromDb.toLowerCase().contains('spanish') ? 'es' : 'en';
            }
          }
          
          // Mapear frecuencia de la BD a la traducción actual
          final frequencyFromDb = userData['frecuencia_uso_facebook'] as String?;
          if (frequencyFromDb != null) {
            _selectedFrequency = _mapFrequencyFromDatabase(frequencyFromDb, localizations);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
    }
  }
  
  /// Mapear género de la base de datos a la traducción actual
  String? _mapGenderFromDatabase(String genderFromDb, AppLocalizations localizations) {
    final genderLower = genderFromDb.toLowerCase();
    // Mapear valores comunes de la BD a las traducciones actuales
    if (genderLower.contains('masculino') || genderLower.contains('male')) {
      return localizations.male;
    } else if (genderLower.contains('femenino') || genderLower.contains('female')) {
      return localizations.female;
    } else if (genderLower.contains('no binario') || genderLower.contains('non-binary') || genderLower.contains('non binary')) {
      return localizations.nonBinary;
    } else if (genderLower.contains('prefiero no') || genderLower.contains('prefer not')) {
      return localizations.preferNotSay;
    }
    // Si no coincide, verificar si ya es una de las traducciones actuales
    final currentGenders = [localizations.male, localizations.female, localizations.nonBinary, localizations.preferNotSay];
    if (currentGenders.contains(genderFromDb)) {
      return genderFromDb;
    }
    return null;
  }
  
  /// Mapear género entre idiomas usando las traducciones
  String? _mapGenderBetweenLanguages(String genderValue, AppLocalizations oldLocalizations, AppLocalizations newLocalizations) {
    // Obtener todas las traducciones en ambos idiomas
    final oldGenders = [oldLocalizations.male, oldLocalizations.female, oldLocalizations.nonBinary, oldLocalizations.preferNotSay];
    final newGenders = [newLocalizations.male, newLocalizations.female, newLocalizations.nonBinary, newLocalizations.preferNotSay];
    
    // Buscar el índice del valor en el idioma anterior
    final index = oldGenders.indexOf(genderValue);
    if (index >= 0 && index < newGenders.length) {
      return newGenders[index];
    }
    
    // Si no se encuentra, intentar mapear desde la BD
    return _mapGenderFromDatabase(genderValue, newLocalizations);
  }
  
  /// Mapear frecuencia de la base de datos a la traducción actual
  String? _mapFrequencyFromDatabase(String frequencyFromDb, AppLocalizations localizations) {
    final freqLower = frequencyFromDb.toLowerCase();
    // Mapear valores comunes de la BD a las traducciones actuales
    if (freqLower.contains('muy frecuente') || freqLower.contains('very frequent') || freqLower.contains('más de 4')) {
      return localizations.veryFrequent;
    } else if (freqLower.contains('frecuente') && !freqLower.contains('muy') || freqLower.contains('frequent') && !freqLower.contains('very') || freqLower.contains('2-4')) {
      return localizations.frequent;
    } else if (freqLower.contains('moderado') || freqLower.contains('moderate') || freqLower.contains('1-2')) {
      return localizations.moderate;
    } else if (freqLower.contains('poco frecuente') || freqLower.contains('low frequency') || freqLower.contains('menos de 1')) {
      return localizations.lowFrequency;
    }
    // Si no coincide, verificar si ya es una de las traducciones actuales
    final currentFrequencies = [localizations.veryFrequent, localizations.frequent, localizations.moderate, localizations.lowFrequency];
    if (currentFrequencies.contains(frequencyFromDb)) {
      return frequencyFromDb;
    }
    return null;
  }
  
  /// Mapear frecuencia entre idiomas usando las traducciones
  String? _mapFrequencyBetweenLanguages(String frequencyValue, AppLocalizations oldLocalizations, AppLocalizations newLocalizations) {
    // Obtener todas las traducciones en ambos idiomas
    final oldFrequencies = [oldLocalizations.veryFrequent, oldLocalizations.frequent, oldLocalizations.moderate, oldLocalizations.lowFrequency];
    final newFrequencies = [newLocalizations.veryFrequent, newLocalizations.frequent, newLocalizations.moderate, newLocalizations.lowFrequency];
    
    // Buscar el índice del valor en el idioma anterior
    final index = oldFrequencies.indexOf(frequencyValue);
    if (index >= 0 && index < newFrequencies.length) {
      return newFrequencies[index];
    }
    
    // Si no se encuentra, intentar mapear desde la BD
    return _mapFrequencyFromDatabase(frequencyValue, newLocalizations);
  }
  
  /// Mapear valores al idioma actual cuando cambia el idioma
  void _mapValuesToCurrentLanguage(AppLocalizations localizations) {
    bool needsUpdate = false;
    String? newGender = _selectedGender;
    String? newFrequency = _selectedFrequency;
    
    final currentGenders = [localizations.male, localizations.female, localizations.nonBinary, localizations.preferNotSay];
    final currentFrequencies = [localizations.veryFrequent, localizations.frequent, localizations.moderate, localizations.lowFrequency];
    
    // Mapear género si no está en la lista actual
    if (_selectedGender != null && !currentGenders.contains(_selectedGender)) {
      newGender = _mapGenderFromDatabase(_selectedGender!, localizations);
      if (newGender != null && newGender != _selectedGender) {
        needsUpdate = true;
      }
    }
    
    // Mapear frecuencia si no está en la lista actual
    if (_selectedFrequency != null && !currentFrequencies.contains(_selectedFrequency)) {
      newFrequency = _mapFrequencyFromDatabase(_selectedFrequency!, localizations);
      if (newFrequency != null && newFrequency != _selectedFrequency) {
        needsUpdate = true;
      }
    }
    
    // Actualizar estado solo si es necesario
    if (needsUpdate) {
      setState(() {
        if (newGender != null) _selectedGender = newGender;
        if (newFrequency != null) _selectedFrequency = newFrequency;
      });
    }
  }

  String? _getAgeRange(int age) {
    if (age >= 18 && age <= 25) return '18-25';
    if (age >= 26 && age <= 35) return '26-35';
    if (age >= 36 && age <= 45) return '36-45';
    if (age >= 46 && age <= 55) return '46-55';
    if (age >= 56 && age <= 65) return '56-65';
    if (age >= 66 && age <= 75) return '66-75';
    if (age >= 76 && age <= 85) return '76-85';
    if (age >= 86) return '86+';
    return '18-25';
  }

  int _extractMinAgeFromRange(String? range) {
    if (range == null || range.isEmpty) return 18;
    final RegExp rangeRegex = RegExp(r'^(\d+)-(\d+)$|^(\d+)\+$');
    final Match? match = rangeRegex.firstMatch(range);
    if (match == null) return 18;
    return match.group(1) != null 
        ? int.parse(match.group(1)!) 
        : int.parse(match.group(3)!);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          _profileImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showError(
          context,
          '${localizations.errorSelectingImage}: $e',
          icon: Icons.image_not_supported_rounded,
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Builder(
              builder: (context) {
                final localizations = AppLocalizations.of(context)!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library, color: AppColors.textLight),
                      title: Text(localizations.gallery, style: const TextStyle(color: AppColors.textLight)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt, color: AppColors.textLight),
                      title: Text(localizations.camera, style: const TextStyle(color: AppColors.textLight)),
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    if (_profileImage != null || _profileImageUrl != null)
                      ListTile(
                        leading: const Icon(Icons.delete, color: Colors.red),
                        title: Text(localizations.deletePhoto, style: const TextStyle(color: Colors.red)),
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _profileImage = null;
                            _profileImageUrl = null;
                          });
                          CustomSnackBar.showInfo(
                            context,
                            localizations.deletePhoto,
                            icon: Icons.delete_outline_rounded,
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(
    String labelText, {
    Widget? suffixIcon,
    IconData icon = Icons.edit_outlined,
  }) {
    return AuthTheme.inputDecoration(
      label: labelText,
      icon: icon,
      suffixIcon: suffixIcon,
    );
  }

  String? _validateName(String? value, AppLocalizations localizations) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return localizations.nameRequired;
    if (v.length < 3) return localizations.nameMinLength;
    if (v.length > 50) return localizations.nameMaxLength;
    final RegExp allowed = RegExp(r'^[A-Za-zÀ-ÿ]+( [A-Za-zÀ-ÿ]+)*$');
    if (!allowed.hasMatch(v)) {
      return localizations.nameInvalid;
    }
    if (v.contains('  ')) return 'Usa un solo espacio entre nombres';
    return null;
  }

  String? _validateAge(String? value, AppLocalizations localizations) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return localizations.ageRequired;
    final RegExp rangeRegex = RegExp(r'^(\d+)-(\d+)$|^(\d+)\+$');
    if (!rangeRegex.hasMatch(v)) {
      return localizations.ageInvalid;
    }
    final Match? match = rangeRegex.firstMatch(v);
    if (match == null) return localizations.invalidAgeRange;
    final int minAge = match.group(1) != null 
        ? int.parse(match.group(1)!) 
        : int.parse(match.group(3)!);
    if (minAge < 18) {
      return localizations.ageMin18;
    }
    return null;
  }

  Future<void> _saveProfile() async {
    setState(() {
      _autoValidate = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final user = userProvider.user;
      
      if (user == null) {
        final localizations = AppLocalizations.of(context)!;
        throw Exception(localizations.userNotFound);
      }

      // Subir imagen si hay una nueva
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        // Subir la imagen a Supabase Storage
        final uploadResult = await UserService.uploadProfileImage(_profileImage!);
        
        if (!uploadResult['success']) {
          if (mounted) {
            final localizations = AppLocalizations.of(context)!;
            CustomSnackBar.showError(
              context,
              uploadResult['error'] ?? localizations.errorUpdatingProfile,
              icon: Icons.cloud_upload_outlined,
            );
            return;
          }
        }
        
        imageUrl = uploadResult['url'];
        debugPrint('📸 URL de la foto obtenida: $imageUrl');
      }

      // Actualizar perfil en UserProvider
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        profileImage: imageUrl,
      );
      
      debugPrint('👤 UserProvider actualizado con foto: ${userProvider.user?.profileImage}');

      // Actualizar datos adicionales en la base de datos
      // El método updateUser ahora usa automáticamente auth_user_id del usuario autenticado
      // Mapear valores traducidos de vuelta a valores para la BD
      // El género y frecuencia se guardan como están (ya están en el idioma actual)
      // El idioma se guarda como código (es/en)
      final updateResult = await UserService.updateUser(
        name: _nameController.text.trim(),
        age: _extractMinAgeFromRange(_selectedAge),
        gender: _selectedGender, // Ya está mapeado a la traducción actual
        language: _selectedLanguage, // Ya está como código (es/en)
        frequency: _selectedFrequency, // Ya está mapeado a la traducción actual
        fotoPerfil: imageUrl, // Actualizar la foto de perfil en la base de datos
      );

      if (!updateResult['success']) {
        if (mounted) {
          final localizations = AppLocalizations.of(context)!;
          CustomSnackBar.showError(
            context,
            updateResult['error'] ?? localizations.errorUpdatingProfile,
            icon: Icons.error_outline_rounded,
          );
          return;
        }
      }

      // Recargar datos del usuario desde Supabase para sincronizar
      if (updateResult['success']) {
        // Otorgar puntos por actualizar perfil
        await PointsService.awardUpdateProfilePoints();
        
        // Verificar si el perfil está completo para otorgar bonus
        await PointsService.awardCompleteProfilePoints();
        
        // Esperar un momento para que Supabase procese la actualización
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Recargar el usuario desde Supabase para obtener los datos más recientes
        await userProvider.reloadUser();
        
        debugPrint('✅ Usuario recargado. Foto actual: ${userProvider.user?.profileImage}');
      }

      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showSuccess(
          context,
          localizations.profileUpdatedSuccessfully,
          icon: Icons.check_circle_rounded,
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final localizations = AppLocalizations.of(context)!;
        CustomSnackBar.showError(
          context,
          '${localizations.errorUpdatingProfile}: $e',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final localizations = AppLocalizations.of(context)!;
        AppColors.setTheme(appProvider.colorTheme);
    
    // Detectar cambio de idioma y mapear valores automáticamente
    final currentLanguage = appProvider.language;
    if (_lastLanguage != null && _lastLanguage != currentLanguage) {
      // El idioma cambió, mapear valores al nuevo idioma
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _mapValuesToCurrentLanguage(localizations);
        }
      });
    }
    _lastLanguage = currentLanguage;
    
    // Obtener traducciones dinámicamente según el idioma actual
    // NOTE: Campo de género oculto temporalmente en esta versión.
    // Mantener esta lista comentada para una futura reintegración.
    // final List<String> genders = <String>[
    //   localizations.male,
    //   localizations.female,
    //   localizations.nonBinary,
    //   localizations.preferNotSay
    // ];
    // Usar códigos de idioma para el valor del dropdown, pero mostrar las traducciones
    final Map<String, String> languageMap = {
      'es': localizations.spanish,
      'en': localizations.english,
    };
    final List<String> languageCodes = ['es', 'en'];
    // NOTE: Campo de frecuencia de uso oculto temporalmente en esta versión.
    // Mantener esta lista comentada para una futura reintegración.
    // final List<String> frequencies = <String>[
    //   localizations.veryFrequent,
    //   localizations.frequent,
    //   localizations.moderate,
    //   localizations.lowFrequency
    // ];
    
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
        title: Text(
          localizations.editProfileTitle,
          style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back, color: AppColors.textLight),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AuthTheme.backgroundDecoration(),
        child: Stack(
          children: [
            ...AuthTheme.buildBackgroundOrbs(),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Form(
                  key: _formKey,
                  autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const ProEntrance(
                        delayMs: 40,
                        child: AuthHeaderChip(
                          icon: Icons.edit_note_rounded,
                          text: 'Personaliza tu perfil',
                        ),
                      ),
                      const SizedBox(height: 14),
                      ProEntrance(
                        delayMs: 90,
                        child: Text(
                          localizations.editProfileTitle,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      ProEntrance(
                        delayMs: 140,
                        child: AuthGlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        Hero(
                          tag: 'profile_avatar_hero',
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(colors: AppColors.accentGradient),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.darkSurface,
                                ),
                                child: _profileImage != null
                                    ? Container(
                                        width: 112,
                                        height: 112,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          image: DecorationImage(
                                            image: fileAvatarProvider(_profileImage!, logicalDiameter: 112),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    : _profileImageUrl != null
                                        ? Container(
                                            width: 112,
                                            height: 112,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              image: DecorationImage(
                                                image: networkAvatarProvider(_profileImageUrl!, logicalDiameter: 112),
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: AppColors.textLight,
                                            size: 60,
                                          ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: AppColors.accentGradient),
                              border: Border.all(color: AppColors.darkSurface, width: 3),
                            ),
                            child: IconButton(
                              tooltip: localizations.camera,
                              icon: const Icon(Icons.camera_alt, color: AppColors.textLight, size: 20),
                              onPressed: _showImagePickerDialog,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Nombre
                  AuthInputField(
                    controller: _nameController,
                    label: localizations.fullName,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                    validator: (value) => _validateName(value, localizations),
                    inputFormatters: [NameCapitalizationFormatter()],
                  ),
                  const SizedBox(height: 16),
                  
                  // Edad
                  AuthSelectField<String>(
                    value: _selectedAge,
                    label: localizations.ageOver18,
                    icon: Icons.cake_outlined,
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
                      setState(() {
                        _selectedAge = v;
                        _ageController.text = v ?? '';
                      });
                    },
                    validator: (String? v) => _validateAge(v ?? '', localizations),
                  ),
                  const SizedBox(height: 16),
                  
                  // NOTE: Campo de género oculto temporalmente por esencialización de software.
                  // Si se requiere en una versión posterior, descomentar este bloque.
                  // DropdownButtonFormField<String>(
                  //   initialValue: _selectedGender != null && genders.contains(_selectedGender)
                  //       ? _selectedGender
                  //       : null,
                  //   dropdownColor: AppColors.darkSurface,
                  //   style: const TextStyle(color: AppColors.textLight),
                  //   items: genders
                  //       .map((String e) => DropdownMenuItem<String>(
                  //             value: e,
                  //             child: Text(e, style: const TextStyle(color: AppColors.textLight)),
                  //           ))
                  //       .toList(),
                  //   onChanged: (String? v) => setState(() => _selectedGender = v),
                  //   decoration: _getInputDecoration(localizations.gender),
                  //   validator: (String? v) => v == null || v.isEmpty ? localizations.selectGender : null,
                  // ),
                  // const SizedBox(height: 16),
                  
                  // Email (solo lectura)
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                    decoration: _getInputDecoration(
                      localizations.emailCannotChange,
                      icon: Icons.lock_outline_rounded,
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Idioma
                  AuthSelectField<String>(
                    value: _selectedLanguage ?? (appProvider.language == 'es' ? 'es' : 'en'),
                    label: localizations.language,
                    icon: Icons.language_rounded,
                    items: languageCodes
                        .map((String code) => DropdownMenuItem<String>(
                              value: code,
                              child: Text(languageMap[code]!, style: const TextStyle(color: AppColors.textLight)),
                            ))
                        .toList(),
                    onChanged: (String? v) async {
                      if (v != null) {
                        // Guardar los valores actuales y las localizaciones antes de cambiar el idioma
                        final currentFrequency = _selectedFrequency;
                        final currentGender = _selectedGender;
                        final oldLocalizations = AppLocalizations.of(context)!;
                        
                        // Cambiar el idioma de la app PRIMERO
                        await appProvider.setLanguage(v);
                        
                        // Esperar un frame para que las nuevas localizaciones se actualicen
                        await Future.delayed(const Duration(milliseconds: 50));
                        
                        // Obtener las nuevas localizaciones
                        if (!context.mounted) return;
                        final newLocalizations = AppLocalizations.of(context)!;
                        
                        // Mapear género al nuevo idioma usando mapeo entre idiomas
                        String? mappedGender;
                        if (currentGender != null) {
                          mappedGender = _mapGenderBetweenLanguages(currentGender, oldLocalizations, newLocalizations);
                        }
                        
                        // Mapear frecuencia al nuevo idioma usando mapeo entre idiomas
                        String? mappedFrequency;
                        if (currentFrequency != null) {
                          mappedFrequency = _mapFrequencyBetweenLanguages(currentFrequency, oldLocalizations, newLocalizations);
                        }
                        
                        // Actualizar estado con los valores mapeados
                        setState(() {
                          _selectedLanguage = v;
                          if (mappedGender != null) {
                            _selectedGender = mappedGender;
                          }
                          if (mappedFrequency != null) {
                            _selectedFrequency = mappedFrequency;
                          }
                        });
                      }
                    },
                    validator: (String? v) => v == null || v.isEmpty ? localizations.selectLanguageField : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // NOTE: Campo de frecuencia de uso oculto temporalmente por esencialización de software.
                  // Si se requiere en una versión posterior, descomentar este bloque.
                  // DropdownButtonFormField<String>(
                  //   initialValue: _selectedFrequency != null && frequencies.contains(_selectedFrequency)
                  //       ? _selectedFrequency
                  //       : null,
                  //   dropdownColor: AppColors.darkSurface,
                  //   style: const TextStyle(color: AppColors.textLight),
                  //   items: frequencies
                  //       .map((String e) => DropdownMenuItem<String>(
                  //             value: e,
                  //             child: Text(e, style: const TextStyle(color: AppColors.textLight)),
                  //           ))
                  //       .toList(),
                  //   onChanged: (String? v) => setState(() => _selectedFrequency = v),
                  //   decoration: _getInputDecoration(localizations.facebookUsageFrequency),
                  //   validator: (String? v) => v == null || v.isEmpty ? localizations.selectFrequency : null,
                  // ),
                  const SizedBox(height: 32),
                  
                  // Botón guardar
                  AuthPrimaryButton(
                    text: localizations.saveChanges,
                    isLoading: _isLoading,
                    onPressed: _saveProfile,
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
          ],
        ),
      ),
    );
      },
    );
  }
}

