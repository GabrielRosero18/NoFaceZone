# NoFaceZone 📱

**Control de Adicción a Facebook - Toma el control de tu tiempo en redes sociales**

NoFaceZone es una aplicación móvil desarrollada en Flutter diseñada para ayudarte a controlar tu tiempo en Facebook y mejorar tu bienestar digital. Con un sistema de recompensas, seguimiento de emociones y límites de uso personalizables, te ayuda a desarrollar hábitos más saludables en el uso de redes sociales.

## ✨ Características Principales

### 🎯 Control de Uso
- **Límites diarios**: Establece límites de tiempo de uso diario
- **Metas semanales**: Define objetivos de horas por semana
- **Notificaciones**: Recibe alertas cuando alcanzas tus límites
- **Modo privado**: Protege tu privacidad con modo privado

### 🎨 Personalización
- **Temas de colores**: Desbloquea y personaliza temas (Océano, Atardecer, Bosque, Lavanda, Coral, Medianoche)
- **Fuentes**: Elige entre diferentes fuentes tipográficas (Roboto, Playfair Display, Poppins, Comfortaa, Montserrat)
- **Mensajes motivacionales**: Activa colecciones de mensajes inspiradores
- **Idiomas**: Soporte para Español e Inglés

### 🏆 Sistema de Recompensas
- **Puntos**: Gana puntos por acciones diarias
  - Inicio de sesión diario
  - Registro de emociones
  - Completar perfil
  - Actualizar perfil
  - Racha de uso de Facebook
- **Badges**: Desbloquea insignias por logros
  - Primeros Pasos
  - Guerrero Semanal
  - Maestro del Mes
  - Ahorrador de Tiempo
  - Y muchos más...
- **Recompensas**: Gasta puntos para desbloquear temas, fuentes y colecciones de mensajes

### 😊 Seguimiento de Emociones
- Registra tus emociones diarias
- Visualiza tu estado emocional a lo largo del tiempo
- Estadísticas y gráficos de tu bienestar emocional

### 📊 Estadísticas
- Visualiza tu tiempo de uso
- Gráficos de progreso
- Historial de emociones
- Análisis de patrones de uso

### ⚙️ Configuraciones
- Perfil de usuario personalizable
- Exportación de datos
- Reset de aplicación
- Configuración de notificaciones

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework multiplataforma
- **Supabase**: Backend como servicio (BaaS)
  - Autenticación
  - Base de datos PostgreSQL
  - Row Level Security (RLS)
- **Provider**: Gestión de estado
- **SharedPreferences**: Almacenamiento local
- **Google Fonts**: Fuentes tipográficas
- **Image Picker**: Selección de imágenes

## 📋 Requisitos

- Flutter SDK 3.9.2 o superior
- Dart SDK compatible
- Cuenta de Supabase configurada
- Android SDK 21+ (para Android)
- iOS 12.0+ (para iOS)

## 🚀 Instalación

1. **Clona el repositorio**
   ```bash
   git clone https://github.com/tu-usuario/NoFaceZone.git
   cd NoFaceZone
   ```

2. **Instala las dependencias**
   ```bash
   flutter pub get
   ```

3. **Configura Supabase**
   - Crea un proyecto en [Supabase](https://supabase.com)
   - Configura las tablas según `SUPABASE.md`
   - Actualiza las credenciales en `lib/src/Custom/Config.dart`

4. **Ejecuta la aplicación**
   ```bash
   flutter run
   ```

## 📱 Plataformas Soportadas

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 📖 Documentación

Para más información sobre la base de datos y configuración de Supabase, consulta [SUPABASE.md](./SUPABASE.md).

## 🎨 Temas Disponibles

- **Océano Azul** (Por defecto): Tema relajante inspirado en el mar
- **Atardecer**: Colores cálidos del atardecer
- **Bosque Verde**: Tema natural y relajante
- **Lavanda**: Suave y relajante
- **Coral**: Vibrante y energético
- **Medianoche**: Elegante y sofisticado

## 🔐 Privacidad y Seguridad

- Todos los datos se almacenan de forma segura en Supabase
- Row Level Security (RLS) implementado para proteger los datos del usuario
- Modo privado disponible para mayor privacidad
- Exportación de datos para respaldo

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver el archivo `LICENSE` para más detalles.

## 👨‍💻 Autor

Desarrollado con ❤️ para ayudar a las personas a tener una relación más saludable con las redes sociales.

## 📞 Soporte

Si tienes preguntas o necesitas ayuda, por favor abre un issue en el repositorio.

---

**¡Toma el control de tu tiempo digital y mejora tu bienestar!** 🌟

