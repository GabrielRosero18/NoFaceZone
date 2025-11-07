import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nofacezone/src/Custom/AppColors.dart';
import 'package:nofacezone/src/Providers/UserProvider.dart';
import 'package:nofacezone/src/Providers/AppProvider.dart';
import 'package:nofacezone/src/Services/UserService.dart';

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

  final List<String> genders = ['Masculino', 'Femenino', 'No binario', 'Prefiero no decirlo'];
  final List<String> languages = ['Español', 'English'];
  final List<String> frequencies = [
    'Muy frecuente (más de 4 horas)',
    'Frecuente (2-4 horas)',
    'Moderado (1-2 horas)',
    'Poco frecuente (menos de 1 hora)'
  ];
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
        setState(() {
          // Mapear edad a rango
          final age = userData['edad'] as int?;
          if (age != null) {
            _selectedAge = _getAgeRange(age);
            _ageController.text = _selectedAge ?? '';
          }
          
          _selectedGender = userData['genero'] as String?;
          _selectedLanguage = userData['idioma_preferido'] as String?;
          _selectedFrequency = userData['frecuencia_uso_facebook'] as String?;
        });
      }
    } catch (e) {
      debugPrint('Error loading user details: $e');
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
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
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.textLight),
              title: const Text('Galería', style: TextStyle(color: AppColors.textLight)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.textLight),
              title: const Text('Cámara', style: TextStyle(color: AppColors.textLight)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_profileImage != null || _profileImageUrl != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Eliminar foto', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _profileImage = null;
                    _profileImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

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

  String? _validateName(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'El nombre es obligatorio';
    if (v.length < 3) return 'El nombre debe tener al menos 3 caracteres';
    if (v.length > 50) return 'El nombre no puede exceder 50 caracteres';
    final RegExp allowed = RegExp(r'^[A-Za-zÀ-ÿ]+( [A-Za-zÀ-ÿ]+)*$');
    if (!allowed.hasMatch(v)) {
      return 'Solo letras y espacios, sin números ni símbolos';
    }
    if (v.contains('  ')) return 'Usa un solo espacio entre nombres';
    return null;
  }

  String? _validateAge(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'La edad es obligatoria';
    final RegExp rangeRegex = RegExp(r'^(\d+)-(\d+)$|^(\d+)\+$');
    if (!rangeRegex.hasMatch(v)) {
      return 'Selecciona un rango de edad válido';
    }
    final Match? match = rangeRegex.firstMatch(v);
    if (match == null) return 'Rango de edad inválido';
    final int minAge = match.group(1) != null 
        ? int.parse(match.group(1)!) 
        : int.parse(match.group(3)!);
    if (minAge < 18) {
      return 'Debes ser mayor de 18 años';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final String v = (value ?? '').trim();
    if (v.isEmpty) return 'El email es obligatorio';
    if (v.contains(' ')) return 'El email no puede contener espacios';
    final RegExp emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(v)) return 'Formato de email no válido';
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
        throw Exception('Usuario no encontrado');
      }

      // Subir imagen si hay una nueva
      String? imageUrl = _profileImageUrl;
      if (_profileImage != null) {
        // Aquí deberías subir la imagen a Supabase Storage
        // Por ahora, guardamos la ruta local temporalmente
        imageUrl = _profileImage!.path;
        // TODO: Implementar subida a Supabase Storage
      }

      // Actualizar perfil en UserProvider
      await userProvider.updateProfile(
        name: _nameController.text.trim(),
        profileImage: imageUrl,
      );

      // Actualizar datos adicionales en la base de datos
      // Necesitamos el ID del usuario de la base de datos
      final userData = await UserService.getUserByEmail(user.email);
      if (userData != null) {
        final userId = userData['id_usuario'] as int;
        
        await UserService.updateUser(
          userId: userId,
          name: _nameController.text.trim(),
          age: _extractMinAgeFromRange(_selectedAge),
          gender: _selectedGender,
          language: _selectedLanguage,
          frequency: _selectedFrequency,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
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
    final appProvider = Provider.of<AppProvider>(context);
    AppColors.setTheme(appProvider.colorTheme);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate ? AutovalidateMode.always : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Foto de perfil
                  Center(
                    child: Stack(
                      children: [
                        Container(
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
                                ? ClipOval(
                                    child: Image.file(
                                      _profileImage!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : _profileImageUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _profileImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.person,
                                              color: AppColors.textLight,
                                              size: 60,
                                            );
                                          },
                                        ),
                                      )
                                    : const Icon(
                                        Icons.person,
                                        color: AppColors.textLight,
                                        size: 60,
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
                              icon: const Icon(Icons.camera_alt, color: AppColors.textLight, size: 20),
                              onPressed: _showImagePickerDialog,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Nombre
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppColors.textLight),
                    decoration: _getInputDecoration('Nombre completo'),
                    textInputAction: TextInputAction.next,
                    validator: _validateName,
                    inputFormatters: [NameCapitalizationFormatter()],
                  ),
                  const SizedBox(height: 16),
                  
                  // Edad
                  DropdownButtonFormField<String>(
                    value: _selectedAge,
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: AppColors.textLight),
                    items: ageRanges
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                '$e años',
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
                    decoration: _getInputDecoration('Edad (mayor de 18 años)'),
                    validator: (String? v) => _validateAge(v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  
                  // Género
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: AppColors.textLight),
                    items: genders
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e, style: const TextStyle(color: AppColors.textLight)),
                            ))
                        .toList(),
                    onChanged: (String? v) => setState(() => _selectedGender = v),
                    decoration: _getInputDecoration('Género'),
                    validator: (String? v) => v == null || v.isEmpty ? 'Selecciona un género' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Email (solo lectura)
                  TextFormField(
                    controller: _emailController,
                    style: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6)),
                    decoration: _getInputDecoration('Email (no se puede cambiar)'),
                    enabled: false,
                  ),
                  const SizedBox(height: 16),
                  
                  // Idioma
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: AppColors.textLight),
                    items: languages
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e, style: const TextStyle(color: AppColors.textLight)),
                            ))
                        .toList(),
                    onChanged: (String? v) => setState(() => _selectedLanguage = v),
                    decoration: _getInputDecoration('Idioma'),
                    validator: (String? v) => v == null || v.isEmpty ? 'Selecciona un idioma' : null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Frecuencia de uso
                  DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    dropdownColor: AppColors.darkSurface,
                    style: const TextStyle(color: AppColors.textLight),
                    items: frequencies
                        .map((String e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(e, style: const TextStyle(color: AppColors.textLight)),
                            ))
                        .toList(),
                    onChanged: (String? v) => setState(() => _selectedFrequency = v),
                    decoration: _getInputDecoration('Frecuencia de uso de Facebook'),
                    validator: (String? v) => v == null || v.isEmpty ? 'Selecciona tu frecuencia de uso' : null,
                  ),
                  const SizedBox(height: 32),
                  
                  // Botón guardar
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.accentGradient),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveProfile,
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
                              'Guardar cambios',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                              ),
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
  }
}

