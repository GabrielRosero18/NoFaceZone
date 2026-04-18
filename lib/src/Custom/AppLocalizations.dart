import 'package:flutter/material.dart';

/// Sistema de localización para la aplicación NoFaceZone
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // General
      'app_name': 'NoFaceZone',
      'welcome': 'Bienvenido',
      'loading': 'Cargando...',
      'save': 'Guardar',
      'cancel': 'Cancelar',
      'delete': 'Eliminar',
      'edit': 'Editar',
      'close': 'Cerrar',
      'confirm': 'Confirmar',
      'yes': 'Sí',
      'no': 'No',
      'ok': 'OK',
      
      // Settings
      'settings': 'Configuración',
      'appearance': 'Apariencia',
      'theme': 'Tema',
      'language': 'Idioma',
      'select_language': 'Seleccionar idioma',
      'spanish': 'Español',
      'english': 'English',
      'language_updated': 'Idioma actualizado',
      'system': 'Sistema',
      'light': 'Claro',
      'dark': 'Oscuro',
      'appearance_description': 'Apariencia de la aplicación',
      'select_language_description': 'Seleccionar idioma',
      'select_theme': 'Seleccionar tema',
      
      // Profile
      'profile': 'Perfil',
      'edit_profile': 'Editar perfil',
      'name': 'Nombre',
      'email': 'Email',
      'email_cannot_change': 'Email (no se puede cambiar)',
      'select_language_field': 'Selecciona un idioma',
      
      // Notifications
      'notifications': 'Notificaciones',
      'enable_notifications': 'Activar notificaciones',
      'notification_interval': 'Intervalo de notificaciones',
      'minutes': 'minutos',
      'minute': 'minuto',
      'time_connector': 'y',
      
      // Usage Limits
      'usage_limits': 'Límites de uso',
      'daily_limit': 'Límite diario',
      'weekly_goal': 'Meta semanal',
      'hours': 'horas',
      'hour': 'hora',
      
      // Advanced
      'advanced': 'Configuración avanzada',
      'export_data': 'Exportar datos',
      'reset_app': 'Restablecer aplicación',
      'logout': 'Cerrar sesión',
      'private_mode': 'Modo privado',
      
      // About
      'about': 'Acerca de',
      'version': 'Versión',
      'app_description': 'Control de Adicción a Facebook',
      
      // Home
      'home': 'Inicio',
      'today': 'Hoy',
      'this_week': 'Esta semana',
      'statistics': 'Estadísticas',
      'rewards': 'Recompensas',
      
      // Login/Register
      'login': 'Iniciar sesión',
      'register': 'Registrarse',
      'password': 'Contraseña',
      'forgot_password': '¿Olvidaste tu contraseña?',
      'dont_have_account': '¿No tienes cuenta?',
      'already_have_account': '¿Ya tienes cuenta?',
      
      // Messages
      'no_data_to_export': 'No hay datos de usuario para exportar',
      'data_exported': 'Datos exportados exitosamente',
      'reset_confirmation': '¿Estás seguro de que deseas restablecer la aplicación?',
      'reset_warning': 'Esta acción cerrará tu sesión y eliminará todas tus preferencias.',
      
      // Register/Login
      'full_name': 'Nombre completo',
      'age': 'Edad',
      'age_over_18': 'Edad (mayor de 18 años)',
      'gender': 'Género',
      'select_gender': 'Selecciona un género',
      'male': 'Masculino',
      'female': 'Femenino',
      'non_binary': 'No binario',
      'prefer_not_say': 'Prefiero no decirlo',
      'facebook_usage_frequency': 'Frecuencia de uso de Facebook',
      'select_frequency': 'Selecciona tu frecuencia de uso',
      'very_frequent': 'Muy frecuente (más de 4 horas)',
      'frequent': 'Frecuente (2-4 horas)',
      'moderate': 'Moderado (1-2 horas)',
      'low_frequency': 'Poco frecuente (menos de 1 hora)',
      'confirm_password': 'Confirmar contraseña',
      'password_strength': 'Fortaleza de contraseña',
      'very_weak': 'Muy débil',
      'weak': 'Débil',
      'regular': 'Regular',
      'strong': 'Fuerte',
      'very_strong': 'Muy fuerte',
      'years': 'años',
      
      // Validation messages
      'name_required': 'El nombre es obligatorio',
      'name_min_length': 'El nombre debe tener al menos 3 caracteres',
      'name_max_length': 'El nombre no puede exceder 50 caracteres',
      'name_invalid': 'Solo letras y espacios, sin números ni símbolos',
      'age_required': 'La edad es obligatoria',
      'age_invalid': 'Selecciona un rango de edad válido',
      'age_min_18': 'Debes ser mayor de 18 años para usar esta aplicación',
      'email_required': 'El email es obligatorio',
      'email_invalid': 'Formato de email no válido (ej. usuario@dominio.com)',
      'email_no_spaces': 'El email no puede contener espacios',
      'email_temp_not_allowed': 'No se permiten emails temporales. Usa un email permanente.',
      'password_required': 'La contraseña es obligatoria',
      'password_min': 'Mínimo 6 caracteres',
      'password_no_spaces': 'La contraseña no puede contener espacios',
      'password_confirm': 'Confirma tu contraseña',
      'password_mismatch': 'Las contraseñas no coinciden',
      'show_password_a11y': 'Mostrar contraseña',
      'hide_password_a11y': 'Ocultar contraseña',
      
      // Welcome
      'app_subtitle': 'Control de Adicción a Facebook',
      'app_description_text': 'Toma el control de tu tiempo en redes sociales y mejora tu bienestar digital',
      'get_started': 'Comenzar',
      
      // Common
      'create_account': 'Crear cuenta',
      'sign_up': 'Registrarse',
      'sign_in': 'Iniciar sesión',
      'forgot_password_text': '¿Olvidaste tu contraseña?',
      'password_recovery_not_implemented': 'Recuperación de contraseña no implementada',
      
      // Settings - Usage Limits
      'usage_limits_title': 'Límites de uso',
      'time_limits_title': 'Límites de Tiempo',
      'time_limits_subtitle': 'Configura tus objetivos de uso diario',
      'daily_limit_title': 'Límite diario',
      'daily_limit_description': 'Tiempo máximo de uso por día',
      'weekly_goal_title': 'Meta semanal',
      'weekly_goal_description': 'Objetivo de horas por semana',
      'daily_limit_dialog_title': 'Límite diario',
      'enter_minutes': 'Ingrese minutos',
      'daily_limit_updated': 'Límite diario actualizado',
      'work_limit_label': 'Límite Trabajo',
      'personal_limit_label': 'Límite Personal',
      'alert_message': 'Recibirás una alerta cuando alcances este límite',
      'configure_daily_goals': 'Configura tus objetivos de uso diario',
      'weekly_goal_dialog_title': 'Meta semanal (horas)',
      'enter_hours': 'Ingrese horas',
      'weekly_goal_updated': 'Meta semanal actualizada',
      
      // Settings - Advanced
      'advanced_settings_title': 'Configuración avanzada',
      'export_data_title': 'Exportar datos',
      'export_data_description': 'Guardar tu progreso',
      'import_data_title': 'Importar datos',
      'import_data_description': 'Restaurar tu progreso',
      'reset_settings_title': 'Reiniciar configuración',
      'reset_settings_description': 'Volver a valores por defecto',
      'reset_settings_confirm': '¿Está seguro de que desea reiniciar toda la configuración a sus valores por defecto?',
      
      // Settings - About
      'about_title': 'Información',
      'version_title': 'Versión',
      'app_info': 'Información de la app',
      'terms_and_conditions': 'Términos y condiciones',
      'read_legal_documents': 'Leer documentos legales',
      'privacy_policy': 'Política de privacidad',
      'how_we_protect_data': 'Cómo protegemos tus datos',
      'contact': 'Contacto',
      'support_and_suggestions': 'Soporte y sugerencias',
      
      // HomeScreen
      'good_morning': 'Buenos días',
      'good_afternoon': 'Buenas tardes',
      'good_evening': 'Buenas noches',
      'user': 'Usuario',
      'message_of_day': 'Mensaje del día',
      'usage_summary': 'Resumen de uso',
      'time_without_facebook': 'Tiempo sin Facebook',
      'blocked_sessions': 'Sesiones bloqueadas',
      'time_saved': 'Tiempo ahorrado',
      'consecutive_days': 'Días consecutivos',
      'usage_limits_title_home': 'Límites de uso',
      'daily_limit_home': 'Límite diario',
      'night_block': 'Bloqueo nocturno',
      'active': 'Activo',
      'feature_off': 'Apagado',
      'usage_status_standby': 'En espera',
      'mandatory_breaks': 'Pausas obligatorias',
      'next_in': 'Próxima en',
      'remaining': 'restantes',
      'weekly_progress': 'Progreso semanal',
      'days_completed': 'días completados',
      'of_word': 'de',
      'quick_navigation': 'Navegación rápida',
      
      // Emotion Tracking
      'emotion_tracking': 'Emociones',
      'emotion_tracking_title': 'Seguimiento de Emociones',
      'how_do_you_feel_today': '¿Cómo te sientes hoy?',
      'select_emotion_description': 'Selecciona la emoción que mejor describe tu estado actual',
      'comment_optional': 'Comentario (Opcional)',
      'comment_placeholder': 'Describe brevemente lo que sientes o el contexto...',
      'register_emotion': 'Registrar Emoción',
      'recent_log': 'Registro Reciente',
      'recent_emotions_subtitle': 'Tus últimas emociones registradas',
      'no_emotions_registered': 'No hay emociones registradas aún',
      'emotion_registered_successfully': 'Emoción registrada exitosamente',
      'error_registering_emotion': 'Error al registrar emoción',
      'please_select_emotion': 'Por favor selecciona una emoción',
      'delete_emotion': 'Eliminar emoción',
      'delete_emotion_confirmation': '¿Estás seguro de que deseas eliminar esta emoción?',
      'emotion_deleted_successfully': 'Emoción eliminada exitosamente',
      'error_deleting_emotion': 'Error al eliminar emoción',
      'error_loading_emotions': 'Error al cargar emociones',
      'emotion_happy': 'Feliz',
      'emotion_sad': 'Triste',
      'emotion_neutral': 'Neutro',
      'emotion_anxious': 'Ansioso',
      'emotion_angry': 'Enojado',
      
      // Settings - Notifications
      'notifications_title': 'Notificaciones',
      'enable_notifications_title': 'Habilitar notificaciones',
      'receive_alerts': 'Recibir alertas y recordatorios',
      'notification_interval_title': 'Intervalo de notificaciones',
      'reminder_frequency': 'Frecuencia de recordatorios',
      
      // Settings - Export/Import
      'data_exported_title': 'Datos exportados',
      'data_prepared_for_export': 'Tus datos han sido preparados para exportar. Copia el siguiente JSON:',
      'data_copied': 'Datos copiados al portapapeles',
      'copy': 'Copiar',
      'import_data_title_dialog': 'Importar datos',
      'paste_json': 'Pega el JSON con tus datos exportados:',
      'paste_json_here': 'Pega el JSON aquí...',
      'import': 'Importar',
      'data_imported_successfully': 'Datos importados correctamente',
      'invalid_json': 'Error al importar datos: JSON inválido',
      'export_error': 'Error al exportar datos',
      'import_error': 'Error al importar datos',
      
      // Reports and Exportation
      'reports_and_exportation': 'Reportes y Exportación',
      'reports_and_exportation_description': 'Genera y descarga reportes detallados de tu uso',
      'select_period': 'Seleccionar Período',
      'select_period_description': 'Elige el rango de fechas para generar el reporte',
      'from': 'Desde',
      'to': 'Hasta',
      'select_date': 'Seleccionar fecha',
      'reports_last_week': 'Última semana',
      'reports_last_month': 'Último mes',
      'generate_report': 'Generar Reporte',
      'report_generated': 'Reporte generado exitosamente',
      'report_error': 'Error al generar el reporte',
      'select_date_range': 'Por favor selecciona un rango de fechas',
      'invalid_date_range': 'La fecha de inicio debe ser anterior a la fecha de fin',
      'report_title': 'Reporte de Uso - NoFaceZone',
      'report_period': 'Período del reporte',
      'total_time_free': 'Tiempo total libre',
      'blocked_sessions_count': 'Sesiones bloqueadas',
      'time_saved_total': 'Tiempo ahorrado',
      'consecutive_days_count': 'Días consecutivos',
      'daily_average_time': 'Promedio diario',
      'generated_on': 'Generado el',
      'user_label': 'Usuario',
      'email_label_report': 'Email',
      'day': 'día',
      'days': 'días',
      'configuration': 'Configuración',
      'daily_limit_label': 'Límite diario',
      'weekly_goal_label': 'Meta semanal',
      'record_free_time': 'Récord de tiempo libre',
      'hours_short': 'h',
      'minutes_short': 'm',
      
      // Terms and Conditions
      'terms_title': 'Términos y Condiciones',
      'last_update': 'Última actualización',
      'terms_section_1_title': '1. Aceptación de los Términos',
      'terms_section_1_text': 'Al usar NoFaceZone, aceptas estos términos y condiciones. Si no estás de acuerdo, no uses la aplicación.',
      'terms_section_2_title': '2. Uso de la Aplicación',
      'terms_section_2_text': 'NoFaceZone está diseñada para ayudarte a controlar tu uso de redes sociales. Debes usar la aplicación de manera responsable y legal.',
      'terms_section_3_title': '3. Privacidad',
      'terms_section_3_text': 'Respetamos tu privacidad. Los datos que recopilamos se utilizan únicamente para mejorar tu experiencia en la aplicación. Consulta nuestra Política de Privacidad para más detalles.',
      'terms_section_4_title': '4. Limitación de Responsabilidad',
      'terms_section_4_text': 'NoFaceZone se proporciona "tal cual" sin garantías. No nos hacemos responsables de ningún daño derivado del uso de la aplicación.',
      'terms_section_5_title': '5. Modificaciones',
      'terms_section_5_text': 'Nos reservamos el derecho de modificar estos términos en cualquier momento. Te notificaremos sobre cambios importantes.',
      
      // Privacy Policy
      'privacy_title': 'Política de Privacidad',
      'privacy_section_1_title': '1. Sobre NoFaceZone',
      'privacy_section_1_text': 'NoFaceZone es una aplicación de autocontrol diseñada para ayudarte a gestionar y reducir tu tiempo de uso en redes sociales, especialmente Facebook. Nuestro objetivo es proporcionarte herramientas para desarrollar hábitos más saludables y conscientes en el uso de tecnología.',
      'privacy_section_2_title': '2. Información que Recopilamos',
      'privacy_section_2_text': 'Para brindarte un servicio de autocontrol efectivo, recopilamos: información de tu cuenta (nombre, email), datos de uso de la aplicación (tiempo de uso, límites establecidos, metas alcanzadas), preferencias de configuración (notificaciones, temas, idioma), y estadísticas de autocontrol (tiempo sin usar Facebook, progreso semanal). Todos estos datos se almacenan de forma segura y se utilizan exclusivamente para tu beneficio personal.',
      'privacy_section_3_title': '3. Cómo Usamos tu Información para el Autocontrol',
      'privacy_section_3_text': 'Utilizamos tu información únicamente para: generar estadísticas personalizadas sobre tu uso de redes sociales, enviarte recordatorios y notificaciones que te ayuden a mantener tus límites de autocontrol, crear gráficos y reportes de tu progreso, personalizar tu experiencia según tus objetivos de autocontrol, y mejorar las funcionalidades de la aplicación para mejorarte en tu proceso de autocontrol.',
      'privacy_section_4_title': '4. Privacidad y Confidencialidad',
      'privacy_section_4_text': 'Entendemos que el autocontrol es un proceso personal y privado. Por ello, NO vendemos, compartimos ni divulgamos tu información personal con terceros. Tus datos de autocontrol son completamente confidenciales y solo tú tienes acceso a ellos. Solo utilizamos datos agregados y completamente anónimos para análisis generales que nos ayudan a mejorar la aplicación.',
      'privacy_section_5_title': '5. Seguridad de tus Datos',
      'privacy_section_5_text': 'Implementamos medidas de seguridad técnicas y organizativas para proteger tu información personal y tus datos de autocontrol. Utilizamos encriptación y almacenamiento seguro. Sin embargo, ningún método de transmisión por Internet es 100% seguro, por lo que te recomendamos mantener tu cuenta segura con una contraseña fuerte.',
      'privacy_section_6_title': '6. Tus Derechos de Autocontrol',
      'privacy_section_6_text': 'Tienes control total sobre tus datos: puedes acceder, modificar, exportar o eliminar tu información personal y datos de autocontrol en cualquier momento a través de la configuración de la aplicación. También puedes reiniciar tus estadísticas o ajustar tus límites de autocontrol cuando lo desees. Tu autonomía y control sobre tus datos es nuestra prioridad.',
      'privacy_section_7_title': '7. Datos de Autocontrol y Estadísticas',
      'privacy_section_7_text': 'Los datos de autocontrol (tiempo de uso, límites, metas, progreso) se almacenan localmente en tu dispositivo y de forma segura en nuestros servidores para permitir sincronización entre dispositivos. Estos datos son esenciales para que la aplicación funcione correctamente y te proporcione las herramientas de autocontrol que necesitas. Puedes eliminar estos datos en cualquier momento desde la configuración.',
      
      // Contact
      'contact_title': 'Contacto',
      'need_help': '¿Necesitas ayuda o tienes sugerencias?',
      'email_label': 'Email',
      'support_label': 'Soporte',
      'help_center': 'Centro de ayuda',
      'email_copied': 'Email copiado al portapapeles',
      
      // Statistics
      'day_summary': 'Resumen del día',
      'weekly_summary': 'Resumen semanal',
      'monthly_summary': 'Resumen mensual',
      'free_time_from_facebook': 'Tiempo libre de Facebook',
      'total_free_time': 'Total tiempo libre',
      'daily_average': 'Promedio diario',
      
      // App Info Dialog
      'app_info_title': 'Información de la aplicación',
      'name_label': 'Nombre',
      'version_label': 'Versión',
      'build_label': 'Build',
      'description_label': 'Descripción',
      'error_getting_info': 'Error al obtener información',
      
      // Statistics Screen
      'week': 'Semana',
      'month': 'Mes',
      'hourly_activity': 'Actividad horaria',
      'effectiveness': 'Efectividad',
      'mood': 'Estado de ánimo',
      'mental_strength': 'Fuerza mental',
      'high': 'Alta',
      'good': 'Bueno',
      'last_week': 'Semana pasada',
      'week_number': 'Semana',
      'weekly_comparison': 'Comparación semanal',
      'best_streak': 'Mejor racha',
      'success_rate': 'Tasa de éxito',
      'weekly_activity': 'Actividad semanal',
      'monthly_progress': 'Progreso mensual',
      'monthly_achievements': 'Logros del mes',
      'improvement': 'Mejora del',
      'monday': 'Lun',
      'tuesday': 'Mar',
      'wednesday': 'Mié',
      'thursday': 'Jue',
      'friday': 'Vie',
      'saturday': 'Sáb',
      'sunday': 'Dom',
      'streak_7_days': 'Racha de 7 días',
      'weekly_goal_achieved': 'Meta semanal cumplida',
      '100_hours_free': '100 horas libres',
      
      // Rewards Screen
      'themes': 'Temas',
      'fonts': 'Fuentes',
      'messages': 'Mensajes',
      'badges': 'Badges',
      'points': 'Puntos',
      'your_points': 'Tus puntos',
      'points_text': 'puntos',
      'available_points': 'Puntos disponibles',
      'motivation_difficult_moments': 'Motivación en momentos difíciles',
      'encouragement_messages': 'Mensajes de aliento',
      'warrior_weekly': 'Guerrero Semanal',
      'complete_7_days': 'Completa 7 días consecutivos',
      
      // Rewards - Themes
      'color_themes': '🎨 Temas de colores',
      'unlock_themes_description': 'Desbloquea nuevos temas personalizando tu experiencia',
      'theme_ocean_blue': 'Océano Azul',
      'theme_ocean_description': 'Un tema relajante inspirado en el mar',
      'theme_sunset': 'Atardecer',
      'theme_sunset_description': 'Colores cálidos del atardecer',
      'theme_forest': 'Bosque Verde',
      'theme_forest_description': 'Tema natural y relajante',
      'theme_lavender': 'Lavanda',
      'theme_lavender_description': 'Suave y relajante',
      'theme_coral': 'Coral',
      'theme_coral_description': 'Vibrante y energético',
      'theme_midnight': 'Medianoche',
      'theme_midnight_description': 'Elegante y sofisticado',
      'theme_applied': 'Tema "{name}" aplicado ✨',
      'available': 'Disponible',
      
      // Rewards - Fonts
      'font_types': '✍️ Tipos de letra',
      'customize_fonts_description': 'Personaliza la tipografía de la aplicación',
      'font_roboto_description': 'Fuente estándar y legible',
      'font_playfair_description': 'Elegante y sofisticada',
      'font_poppins_description': 'Moderna y minimalista',
      'font_comfortaa_description': 'Amigable y redondeada',
      'font_montserrat_description': 'Audaz y llamativa',
      'font_applied': 'Fuente "{name}" aplicada ✨',
      
      // Rewards - Messages
      'motivational_messages': '💬 Mensajes motivacionales',
      'unlock_messages_description': 'Desbloquea colecciones de mensajes inspiradores',
      'daily_messages': 'Mensajes diarios',
      'daily_messages_description': 'Mensajes motivacionales cada día',
      'achievement_messages': 'Mensajes de logros',
      'achievement_messages_description': 'Celebra tus éxitos',
      'wisdom_daily': 'Sabiduría diaria',
      'wisdom_daily_description': 'Frases inspiradoras de grandes pensadores',
      'collection_activated': 'Colección "{name}" activada ✨',
      'collection_deactivated': 'Colección "{name}" desactivada',
      'message_example_1': '✨ Cada día es una nueva oportunidad',
      'message_example_2': '💪 Eres más fuerte de lo que crees',
      'message_example_3': '🌟 Tus pequeños pasos llevan a grandes cambios',
      'message_example_4': '🎉 ¡Increíble! Lograste tu meta',
      'message_example_5': '🏆 Has superado tus expectativas',
      'message_example_6': '⭐ Eres un ejemplo de perseverancia',
      'message_example_7': '🌱 Todo crecimiento requiere tiempo',
      'message_example_8': '💫 Tus esfuerzos no pasan desapercibidos',
      'message_example_9': '🌺 Eres capaz de superar cualquier obstáculo',
      'message_example_10': '🧘 La paz viene de dentro',
      'message_example_11': '🎯 El éxito es la suma de pequeños esfuerzos',
      'message_example_12': '🌈 La persistencia supera la resistencia',
      
      // Rewards - Badges
      'badges_and_achievements': '🏆 Badges y Logros',
      'unlock_badges_description': 'Desbloquea badges especiales por tus logros',
      'badge_first_steps': 'Primeros Pasos',
      'badge_first_steps_description': 'Completa 3 días consecutivos',
      'badge_month_master': 'Maestro Mensual',
      'badge_month_master_description': 'Completa 30 días consecutivos',
      'badge_time_saver': 'Ahorrador de Tiempo',
      'badge_time_saver_description': 'Ahorra 50 horas libres',
      'badge_early_bird': 'Madrugador',
      'badge_early_bird_description': 'Completa 5 días antes del mediodía',
      'badge_streak_master': 'Maestro de Racha',
      'badge_streak_master_description': 'Mantén 10 días consecutivos',
      'badge_goal_crusher': 'Destructor de Metas',
      'badge_goal_crusher_description': 'Cumple todas las metas semanales',
      'badge_zen_master': 'Maestro Zen',
      'badge_zen_master_description': '10 horas libres en un día',
      'badge_night_owl': 'Búho Nocturno',
      'badge_night_owl_description': 'Completa 5 días después de medianoche',
      'badge_unstoppable': 'Imparable',
      'badge_unstoppable_description': '15 días consecutivos sin faltar',
      'badge_legend': 'Leyenda',
      'badge_legend_description': 'Completa 100 días consecutivos',
      
      // Edit Profile Screen
      'edit_profile_title': 'Editar perfil',
      'gallery': 'Galería',
      'camera': 'Cámara',
      'delete_photo': 'Eliminar foto',
      'error_selecting_image': 'Error al seleccionar imagen',
      'profile_updated_successfully': 'Perfil actualizado exitosamente',
      'error_updating_profile': 'Error al actualizar perfil',
      'user_not_found': 'Usuario no encontrado',
      'save_changes': 'Guardar cambios',
      'invalid_age_range': 'Rango de edad inválido',
      
      // Register Screen - Dialog messages
      'registration_success': '¡Registro exitoso!',
      'welcome_to_app': '¡Bienvenido a NoFaceZone!',
      'account_created_message': 'Tu cuenta ha sido creada correctamente. Ahora puedes iniciar sesión y comenzar a controlar tu tiempo en Facebook.',
      'registration_error': 'Error en el registro',
      'unknown_error': 'Error desconocido',
      'minimum_6_characters': 'Mínimo 6 caracteres',
    },
    'en': {
      // General
      'app_name': 'NoFaceZone',
      'welcome': 'Welcome',
      'loading': 'Loading...',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'close': 'Close',
      'confirm': 'Confirm',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      
      // Settings
      'settings': 'Settings',
      'appearance': 'Appearance',
      'theme': 'Theme',
      'language': 'Language',
      'select_language': 'Select language',
      'spanish': 'Español',
      'english': 'English',
      'language_updated': 'Language updated',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'appearance_description': 'Application appearance',
      'select_language_description': 'Select language',
      'select_theme': 'Select theme',
      
      // Profile
      'profile': 'Profile',
      'edit_profile': 'Edit profile',
      'name': 'Name',
      'email': 'Email',
      'email_cannot_change': 'Email (cannot be changed)',
      'select_language_field': 'Select a language',
      
      // Notifications
      'notifications': 'Notifications',
      'enable_notifications': 'Enable notifications',
      'notification_interval': 'Notification interval',
      'minutes': 'minutes',
      'minute': 'minute',
      'time_connector': 'and',
      
      // Usage Limits
      'usage_limits': 'Usage limits',
      'daily_limit': 'Daily limit',
      'weekly_goal': 'Weekly goal',
      'hours': 'hours',
      'hour': 'hour',
      
      // Advanced
      'advanced': 'Advanced settings',
      'export_data': 'Export data',
      'reset_app': 'Reset application',
      'logout': 'Logout',
      'private_mode': 'Private mode',
      
      // About
      'about': 'About',
      'version': 'Version',
      'app_description': 'Facebook Addiction Control',
      
      // Home
      'home': 'Home',
      'today': 'Today',
      'this_week': 'This week',
      'statistics': 'Statistics',
      'rewards': 'Rewards',
      
      // Login/Register
      'login': 'Login',
      'register': 'Register',
      'password': 'Password',
      'forgot_password': 'Forgot password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      
      // Messages
      'no_data_to_export': 'No user data to export',
      'data_exported': 'Data exported successfully',
      'reset_confirmation': 'Are you sure you want to reset the application?',
      'reset_warning': 'This action will log you out and delete all your preferences.',
      
      // Register/Login
      'full_name': 'Full name',
      'age': 'Age',
      'age_over_18': 'Age (over 18 years)',
      'gender': 'Gender',
      'select_gender': 'Select a gender',
      'male': 'Male',
      'female': 'Female',
      'non_binary': 'Non-binary',
      'prefer_not_say': 'Prefer not to say',
      'facebook_usage_frequency': 'Facebook usage frequency',
      'select_frequency': 'Select your usage frequency',
      'very_frequent': 'Very frequent (more than 4 hours)',
      'frequent': 'Frequent (2-4 hours)',
      'moderate': 'Moderate (1-2 hours)',
      'low_frequency': 'Low frequency (less than 1 hour)',
      'confirm_password': 'Confirm password',
      'password_strength': 'Password strength',
      'very_weak': 'Very weak',
      'weak': 'Weak',
      'regular': 'Regular',
      'strong': 'Strong',
      'very_strong': 'Very strong',
      'years': 'years',
      
      // Validation messages
      'name_required': 'Name is required',
      'name_min_length': 'Name must have at least 3 characters',
      'name_max_length': 'Name cannot exceed 50 characters',
      'name_invalid': 'Only letters and spaces, no numbers or symbols',
      'age_required': 'Age is required',
      'age_invalid': 'Select a valid age range',
      'age_min_18': 'You must be over 18 years old to use this application',
      'email_required': 'Email is required',
      'email_invalid': 'Invalid email format (e.g. user@domain.com)',
      'email_no_spaces': 'Email cannot contain spaces',
      'email_temp_not_allowed': 'Temporary emails are not allowed. Use a permanent email.',
      'password_required': 'Password is required',
      'password_min': 'Minimum 6 characters',
      'password_no_spaces': 'Password cannot contain spaces',
      'password_confirm': 'Confirm your password',
      'password_mismatch': 'Passwords do not match',
      'show_password_a11y': 'Show password',
      'hide_password_a11y': 'Hide password',
      
      // Welcome
      'app_subtitle': 'Facebook Addiction Control',
      'app_description_text': 'Take control of your time on social media and improve your digital well-being',
      'get_started': 'Get Started',
      
      // Common
      'create_account': 'Create account',
      'sign_up': 'Sign up',
      'sign_in': 'Sign in',
      'forgot_password_text': 'Forgot password?',
      'password_recovery_not_implemented': 'Password recovery not implemented',
      
      // Settings - Usage Limits
      'usage_limits_title': 'Usage limits',
      'time_limits_title': 'Time Limits',
      'time_limits_subtitle': 'Configure your daily usage goals',
      'daily_limit_title': 'Daily limit',
      'daily_limit_description': 'Maximum usage time per day',
      'weekly_goal_title': 'Weekly goal',
      'weekly_goal_description': 'Goal of hours per week',
      'daily_limit_dialog_title': 'Daily limit',
      'enter_minutes': 'Enter minutes',
      'daily_limit_updated': 'Daily limit updated',
      'work_limit_label': 'Work Limit',
      'personal_limit_label': 'Personal Limit',
      'alert_message': 'You will receive an alert when you reach this limit',
      'configure_daily_goals': 'Configure your daily usage goals',
      'weekly_goal_dialog_title': 'Weekly goal (hours)',
      'enter_hours': 'Enter hours',
      'weekly_goal_updated': 'Weekly goal updated',
      
      // Settings - Advanced
      'advanced_settings_title': 'Advanced settings',
      'export_data_title': 'Export data',
      'export_data_description': 'Save your progress',
      'import_data_title': 'Import data',
      'import_data_description': 'Restore your progress',
      'reset_settings_title': 'Reset settings',
      'reset_settings_description': 'Return to default values',
      'reset_settings_confirm': 'Are you sure you want to reset all settings to their default values?',
      
      // Settings - About
      'about_title': 'Information',
      'version_title': 'Version',
      'app_info': 'App information',
      'terms_and_conditions': 'Terms and conditions',
      'read_legal_documents': 'Read legal documents',
      'privacy_policy': 'Privacy policy',
      'how_we_protect_data': 'How we protect your data',
      'contact': 'Contact',
      'support_and_suggestions': 'Support and suggestions',
      
      // HomeScreen
      'good_morning': 'Good morning',
      'good_afternoon': 'Good afternoon',
      'good_evening': 'Good evening',
      'user': 'User',
      'message_of_day': 'Message of the day',
      'usage_summary': 'Usage summary',
      'time_without_facebook': 'Time without Facebook',
      'blocked_sessions': 'Blocked sessions',
      'time_saved': 'Time saved',
      'consecutive_days': 'Consecutive days',
      'usage_limits_title_home': 'Usage limits',
      'daily_limit_home': 'Daily limit',
      'night_block': 'Night block',
      'active': 'Active',
      'feature_off': 'Off',
      'usage_status_standby': 'Standby',
      'mandatory_breaks': 'Mandatory breaks',
      'next_in': 'Next in',
      'remaining': 'remaining',
      'weekly_progress': 'Weekly progress',
      'days_completed': 'days completed',
      'of_word': 'of',
      'quick_navigation': 'Quick navigation',
      
      // Emotion Tracking
      'emotion_tracking': 'Emotions',
      'emotion_tracking_title': 'Emotion Tracking',
      'how_do_you_feel_today': 'How do you feel today?',
      'select_emotion_description': 'Select the emotion that best describes your current state',
      'comment_optional': 'Comment (Optional)',
      'comment_placeholder': 'Briefly describe what you feel or the context...',
      'register_emotion': 'Register Emotion',
      'recent_log': 'Recent Log',
      'recent_emotions_subtitle': 'Your last registered emotions',
      'no_emotions_registered': 'No emotions registered yet',
      'emotion_registered_successfully': 'Emotion registered successfully',
      'error_registering_emotion': 'Error registering emotion',
      'please_select_emotion': 'Please select an emotion',
      'delete_emotion': 'Delete emotion',
      'delete_emotion_confirmation': 'Are you sure you want to delete this emotion?',
      'emotion_deleted_successfully': 'Emotion deleted successfully',
      'error_deleting_emotion': 'Error deleting emotion',
      'error_loading_emotions': 'Error loading emotions',
      'emotion_happy': 'Happy',
      'emotion_sad': 'Sad',
      'emotion_neutral': 'Neutral',
      'emotion_anxious': 'Anxious',
      'emotion_angry': 'Angry',
      
      // Settings - Notifications
      'notifications_title': 'Notifications',
      'enable_notifications_title': 'Enable notifications',
      'receive_alerts': 'Receive alerts and reminders',
      'notification_interval_title': 'Notification interval',
      'reminder_frequency': 'Reminder frequency',
      
      // Settings - Export/Import
      'data_exported_title': 'Data exported',
      'data_prepared_for_export': 'Your data has been prepared for export. Copy the following JSON:',
      'data_copied': 'Data copied to clipboard',
      'copy': 'Copy',
      'import_data_title_dialog': 'Import data',
      'paste_json': 'Paste the JSON with your exported data:',
      'paste_json_here': 'Paste JSON here...',
      'import': 'Import',
      'data_imported_successfully': 'Data imported successfully',
      'invalid_json': 'Error importing data: Invalid JSON',
      'export_error': 'Error exporting data',
      'import_error': 'Error importing data',
      
      // Reports and Exportation
      'reports_and_exportation': 'Reports and Exportation',
      'reports_and_exportation_description': 'Generate and download detailed reports of your usage',
      'select_period': 'Select Period',
      'select_period_description': 'Choose the date range to generate the report',
      'from': 'From',
      'to': 'To',
      'select_date': 'Select date',
      'reports_last_week': 'Last week',
      'reports_last_month': 'Last month',
      'generate_report': 'Generate Report',
      'report_generated': 'Report generated successfully',
      'report_error': 'Error generating report',
      'select_date_range': 'Please select a date range',
      'invalid_date_range': 'Start date must be before end date',
      'report_title': 'Usage Report - NoFaceZone',
      'report_period': 'Report period',
      'total_time_free': 'Total free time',
      'blocked_sessions_count': 'Blocked sessions',
      'time_saved_total': 'Time saved',
      'consecutive_days_count': 'Consecutive days',
      'daily_average_time': 'Daily average',
      'generated_on': 'Generated on',
      'user_label': 'User',
      'email_label_report': 'Email',
      'day': 'day',
      'days': 'days',
      'configuration': 'Configuration',
      'daily_limit_label': 'Daily limit',
      'weekly_goal_label': 'Weekly goal',
      'record_free_time': 'Free time record',
      'hours_short': 'h',
      'minutes_short': 'm',
      
      // Terms and Conditions
      'terms_title': 'Terms and Conditions',
      'last_update': 'Last update',
      'terms_section_1_title': '1. Acceptance of the Terms',
      'terms_section_1_text': 'By using NoFaceZone, you accept these terms and conditions. If you do not agree, do not use the application.',
      'terms_section_2_title': '2. Use of the Application',
      'terms_section_2_text': 'NoFaceZone is designed to help you control your use of social networks. You must use the application responsibly and legally.',
      'terms_section_3_title': '3. Privacy',
      'terms_section_3_text': 'We respect your privacy. The data we collect is used solely to improve your experience in the application. Consult our Privacy Policy for more details.',
      'terms_section_4_title': '4. Limitation of Liability',
      'terms_section_4_text': 'NoFaceZone is provided "as is" without warranties. We are not responsible for any damage resulting from the use of the application.',
      'terms_section_5_title': '5. Modifications',
      'terms_section_5_text': 'We reserve the right to modify these terms at any time. We will notify you of important changes.',
      
      // Privacy Policy
      'privacy_title': 'Privacy Policy',
      'privacy_section_1_title': '1. About NoFaceZone',
      'privacy_section_1_text': 'NoFaceZone is a self-control application designed to help you manage and reduce your time on social networks, especially Facebook. Our goal is to provide you with tools to develop healthier and more conscious habits in technology use.',
      'privacy_section_2_title': '2. Information We Collect',
      'privacy_section_2_text': 'To provide you with an effective self-control service, we collect: account information (name, email), application usage data (usage time, set limits, achieved goals), configuration preferences (notifications, themes, language), and self-control statistics (time without using Facebook, weekly progress). All this data is stored securely and used exclusively for your personal benefit.',
      'privacy_section_3_title': '3. How We Use Your Information for Self-Control',
      'privacy_section_3_text': 'We use your information solely to: generate personalized statistics about your social network usage, send you reminders and notifications to help you maintain your self-control limits, create charts and reports of your progress, personalize your experience according to your self-control goals, and improve application features to help you in your self-control process.',
      'privacy_section_4_title': '4. Privacy and Confidentiality',
      'privacy_section_4_text': 'We understand that self-control is a personal and private process. Therefore, we do NOT sell, share, or disclose your personal information to third parties. Your self-control data is completely confidential and only you have access to it. We only use aggregated and completely anonymous data for general analysis that helps us improve the application.',
      'privacy_section_5_title': '5. Security of Your Data',
      'privacy_section_5_text': 'We implement technical and organizational security measures to protect your personal information and self-control data. We use encryption and secure storage. However, no method of Internet transmission is 100% secure, so we recommend keeping your account secure with a strong password.',
      'privacy_section_6_title': '6. Your Self-Control Rights',
      'privacy_section_6_text': 'You have full control over your data: you can access, modify, export, or delete your personal information and self-control data at any time through the application settings. You can also reset your statistics or adjust your self-control limits whenever you wish. Your autonomy and control over your data is our priority.',
      'privacy_section_7_title': '7. Self-Control Data and Statistics',
      'privacy_section_7_text': 'Self-control data (usage time, limits, goals, progress) is stored locally on your device and securely on our servers to allow synchronization between devices. This data is essential for the application to function correctly and provide you with the self-control tools you need. You can delete this data at any time from the settings.',
      
      // Contact
      'contact_title': 'Contact',
      'need_help': 'Need help or have suggestions?',
      'email_label': 'Email',
      'support_label': 'Support',
      'help_center': 'Help center',
      'email_copied': 'Email copied to clipboard',
      'exit_application': 'Exit the application',
      
      // Statistics
      'day_summary': 'Day summary',
      'weekly_summary': 'Weekly summary',
      'monthly_summary': 'Monthly summary',
      'free_time_from_facebook': 'Free time from Facebook',
      'total_free_time': 'Total free time',
      'daily_average': 'Daily average',
      
      // App Info Dialog
      'app_info_title': 'App Information',
      'name_label': 'Name',
      'version_label': 'Version',
      'build_label': 'Build',
      'description_label': 'Description',
      'error_getting_info': 'Error getting information',
      
      // Statistics Screen
      'week': 'Week',
      'month': 'Month',
      'hourly_activity': 'Hourly Activity',
      'effectiveness': 'Effectiveness',
      'mood': 'Mood',
      'mental_strength': 'Mental Strength',
      'high': 'High',
      'good': 'Good',
      'last_week': 'Last week',
      'week_number': 'Week',
      'weekly_comparison': 'Weekly comparison',
      'best_streak': 'Best streak',
      'success_rate': 'Success rate',
      'weekly_activity': 'Weekly activity',
      'monthly_progress': 'Monthly progress',
      'monthly_achievements': 'Monthly achievements',
      'improvement': 'Improvement of',
      'monday': 'Mon',
      'tuesday': 'Tue',
      'wednesday': 'Wed',
      'thursday': 'Thu',
      'friday': 'Fri',
      'saturday': 'Sat',
      'sunday': 'Sun',
      'streak_7_days': '7-day streak',
      'weekly_goal_achieved': 'Weekly goal achieved',
      '100_hours_free': '100 hours free',
      
      // Rewards Screen
      'themes': 'Themes',
      'fonts': 'Fonts',
      'messages': 'Messages',
      'badges': 'Badges',
      'points': 'Points',
      'your_points': 'Your points',
      'points_text': 'points',
      'available_points': 'Available points',
      'motivation_difficult_moments': 'Motivation in difficult moments',
      'encouragement_messages': 'Encouragement messages',
      'warrior_weekly': 'Weekly Warrior',
      'complete_7_days': 'Complete 7 consecutive days',
      
      // Rewards - Themes
      'color_themes': '🎨 Color Themes',
      'unlock_themes_description': 'Unlock new themes to customize your experience',
      'theme_ocean_blue': 'Blue Ocean',
      'theme_ocean_description': 'A relaxing theme inspired by the sea',
      'theme_sunset': 'Sunset',
      'theme_sunset_description': 'Warm sunset colors',
      'theme_forest': 'Green Forest',
      'theme_forest_description': 'Natural and relaxing theme',
      'theme_lavender': 'Lavender',
      'theme_lavender_description': 'Soft and relaxing',
      'theme_coral': 'Coral',
      'theme_coral_description': 'Vibrant and energetic',
      'theme_midnight': 'Midnight',
      'theme_midnight_description': 'Elegant and sophisticated',
      'theme_applied': 'Theme "{name}" applied ✨',
      'available': 'Available',
      
      // Rewards - Fonts
      'font_types': '✍️ Font Types',
      'customize_fonts_description': 'Customize the application typography',
      'font_roboto_description': 'Standard and readable font',
      'font_playfair_description': 'Elegant and sophisticated',
      'font_poppins_description': 'Modern and minimalist',
      'font_comfortaa_description': 'Friendly and rounded',
      'font_montserrat_description': 'Bold and striking',
      'font_applied': 'Font "{name}" applied ✨',
      
      // Rewards - Messages
      'motivational_messages': '💬 Motivational Messages',
      'unlock_messages_description': 'Unlock collections of inspiring messages',
      'daily_messages': 'Daily messages',
      'daily_messages_description': 'Motivational messages every day',
      'achievement_messages': 'Achievement messages',
      'achievement_messages_description': 'Celebrate your successes',
      'wisdom_daily': 'Daily wisdom',
      'wisdom_daily_description': 'Inspiring phrases from great thinkers',
      'collection_activated': 'Collection "{name}" activated ✨',
      'collection_deactivated': 'Collection "{name}" deactivated',
      'message_example_1': '✨ Every day is a new opportunity',
      'message_example_2': '💪 You are stronger than you think',
      'message_example_3': '🌟 Your small steps lead to big changes',
      'message_example_4': '🎉 Incredible! You achieved your goal',
      'message_example_5': '🏆 You have exceeded your expectations',
      'message_example_6': '⭐ You are an example of perseverance',
      'message_example_7': '🌱 All growth requires time',
      'message_example_8': '💫 Your efforts do not go unnoticed',
      'message_example_9': '🌺 You are capable of overcoming any obstacle',
      'message_example_10': '🧘 Peace comes from within',
      'message_example_11': '🎯 Success is the sum of small efforts',
      'message_example_12': '🌈 Persistence overcomes resistance',
      
      // Rewards - Badges
      'badges_and_achievements': '🏆 Badges and Achievements',
      'unlock_badges_description': 'Unlock special badges for your achievements',
      'badge_first_steps': 'First Steps',
      'badge_first_steps_description': 'Complete 3 consecutive days',
      'badge_month_master': 'Monthly Master',
      'badge_month_master_description': 'Complete 30 consecutive days',
      'badge_time_saver': 'Time Saver',
      'badge_time_saver_description': 'Save 50 free hours',
      'badge_early_bird': 'Early Bird',
      'badge_early_bird_description': 'Complete 5 days before noon',
      'badge_streak_master': 'Streak Master',
      'badge_streak_master_description': 'Maintain 10 consecutive days',
      'badge_goal_crusher': 'Goal Crusher',
      'badge_goal_crusher_description': 'Meet all weekly goals',
      'badge_zen_master': 'Zen Master',
      'badge_zen_master_description': '10 free hours in a day',
      'badge_night_owl': 'Night Owl',
      'badge_night_owl_description': 'Complete 5 days after midnight',
      'badge_unstoppable': 'Unstoppable',
      'badge_unstoppable_description': '15 consecutive days without missing',
      'badge_legend': 'Legend',
      'badge_legend_description': 'Complete 100 consecutive days',
      
      // Edit Profile Screen
      'edit_profile_title': 'Edit profile',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'delete_photo': 'Delete photo',
      'error_selecting_image': 'Error selecting image',
      'profile_updated_successfully': 'Profile updated successfully',
      'error_updating_profile': 'Error updating profile',
      'user_not_found': 'User not found',
      'save_changes': 'Save changes',
      'invalid_age_range': 'Invalid age range',
      
      // Register Screen - Dialog messages
      'registration_success': 'Registration successful!',
      'welcome_to_app': 'Welcome to NoFaceZone!',
      'account_created_message': 'Your account has been created successfully. You can now sign in and start controlling your time on Facebook.',
      'registration_error': 'Registration error',
      'unknown_error': 'Unknown error',
      'minimum_6_characters': 'Minimum 6 characters',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters para acceso directo a traducciones comunes
  String get appName => translate('app_name');
  String get welcome => translate('welcome');
  String get loading => translate('loading');
  String get save => translate('save');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get close => translate('close');
  String get confirm => translate('confirm');
  String get yes => translate('yes');
  String get no => translate('no');
  String get ok => translate('ok');
  String get settings => translate('settings');
  String get appearance => translate('appearance');
  String get theme => translate('theme');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get spanish => translate('spanish');
  String get english => translate('english');
  String get languageUpdated => translate('language_updated');
  String get system => translate('system');
  String get light => translate('light');
  String get dark => translate('dark');
  String get appearanceDescription => translate('appearance_description');
  String get selectLanguageDescription => translate('select_language_description');
  String get selectTheme => translate('select_theme');
  String get profile => translate('profile');
  String get editProfile => translate('edit_profile');
  String get name => translate('name');
  String get email => translate('email');
  String get emailCannotChange => translate('email_cannot_change');
  String get selectLanguageField => translate('select_language_field');
  String get notifications => translate('notifications');
  String get enableNotifications => translate('enable_notifications');
  String get notificationInterval => translate('notification_interval');
  String get minutes => translate('minutes');
  String get minute => translate('minute');
  String get timeConnector => translate('time_connector');
  String get usageLimits => translate('usage_limits');
  String get dailyLimit => translate('daily_limit');
  String get weeklyGoal => translate('weekly_goal');
  String get hours => translate('hours');
  String get hour => translate('hour');
  String get advanced => translate('advanced');
  String get exportData => translate('export_data');
  String get resetApp => translate('reset_app');
  String get logout => translate('logout');
  String get privateMode => translate('private_mode');
  String get about => translate('about');
  String get version => translate('version');
  String get appDescription => translate('app_description');
  String get home => translate('home');
  String get today => translate('today');
  String get statistics => translate('statistics');
  String get rewards => translate('rewards');
  String get login => translate('login');
  String get register => translate('register');
  String get password => translate('password');
  String get forgotPassword => translate('forgot_password');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get noDataToExport => translate('no_data_to_export');
  String get dataExported => translate('data_exported');
  String get resetConfirmation => translate('reset_confirmation');
  String get resetWarning => translate('reset_warning');
  String get fullName => translate('full_name');
  String get age => translate('age');
  String get ageOver18 => translate('age_over_18');
  String get gender => translate('gender');
  String get selectGender => translate('select_gender');
  String get male => translate('male');
  String get female => translate('female');
  String get nonBinary => translate('non_binary');
  String get preferNotSay => translate('prefer_not_say');
  String get facebookUsageFrequency => translate('facebook_usage_frequency');
  String get selectFrequency => translate('select_frequency');
  String get veryFrequent => translate('very_frequent');
  String get frequent => translate('frequent');
  String get moderate => translate('moderate');
  String get lowFrequency => translate('low_frequency');
  String get confirmPassword => translate('confirm_password');
  String get passwordStrength => translate('password_strength');
  String get veryWeak => translate('very_weak');
  String get weak => translate('weak');
  String get regular => translate('regular');
  String get strong => translate('strong');
  String get veryStrong => translate('very_strong');
  String get years => translate('years');
  String get nameRequired => translate('name_required');
  String get nameMinLength => translate('name_min_length');
  String get nameMaxLength => translate('name_max_length');
  String get nameInvalid => translate('name_invalid');
  String get ageRequired => translate('age_required');
  String get ageInvalid => translate('age_invalid');
  String get ageMin18 => translate('age_min_18');
  String get emailRequired => translate('email_required');
  String get emailInvalid => translate('email_invalid');
  String get emailNoSpaces => translate('email_no_spaces');
  String get emailTempNotAllowed => translate('email_temp_not_allowed');
  String get passwordRequired => translate('password_required');
  String get passwordMin => translate('password_min');
  String get passwordNoSpaces => translate('password_no_spaces');
  String get passwordConfirm => translate('password_confirm');
  String get passwordMismatch => translate('password_mismatch');
  String get showPasswordA11y => translate('show_password_a11y');
  String get hidePasswordA11y => translate('hide_password_a11y');
  String get appSubtitle => translate('app_subtitle');
  String get appDescriptionText => translate('app_description_text');
  String get getStarted => translate('get_started');
  String get createAccount => translate('create_account');
  String get signUp => translate('sign_up');
  String get signIn => translate('sign_in');
  String get forgotPasswordText => translate('forgot_password_text');
  String get passwordRecoveryNotImplemented => translate('password_recovery_not_implemented');
  String get usageLimitsTitle => translate('usage_limits_title');
  String get timeLimitsTitle => translate('time_limits_title');
  String get timeLimitsSubtitle => translate('time_limits_subtitle');
  String get dailyLimitTitle => translate('daily_limit_title');
  String get dailyLimitDescription => translate('daily_limit_description');
  String get weeklyGoalTitle => translate('weekly_goal_title');
  String get weeklyGoalDescription => translate('weekly_goal_description');
  String get dailyLimitDialogTitle => translate('daily_limit_dialog_title');
  String get enterMinutes => translate('enter_minutes');
  String get dailyLimitUpdated => translate('daily_limit_updated');
  String get workLimitLabel => translate('work_limit_label');
  String get personalLimitLabel => translate('personal_limit_label');
  String get alertMessage => translate('alert_message');
  String get configureDailyGoals => translate('configure_daily_goals');
  String get weeklyGoalDialogTitle => translate('weekly_goal_dialog_title');
  String get enterHours => translate('enter_hours');
  String get weeklyGoalUpdated => translate('weekly_goal_updated');
  String get advancedSettingsTitle => translate('advanced_settings_title');
  String get exportDataTitle => translate('export_data_title');
  String get exportDataDescription => translate('export_data_description');
  String get importDataTitle => translate('import_data_title');
  String get importDataDescription => translate('import_data_description');
  String get resetSettingsTitle => translate('reset_settings_title');
  String get resetSettingsDescription => translate('reset_settings_description');
  String get resetSettingsConfirm => translate('reset_settings_confirm');
  String get aboutTitle => translate('about_title');
  String get versionTitle => translate('version_title');
  String get appInfo => translate('app_info');
  String get termsAndConditions => translate('terms_and_conditions');
  String get readLegalDocuments => translate('read_legal_documents');
  String get privacyPolicy => translate('privacy_policy');
  String get howWeProtectData => translate('how_we_protect_data');
  String get contact => translate('contact');
  String get supportAndSuggestions => translate('support_and_suggestions');
  String get goodMorning => translate('good_morning');
  String get goodAfternoon => translate('good_afternoon');
  String get goodEvening => translate('good_evening');
  String get user => translate('user');
  String get messageOfDay => translate('message_of_day');
  String get usageSummary => translate('usage_summary');
  String get timeWithoutFacebook => translate('time_without_facebook');
  String get blockedSessions => translate('blocked_sessions');
  String get timeSaved => translate('time_saved');
  String get consecutiveDays => translate('consecutive_days');
  String get usageLimitsTitleHome => translate('usage_limits_title_home');
  String get dailyLimitHome => translate('daily_limit_home');
  String get nightBlock => translate('night_block');
  String get active => translate('active');
  String get featureOff => translate('feature_off');
  String get usageStatusStandby => translate('usage_status_standby');
  String get mandatoryBreaks => translate('mandatory_breaks');
  String get nextIn => translate('next_in');
  String get remaining => translate('remaining');
  String get weeklyProgress => translate('weekly_progress');
  String get daysCompleted => translate('days_completed');
  String get ofWord => translate('of_word');
  String get quickNavigation => translate('quick_navigation');
  String get notificationsTitle => translate('notifications_title');
  String get enableNotificationsTitle => translate('enable_notifications_title');
  String get receiveAlerts => translate('receive_alerts');
  String get notificationIntervalTitle => translate('notification_interval_title');
  String get reminderFrequency => translate('reminder_frequency');
  String get dataExportedTitle => translate('data_exported_title');
  String get dataPreparedForExport => translate('data_prepared_for_export');
  String get dataCopied => translate('data_copied');
  String get copy => translate('copy');
  String get importDataTitleDialog => translate('import_data_title_dialog');
  String get pasteJson => translate('paste_json');
  String get pasteJsonHere => translate('paste_json_here');
  String get import => translate('import');
  String get dataImportedSuccessfully => translate('data_imported_successfully');
  String get invalidJson => translate('invalid_json');
  String get exportError => translate('export_error');
  String get importError => translate('import_error');
  String get reportsAndExportation => translate('reports_and_exportation');
  String get reportsAndExportationDescription => translate('reports_and_exportation_description');
  String get selectPeriod => translate('select_period');
  String get selectPeriodDescription => translate('select_period_description');
  String get from => translate('from');
  String get to => translate('to');
  String get selectDate => translate('select_date');
  String get reportsLastWeek => translate('reports_last_week');
  String get reportsLastMonth => translate('reports_last_month');
  String get generateReport => translate('generate_report');
  String get reportGenerated => translate('report_generated');
  String get reportError => translate('report_error');
  String get selectDateRange => translate('select_date_range');
  String get invalidDateRange => translate('invalid_date_range');
  String get reportTitle => translate('report_title');
  String get reportPeriod => translate('report_period');
  String get totalTimeFree => translate('total_time_free');
  String get blockedSessionsCount => translate('blocked_sessions_count');
  String get timeSavedTotal => translate('time_saved_total');
  String get consecutiveDaysCount => translate('consecutive_days_count');
  String get dailyAverageTime => translate('daily_average_time');
  String get generatedOn => translate('generated_on');
  String get userLabel => translate('user_label');
  String get emailLabelReport => translate('email_label_report');
  String get day => translate('day');
  String get days => translate('days');
  String get configuration => translate('configuration');
  String get dailyLimitLabel => translate('daily_limit_label');
  String get weeklyGoalLabel => translate('weekly_goal_label');
  String get recordFreeTime => translate('record_free_time');
  String get hoursShort => translate('hours_short');
  String get minutesShort => translate('minutes_short');
  String get termsTitle => translate('terms_title');
  String get lastUpdate => translate('last_update');
  String get termsSection1Title => translate('terms_section_1_title');
  String get termsSection1Text => translate('terms_section_1_text');
  String get termsSection2Title => translate('terms_section_2_title');
  String get termsSection2Text => translate('terms_section_2_text');
  String get termsSection3Title => translate('terms_section_3_title');
  String get termsSection3Text => translate('terms_section_3_text');
  String get termsSection4Title => translate('terms_section_4_title');
  String get termsSection4Text => translate('terms_section_4_text');
  String get termsSection5Title => translate('terms_section_5_title');
  String get termsSection5Text => translate('terms_section_5_text');
  String get privacyTitle => translate('privacy_title');
  String get privacySection1Title => translate('privacy_section_1_title');
  String get privacySection1Text => translate('privacy_section_1_text');
  String get privacySection2Title => translate('privacy_section_2_title');
  String get privacySection2Text => translate('privacy_section_2_text');
  String get privacySection3Title => translate('privacy_section_3_title');
  String get privacySection3Text => translate('privacy_section_3_text');
  String get privacySection4Title => translate('privacy_section_4_title');
  String get privacySection4Text => translate('privacy_section_4_text');
  String get privacySection5Title => translate('privacy_section_5_title');
  String get privacySection5Text => translate('privacy_section_5_text');
  String get privacySection6Title => translate('privacy_section_6_title');
  String get privacySection6Text => translate('privacy_section_6_text');
  String get privacySection7Title => translate('privacy_section_7_title');
  String get privacySection7Text => translate('privacy_section_7_text');
  String get contactTitle => translate('contact_title');
  String get needHelp => translate('need_help');
  String get emailLabel => translate('email_label');
  String get supportLabel => translate('support_label');
  String get helpCenter => translate('help_center');
  String get emailCopied => translate('email_copied');
  String get exitApplication => translate('exit_application');
  String get daySummary => translate('day_summary');
  String get weeklySummary => translate('weekly_summary');
  String get monthlySummary => translate('monthly_summary');
  String get freeTimeFromFacebook => translate('free_time_from_facebook');
  String get totalFreeTime => translate('total_free_time');
  String get dailyAverage => translate('daily_average');
  String get appInfoTitle => translate('app_info_title');
  String get nameLabel => translate('name_label');
  String get versionLabel => translate('version_label');
  String get buildLabel => translate('build_label');
  String get descriptionLabel => translate('description_label');
  String get errorGettingInfo => translate('error_getting_info');
  String get week => translate('week');
  String get month => translate('month');
  String get hourlyActivity => translate('hourly_activity');
  String get effectiveness => translate('effectiveness');
  String get motivation => translate('motivation');
  String get mood => translate('mood');
  String get mentalStrength => translate('mental_strength');
  String get high => translate('high');
  String get good => translate('good');
  String get lastWeek => translate('last_week');
  String get thisWeek => translate('this_week');
  String get weekNumber => translate('week_number');
  String get weeklyComparison => translate('weekly_comparison');
  String get bestStreak => translate('best_streak');
  String get successRate => translate('success_rate');
  String get weeklyActivity => translate('weekly_activity');
  String get monthlyProgress => translate('monthly_progress');
  String get monthlyAchievements => translate('monthly_achievements');
  String get improvement => translate('improvement');
  String get monday => translate('monday');
  String get tuesday => translate('tuesday');
  String get wednesday => translate('wednesday');
  String get thursday => translate('thursday');
  String get friday => translate('friday');
  String get saturday => translate('saturday');
  String get sunday => translate('sunday');
  String get streak7Days => translate('streak_7_days');
  String get weeklyGoalAchieved => translate('weekly_goal_achieved');
  String get hours100Free => translate('100_hours_free');
  String get themes => translate('themes');
  String get fonts => translate('fonts');
  String get messages => translate('messages');
  String get badges => translate('badges');
  String get points => translate('points');
  String get yourPoints => translate('your_points');
  String get pointsText => translate('points_text');
  String get availablePoints => translate('available_points');
  String get motivationDifficultMoments => translate('motivation_difficult_moments');
  String get encouragementMessages => translate('encouragement_messages');
  String get warriorWeekly => translate('warrior_weekly');
  String get complete7Days => translate('complete_7_days');
  String get registrationSuccess => translate('registration_success');
  String get welcomeToApp => translate('welcome_to_app');
  String get accountCreatedMessage => translate('account_created_message');
  String get registrationError => translate('registration_error');
  String get unknownError => translate('unknown_error');
  String get minimum6Characters => translate('minimum_6_characters');
  String get colorThemes => translate('color_themes');
  String get unlockThemesDescription => translate('unlock_themes_description');
  String get themeOceanBlue => translate('theme_ocean_blue');
  String get themeOceanDescription => translate('theme_ocean_description');
  String get themeSunset => translate('theme_sunset');
  String get themeSunsetDescription => translate('theme_sunset_description');
  String get themeForest => translate('theme_forest');
  String get themeForestDescription => translate('theme_forest_description');
  String get themeLavender => translate('theme_lavender');
  String get themeLavenderDescription => translate('theme_lavender_description');
  String get themeCoral => translate('theme_coral');
  String get themeCoralDescription => translate('theme_coral_description');
  String get themeMidnight => translate('theme_midnight');
  String get themeMidnightDescription => translate('theme_midnight_description');
  String themeApplied(String name) => translate('theme_applied').replaceAll('{name}', name);
  String get available => translate('available');
  String get fontTypes => translate('font_types');
  String get customizeFontsDescription => translate('customize_fonts_description');
  String get fontRobotoDescription => translate('font_roboto_description');
  String get fontPlayfairDescription => translate('font_playfair_description');
  String get fontPoppinsDescription => translate('font_poppins_description');
  String get fontComfortaaDescription => translate('font_comfortaa_description');
  String get fontMontserratDescription => translate('font_montserrat_description');
  String fontApplied(String name) => translate('font_applied').replaceAll('{name}', name);
  String get motivationalMessages => translate('motivational_messages');
  String get unlockMessagesDescription => translate('unlock_messages_description');
  String get dailyMessages => translate('daily_messages');
  String get dailyMessagesDescription => translate('daily_messages_description');
  String get achievementMessages => translate('achievement_messages');
  String get achievementMessagesDescription => translate('achievement_messages_description');
  String get wisdomDaily => translate('wisdom_daily');
  String get wisdomDailyDescription => translate('wisdom_daily_description');
  String collectionActivated(String name) => translate('collection_activated').replaceAll('{name}', name);
  String collectionDeactivated(String name) => translate('collection_deactivated').replaceAll('{name}', name);
  String get messageExample1 => translate('message_example_1');
  String get messageExample2 => translate('message_example_2');
  String get messageExample3 => translate('message_example_3');
  String get messageExample4 => translate('message_example_4');
  String get messageExample5 => translate('message_example_5');
  String get messageExample6 => translate('message_example_6');
  String get messageExample7 => translate('message_example_7');
  String get messageExample8 => translate('message_example_8');
  String get messageExample9 => translate('message_example_9');
  String get messageExample10 => translate('message_example_10');
  String get messageExample11 => translate('message_example_11');
  String get messageExample12 => translate('message_example_12');
  String get badgesAndAchievements => translate('badges_and_achievements');
  String get unlockBadgesDescription => translate('unlock_badges_description');
  String get badgeFirstSteps => translate('badge_first_steps');
  String get badgeFirstStepsDescription => translate('badge_first_steps_description');
  String get badgeMonthMaster => translate('badge_month_master');
  String get badgeMonthMasterDescription => translate('badge_month_master_description');
  String get badgeTimeSaver => translate('badge_time_saver');
  String get badgeTimeSaverDescription => translate('badge_time_saver_description');
  String get badgeEarlyBird => translate('badge_early_bird');
  String get badgeEarlyBirdDescription => translate('badge_early_bird_description');
  String get badgeStreakMaster => translate('badge_streak_master');
  String get badgeStreakMasterDescription => translate('badge_streak_master_description');
  String get badgeGoalCrusher => translate('badge_goal_crusher');
  String get badgeGoalCrusherDescription => translate('badge_goal_crusher_description');
  String get badgeZenMaster => translate('badge_zen_master');
  String get badgeZenMasterDescription => translate('badge_zen_master_description');
  String get badgeNightOwl => translate('badge_night_owl');
  String get badgeNightOwlDescription => translate('badge_night_owl_description');
  String get badgeUnstoppable => translate('badge_unstoppable');
  String get badgeUnstoppableDescription => translate('badge_unstoppable_description');
  String get badgeLegend => translate('badge_legend');
  String get badgeLegendDescription => translate('badge_legend_description');
  String get editProfileTitle => translate('edit_profile_title');
  String get gallery => translate('gallery');
  String get camera => translate('camera');
  String get deletePhoto => translate('delete_photo');
  String get errorSelectingImage => translate('error_selecting_image');
  String get profileUpdatedSuccessfully => translate('profile_updated_successfully');
  String get errorUpdatingProfile => translate('error_updating_profile');
  String get userNotFound => translate('user_not_found');
  String get saveChanges => translate('save_changes');
  String get invalidAgeRange => translate('invalid_age_range');
  
  // Emotion Tracking
  String get emotionTracking => translate('emotion_tracking');
  String get emotionTrackingTitle => translate('emotion_tracking_title');
  String get howDoYouFeelToday => translate('how_do_you_feel_today');
  String get selectEmotionDescription => translate('select_emotion_description');
  String get commentOptional => translate('comment_optional');
  String get commentPlaceholder => translate('comment_placeholder');
  String get registerEmotion => translate('register_emotion');
  String get recentLog => translate('recent_log');
  String get recentEmotionsSubtitle => translate('recent_emotions_subtitle');
  String get noEmotionsRegistered => translate('no_emotions_registered');
  String get emotionRegisteredSuccessfully => translate('emotion_registered_successfully');
  String get errorRegisteringEmotion => translate('error_registering_emotion');
  String get pleaseSelectEmotion => translate('please_select_emotion');
  String get deleteEmotion => translate('delete_emotion');
  String get deleteEmotionConfirmation => translate('delete_emotion_confirmation');
  String get emotionDeletedSuccessfully => translate('emotion_deleted_successfully');
  String get errorDeletingEmotion => translate('error_deleting_emotion');
  String get errorLoadingEmotions => translate('error_loading_emotions');
  String get emotionHappy => translate('emotion_happy');
  String get emotionSad => translate('emotion_sad');
  String get emotionNeutral => translate('emotion_neutral');
  String get emotionAnxious => translate('emotion_anxious');
  String get emotionAngry => translate('emotion_angry');
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

