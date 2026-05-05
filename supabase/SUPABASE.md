# Supabase en NoFaceZone

Guía técnica del backend de NoFaceZone en Supabase: esquema, migraciones, RPC, RLS y checklist de operación.

## Resumen del backend

NoFaceZone usa Supabase para:

- Autenticación (`auth.users`)
- Datos de usuario y emociones
- Límites de uso y sesiones en tiempo real
- Sistema de puntos/recompensas
- Eventos de recompensas y loadout activo

## Estructura de carpetas

Migraciones SQL actuales:

- `supabase/migrations/20260429_rewards_revamp.sql`
- `supabase/migrations/20260429_rewards_content_expansion.sql`
- `supabase/migrations/20260504_clock_styles_rewards.sql`

> Recomendación: ejecutar en orden cronológico.

## Tablas principales

### Núcleo de usuario

- `usuarios`: perfil extendido del usuario.
- `emociones`: registros emocionales por día.

### Límites de uso

- `limites_uso`: configuración por usuario (límite diario, bloqueo nocturno, pausas, meta semanal, notificaciones).
- `registros_uso_diario`: snapshot diario (`tiempo_usado_minutos`, `limite_del_dia_minutos`, sesiones).
- `sesiones_uso`: sesiones activas/finalizadas con duración.

### Recompensas y puntos

- `tipos_recompensas`
- `recompensas`
- `recompensas_usuario`
- `puntos_usuario`
- `transacciones_puntos`
- `reward_events` (analytics de interacción en tienda)
- `reward_loadout` (tema/fuente/colecciones activas)

## Funciones RPC usadas por la app

### Límites de uso

- `obtener_o_crear_limites_uso(p_usuario_id uuid)`
- `obtener_registro_dia_actual(p_usuario_id uuid)`
- `iniciar_sesion_uso(p_usuario_id uuid)`
- `finalizar_sesion_uso(p_sesion_id integer)`

### Recompensas

- `obtener_recompensas_usuario(p_usuario_id uuid)`
- `comprar_recompensa(p_usuario_id uuid, p_recompensa_id text)`
- `agregar_puntos_usuario(p_usuario_id uuid, p_puntos integer, p_descripcion text)`
- `obtener_resumen_rewards_usuario(p_usuario_id uuid)`

## Triggers y automatizaciones

- `update_updated_at_column`: mantiene `updated_at` consistente.
- Cálculo/propagación de duración de sesiones a registro diario.
- Trigger de puntos: sincroniza `puntos_usuario` al insertar transacciones.
- Trigger de `reward_loadout`: actualización automática de `updated_at`.

## RLS (Row Level Security)

Política general: el usuario autenticado (`auth.uid()`) solo accede a sus filas.

Aplicado en:

- `usuarios`, `emociones`
- `limites_uso`, `registros_uso_diario`, `sesiones_uso`
- `recompensas_usuario`, `puntos_usuario`, `transacciones_puntos`
- `reward_events`, `reward_loadout`

## Cambios recientes integrados en app

### Gamificación avanzada (app + Supabase)

- XP por actividad con multiplicadores por racha y anti-farm (lado app).
- Bonus anti-recaída y cap diario de actividades con puntos.
- Integrado sobre `agregar_puntos_usuario` y `transacciones_puntos`.

### Catálogo de recompensas expandido

- Nuevos temas, fuentes y colecciones de mensajes (`20260429_rewards_content_expansion.sql`).
- Soporte de estilos de reloj en catálogo (`clock_*`, migración `20260504_clock_styles_rewards.sql`).

### Analytics y loadout

- `reward_events`: tracking de clicks, compras, apply.
- `reward_loadout`: estado visual activo del usuario.

## Setup recomendado en entorno nuevo

1. Crear proyecto Supabase.
2. Configurar Auth Email (si app espera sesión inmediata, desactivar confirmación por email).
3. Ejecutar migraciones en orden.
4. Validar tablas y RPC:

```sql
select table_name
from information_schema.tables
where table_schema = 'public'
order by table_name;
```

```sql
select routine_name
from information_schema.routines
where routine_schema = 'public'
order by routine_name;
```

5. Verificar RLS habilitado en tablas críticas.

## Troubleshooting rápido

- Error `cannot change return type of existing function`:
  - hacer `drop function if exists ...` y recrear.
- Error `p_usuario_id no puede ser null` en SQL editor:
  - usar UUID explícito en pruebas manuales.
- Si no actualiza tiempo restante:
  - revisar sesión activa en `sesiones_uso` y que `finalizar_sesion_uso` impacte `registros_uso_diario`.

## Consultas útiles

Sesiones activas:

```sql
select * from sesiones_uso
where estado = 'activa'
order by inicio_sesion desc;
```

Uso diario reciente:

```sql
select fecha, tiempo_usado_minutos, limite_del_dia_minutos, numero_sesiones
from registros_uso_diario
order by fecha desc
limit 14;
```

Puntos y transacciones:

```sql
select * from puntos_usuario where usuario_id = 'TU_UUID';
select * from transacciones_puntos where usuario_id = 'TU_UUID' order by created_at desc limit 20;
```

## Nota de seguridad

- No documentar ni commitear claves sensibles (service role).
- Usar solo clave pública anon en cliente.
- Preferir RPC con `security definer` + validación de `auth.uid()`.
