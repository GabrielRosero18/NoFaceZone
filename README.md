# NoFaceZone

App Flutter para autocontrol de uso de Facebook y bienestar digital.

## Qué hace

- Límites de uso diarios con bloqueo dinámico.
- Bloqueo nocturno y pausas obligatorias.
- Seguimiento emocional diario.
- Sistema de puntos, recompensas y badges.
- Recomendaciones de actividades para reemplazar el hábito.
- Recomendaciones de lugares cercanos (OpenStreetMap) con favoritos, filtros y abrir en mapa.

## Stack

- Flutter + Provider
- Supabase (Auth, PostgreSQL, RLS, RPC)
- SharedPreferences (estado local/caché)
- Geolocator + Overpass (OSM)

## Requisitos

- Flutter SDK 3.9.2+
- Proyecto Supabase configurado

## Instalación rápida

```bash
flutter pub get
flutter run
```

## Configuración de Supabase

Toda la documentación técnica está en:

- [`supabase/SUPABASE.md`](./supabase/SUPABASE.md)

Incluye tablas, RLS, RPC, migraciones y troubleshooting.

## Estado de plataformas

- Android
- iOS
- Web
- Windows
- macOS
- Linux

## Nota

NoFaceZone está orientado a formación de hábitos saludables: impedir uso impulsivo y proponer reemplazos accionables.

