# 📖 Guía de Límites de Uso - NoFaceZone

Esta guía explica cómo usar el nuevo sistema de límites de uso dinámico conectado a Supabase.

## 🎯 Características

El nuevo sistema permite:
- ✅ Tracking dinámico del tiempo de uso (no estático)
- ✅ Registro de sesiones individuales
- ✅ Límites configurables por usuario
- ✅ Bloqueo nocturno
- ✅ Pausas obligatorias
- ✅ Estadísticas semanales
- ✅ Sincronización en la nube con Supabase

## 🗄️ Estructura de Tablas

### 1. `limites_uso`
Almacena las configuraciones de límites por usuario:
- Límite diario en minutos
- Bloqueo nocturno (activo/inactivo, horarios)
- Pausas obligatorias (activo/inactivo, intervalo, duración)
- Meta semanal en horas
- Configuración de notificaciones

### 2. `registro_uso_diario`
Registra el tiempo usado cada día:
- Fecha del registro
- Tiempo usado en minutos
- Límite del día
- Número de sesiones

### 3. `sesiones_uso`
Registra sesiones individuales:
- Inicio y fin de sesión
- Duración calculada automáticamente
- Estado (activa, finalizada, interrumpida)

## 🚀 Instalación

### Paso 1: Ejecutar el SQL en Supabase

1. Abre el SQL Editor en tu dashboard de Supabase
2. Copia y pega el contenido de `supabase_usage_limits_schema.sql`
3. Ejecuta el script

Esto creará:
- Las 3 tablas necesarias
- Los índices para optimización
- Las funciones RPC
- Los triggers automáticos
- Las políticas de seguridad (RLS)

### Paso 2: Verificar la Instalación

Puedes verificar que todo se creó correctamente ejecutando:

```sql
-- Verificar tablas
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('limites_uso', 'registro_uso_diario', 'sesiones_uso');

-- Verificar funciones
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%uso%';
```

## 💻 Uso en el Código

### Obtener Límites de Uso

```dart
import 'package:nofacezone/src/Services/UsageLimitsService.dart';

// Obtener o crear límites del usuario actual
final limits = await UsageLimitsService.getOrCreateUsageLimits();
if (limits != null) {
  final dailyLimit = limits['limite_diario_minutos'];
  final weeklyGoal = limits['meta_semanal_horas'];
  final nightBlockActive = limits['bloqueo_nocturno_activo'];
}
```

### Actualizar Límite Diario

```dart
// Actualizar límite diario a 120 minutos (2 horas)
final success = await UsageLimitsService.updateDailyLimit(120);
```

### Iniciar y Finalizar Sesiones

```dart
// Iniciar una sesión de uso
final sessionId = await UsageLimitsService.startUsageSession();

// ... usuario usa la app ...

// Finalizar la sesión
await UsageLimitsService.finishUsageSession(sessionId);
```

### Obtener Tiempo Usado Hoy

```dart
// Obtener tiempo usado hoy en minutos
final todayMinutes = await UsageLimitsService.getTodayUsageMinutes();

// Obtener tiempo restante
final remaining = await UsageLimitsService.getRemainingTimeToday();

// Verificar si alcanzó el límite
final hasReachedLimit = await UsageLimitsService.hasReachedDailyLimit();
```

### Usar con AppProvider

El `AppProvider` ya está integrado con el nuevo servicio:

```dart
// En tu widget
final appProvider = Provider.of<AppProvider>(context);

// Obtener límite diario
final dailyLimit = appProvider.dailyUsageLimit;

// Obtener tiempo usado hoy
final todayUsage = appProvider.todayUsageMinutes;

// Actualizar límite diario
await appProvider.setDailyUsageLimit(120);

// Iniciar sesión
await appProvider.startUsageSession();

// Finalizar sesión
await appProvider.finishUsageSession();

// Recargar límites desde Supabase
await appProvider.refreshUsageLimits();
```

## 🔄 Flujo de Trabajo Recomendado

### Al Abrir la App

1. Cargar límites desde Supabase (automático en `AppProvider`)
2. Verificar si hay sesiones activas sin finalizar
3. Si hay sesiones activas antiguas, finalizarlas

```dart
// En initState o similar
final activeSessions = await UsageLimitsService.getActiveSessions();
for (var session in activeSessions) {
  // Finalizar sesiones antiguas (más de 24 horas)
  final startTime = DateTime.parse(session['inicio_sesion']);
  if (DateTime.now().difference(startTime).inHours > 24) {
    await UsageLimitsService.finishUsageSession(session['id']);
  }
}
```

### Durante el Uso

1. Iniciar sesión cuando el usuario comience a usar la app
2. Actualizar periódicamente el tiempo usado
3. Verificar límites y mostrar alertas si es necesario

```dart
// Iniciar sesión al abrir la app
await appProvider.startUsageSession();

// Timer para actualizar cada minuto
Timer.periodic(Duration(minutes: 1), (timer) async {
  await appProvider.updateTodayUsage();
  
  // Verificar límites
  if (await UsageLimitsService.hasReachedDailyLimit()) {
    // Mostrar alerta
  }
  
  // Verificar bloqueo nocturno
  if (await UsageLimitsService.isInNightBlockTime()) {
    // Bloquear acceso
  }
});
```

### Al Cerrar la App

1. Finalizar sesión activa
2. Guardar estado local si es necesario

```dart
// En dispose o similar
await appProvider.finishUsageSession();
```

## 📊 Estadísticas

### Obtener Estadísticas Semanales

```dart
final stats = await UsageLimitsService.getWeeklyStats();
print('Total minutos: ${stats['total_minutos']}');
print('Total horas: ${stats['total_horas']}');
print('Promedio diario: ${stats['promedio_diario_minutos']} minutos');
print('Días con uso: ${stats['dias_con_uso']}');
```

### Obtener Historial

```dart
// Obtener últimos 7 días
final history = await UsageLimitsService.getUsageHistory(7);

for (var day in history) {
  print('Fecha: ${day['fecha']}');
  print('Tiempo usado: ${day['tiempo_usado_minutos']} minutos');
  print('Sesiones: ${day['numero_sesiones']}');
}
```

## ⚙️ Configuraciones Avanzadas

### Bloqueo Nocturno

```dart
// Activar bloqueo nocturno de 22:00 a 07:00
await UsageLimitsService.updateNightBlock(
  active: true,
  startTime: '22:00:00',
  endTime: '07:00:00',
);

// Verificar si está en horario de bloqueo
final isBlocked = await UsageLimitsService.isInNightBlockTime();
```

### Pausas Obligatorias

```dart
// Activar pausas cada 30 minutos de 5 minutos
await UsageLimitsService.updateMandatoryBreaks(
  active: true,
  intervalMinutes: 30,
  durationMinutes: 5,
);

// Obtener tiempo hasta próxima pausa
final timeUntilBreak = await UsageLimitsService.getTimeUntilNextBreak();
if (timeUntilBreak != null && timeUntilBreak <= 0) {
  // Forzar pausa
}
```

## 🔒 Seguridad

El sistema utiliza Row Level Security (RLS) para asegurar que:
- Los usuarios solo pueden ver y modificar sus propios datos
- No pueden acceder a datos de otros usuarios
- Las políticas están configuradas automáticamente

## 🔄 Migración desde SharedPreferences

El sistema mantiene compatibilidad con SharedPreferences como respaldo:
- Si Supabase falla, usa valores de SharedPreferences
- Los valores se sincronizan en ambas direcciones
- La migración es automática

## 🐛 Solución de Problemas

### Error: "Usuario no autenticado"
- Asegúrate de que el usuario haya iniciado sesión
- Verifica que `Supabase.instance.client.auth.currentUser` no sea null

### Error: "Función no encontrada"
- Verifica que ejecutaste el SQL completo en Supabase
- Asegúrate de que las funciones RPC estén creadas

### Los límites no se actualizan
- Verifica la conexión a internet
- Revisa los logs de Supabase para errores
- El sistema usará SharedPreferences como fallback

## 📝 Notas Importantes

1. **Sesiones Activas**: Siempre finaliza las sesiones activas antes de iniciar nuevas
2. **Sincronización**: Los datos se sincronizan automáticamente con Supabase
3. **Offline**: El sistema funciona offline usando SharedPreferences como respaldo
4. **Performance**: Los triggers automáticos optimizan las actualizaciones

## 🔗 Referencias

- [SUPABASE.md](./SUPABASE.md) - Documentación completa de Supabase
- [supabase_usage_limits_schema.sql](./supabase_usage_limits_schema.sql) - Esquema SQL completo
- [UsageLimitsService.dart](./lib/src/Services/UsageLimitsService.dart) - Código del servicio

