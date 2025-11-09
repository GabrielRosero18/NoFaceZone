# 📊 Supabase - NoFaceZone

## 🔑 Credenciales de la API

### Proyecto
- **Nombre**: NoFaceZone_
- **URL**: `https://agpqnbzmnqvtyxasegni.supabase.co`

### API Keys
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFncHFuYnptbnF2dHl4YXNlZ25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NjQyMzMsImV4cCI6MjA3ODE0MDIzM30.otiN38phJJiW9iSLW_LqXAhNjsm1DjiTHMSJV3Sdt7g`

### Configuración en el Código
**Archivo**: `lib/src/Custom/Config.dart`

```dart
static const String mSupabaseUrl = "https://agpqnbzmnqvtyxasegni.supabase.co";
static const String mSupabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFncHFuYnptbnF2dHl4YXNlZ25pIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI1NjQyMzMsImV4cCI6MjA3ODE0MDIzM30.otiN38phJJiW9iSLW_LqXAhNjsm1DjiTHMSJV3Sdt7g";
```

---

## 📋 Tablas de la Base de Datos

### 1. Tabla: `usuarios`

Almacena la información de los usuarios de la aplicación.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id_usuario` | SERIAL | ID único del usuario (auto-increment) | PRIMARY KEY |
| `auth_user_id` | UUID | ID del usuario en Supabase Auth | UNIQUE, opcional |
| `nombre` | VARCHAR(255) | Nombre completo del usuario | NOT NULL |
| `edad` | INTEGER | Edad del usuario | NOT NULL, CHECK (edad > 0 AND edad < 150) |
| `genero` | VARCHAR(50) | Género del usuario | NOT NULL |
| `email` | VARCHAR(255) | Email del usuario | UNIQUE, NOT NULL |
| `idioma_preferido` | VARCHAR(50) | Idioma preferido del usuario | Opcional |
| `frecuencia_uso_facebook` | VARCHAR(100) | Frecuencia de uso de Facebook | Opcional |
| `usuario_facebook` | VARCHAR(255) | Nombre de usuario de Facebook | DEFAULT '' |
| `contraseña` | VARCHAR(255) | Contraseña del usuario | NOT NULL |
| `foto_perfil` | TEXT | URL de la foto de perfil | Opcional |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Índices
- `idx_usuarios_email` - Índice en `email`
- `idx_usuarios_auth_user_id` - Índice en `auth_user_id`

---

### 2. Tabla: `emociones`

Almacena las emociones registradas por los usuarios.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | SERIAL | ID único de la emoción (auto-increment) | PRIMARY KEY |
| `emotion` | VARCHAR(50) | Tipo de emoción | NOT NULL, CHECK (emotion IN ('feliz', 'triste', 'neutro', 'ansioso', 'enojado')) |
| `comment` | TEXT | Comentario opcional sobre la emoción | Opcional |
| `user_id` | UUID | ID del usuario de Supabase Auth | NOT NULL |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Valores Permitidos para `emotion`
- `feliz`
- `triste`
- `neutro`
- `ansioso`
- `enojado`

#### Índices
- `idx_emociones_user_id` - Índice en `user_id`
- `idx_emociones_created_at` - Índice en `created_at` (DESC)

---

### 3. Tabla: `tipos_recompensas`

Categoriza las recompensas en diferentes tipos.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | TEXT | ID único del tipo | PRIMARY KEY |
| `name` | TEXT | Nombre del tipo | NOT NULL |
| `description` | TEXT | Descripción del tipo | Opcional |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Tipos Disponibles
- `theme` - Temas de colores
- `font` - Tipografías
- `message` - Colecciones de mensajes
- `badge` - Insignias y logros

---

### 4. Tabla: `recompensas`

Tabla principal que almacena todas las recompensas disponibles en el sistema.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | TEXT | Identificador único (ej: 'theme_ocean', 'font_roboto') | PRIMARY KEY |
| `tipo_recompensa_id` | TEXT | Tipo de recompensa | NOT NULL, REFERENCES tipos_recompensas(id) |
| `name` | TEXT | Nombre por defecto | NOT NULL |
| `name_es` | TEXT | Nombre en español | Opcional |
| `name_en` | TEXT | Nombre en inglés | Opcional |
| `description` | TEXT | Descripción por defecto | Opcional |
| `description_es` | TEXT | Descripción en español | Opcional |
| `description_en` | TEXT | Descripción en inglés | Opcional |
| `price` | INTEGER | Precio en puntos | NOT NULL, DEFAULT 0 |
| `icon_name` | TEXT | Nombre del icono a mostrar | Opcional |
| `is_default` | BOOLEAN | Si es la recompensa por defecto | DEFAULT FALSE |
| `is_active` | BOOLEAN | Si está activa/disponible | DEFAULT TRUE |
| `display_order` | INTEGER | Orden de visualización | DEFAULT 0 |
| `metadata` | JSONB | Datos adicionales (colores, ejemplos, etc.) | Opcional |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Índices
- `idx_recompensas_tipo` - Índice en `tipo_recompensa_id`
- `idx_recompensas_activa` - Índice en `is_active`

#### Metadata JSONB

El campo `metadata` almacena información específica por tipo:

**Temas:**
```json
{
  "colors": ["#7F53AC", "#647DEE", "#B8C1FF"]
}
```

**Fuentes:**
```json
{
  "fontFamily": "Roboto"
}
```

**Mensajes:**
```json
{
  "examples": ["Mensaje 1", "Mensaje 2", "Mensaje 3"]
}
```

**Badges:**
```json
{
  "color": "#2196F3",
  "progress": 1.0
}
```

---

### 5. Tabla: `recompensas_usuario`

Almacena qué recompensas tiene cada usuario.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | UUID | ID único del registro | PRIMARY KEY, DEFAULT gen_random_uuid() |
| `usuario_id` | UUID | ID del usuario (auth.users) | NOT NULL, REFERENCES auth.users(id) |
| `recompensa_id` | TEXT | ID de la recompensa | NOT NULL, REFERENCES recompensas(id) |
| `is_active` | BOOLEAN | Si está activa actualmente | DEFAULT TRUE |
| `unlocked_at` | TIMESTAMP WITH TIME ZONE | Cuándo se desbloqueó | DEFAULT NOW() |
| `purchased_at` | TIMESTAMP WITH TIME ZONE | Cuándo se compró (si aplica) | Opcional |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Restricciones
- `UNIQUE(usuario_id, recompensa_id)` - Un usuario no puede tener la misma recompensa duplicada

#### Índices
- `idx_recompensas_usuario_usuario` - Índice en `usuario_id`

---

### 6. Tabla: `puntos_usuario`

Almacena los puntos de cada usuario.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | UUID | ID único del registro | PRIMARY KEY, DEFAULT gen_random_uuid() |
| `usuario_id` | UUID | ID del usuario (auth.users) | NOT NULL, UNIQUE, REFERENCES auth.users(id) |
| `puntos_totales` | INTEGER | Puntos totales acumulados | NOT NULL, DEFAULT 0 |
| `puntos_actuales` | INTEGER | Puntos disponibles actuales | NOT NULL, DEFAULT 0 |
| `puntos_gastados` | INTEGER | Puntos gastados | NOT NULL, DEFAULT 0 |
| `last_updated` | TIMESTAMP WITH TIME ZONE | Última actualización | DEFAULT NOW() |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

#### Índices
- `idx_puntos_usuario_usuario` - Índice en `usuario_id`

---

### 7. Tabla: `transacciones_puntos`

Registra todas las transacciones de puntos (ganados o gastados).

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | UUID | ID único de la transacción | PRIMARY KEY, DEFAULT gen_random_uuid() |
| `usuario_id` | UUID | ID del usuario (auth.users) | NOT NULL, REFERENCES auth.users(id) |
| `puntos` | INTEGER | Cantidad de puntos (positivo para ganar, negativo para gastar) | NOT NULL |
| `tipo_transaccion` | TEXT | Tipo de transacción | NOT NULL |
| `descripcion` | TEXT | Descripción de la transacción | Opcional |
| `recompensa_id` | TEXT | ID de la recompensa relacionada (si aplica) | Opcional, REFERENCES recompensas(id) |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |

#### Tipos de Transacción
- `earned` - Puntos ganados
- `spent` - Puntos gastados
- `reward_purchase` - Compra de recompensa

#### Índices
- `idx_transacciones_puntos_usuario` - Índice en `usuario_id`
- `idx_transacciones_puntos_tipo` - Índice en `tipo_transaccion`
- `idx_transacciones_puntos_creada` - Índice en `created_at` (DESC)

---

## 🔒 Políticas de Seguridad (RLS)

### Tabla `usuarios`
- **SELECT**: Los usuarios solo pueden ver su propia información
- **INSERT**: Los usuarios pueden insertar su propia información durante el registro
- **UPDATE**: Los usuarios solo pueden actualizar su propia información
- **DELETE**: No permitido (solo administradores)

### Tabla `emociones`
- **SELECT**: Los usuarios solo pueden ver sus propias emociones
- **INSERT**: Los usuarios pueden insertar sus propias emociones
- **UPDATE**: Los usuarios solo pueden actualizar sus propias emociones
- **DELETE**: Los usuarios pueden eliminar sus propias emociones

### Tabla `recompensas`
- **SELECT**: Todos pueden ver las recompensas disponibles (is_active = true)

### Tabla `recompensas_usuario`
- **SELECT**: Los usuarios solo pueden ver sus propias recompensas
- **INSERT**: Los usuarios pueden insertar sus propias recompensas
- **UPDATE**: Los usuarios solo pueden actualizar sus propias recompensas

### Tabla `puntos_usuario`
- **SELECT**: Los usuarios solo pueden ver sus propios puntos
- **INSERT**: Los usuarios pueden insertar sus propios puntos
- **UPDATE**: Los usuarios solo pueden actualizar sus propios puntos

### Tabla `transacciones_puntos`
- **SELECT**: Los usuarios solo pueden ver sus propias transacciones
- **INSERT**: Los usuarios pueden insertar sus propias transacciones

---

## 🔧 Funciones SQL

### 1. `obtener_recompensas_usuario(p_usuario_id UUID)`

Obtiene todas las recompensas de un usuario, indicando cuáles tiene desbloqueadas.

**Parámetros:**
- `p_usuario_id` - UUID del usuario

**Retorna:**
- `recompensa_id` - ID de la recompensa
- `tipo_recompensa` - Tipo de recompensa
- `nombre` - Nombre de la recompensa
- `descripcion` - Descripción
- `precio` - Precio en puntos
- `esta_desbloqueada` - Si está desbloqueada
- `esta_activa` - Si está activa
- `desbloqueada_en` - Cuándo se desbloqueó
- `metadata` - Datos adicionales

**Ejemplo:**
```sql
SELECT * FROM obtener_recompensas_usuario('user-uuid-here');
```

---

### 2. `comprar_recompensa(p_usuario_id UUID, p_recompensa_id TEXT)`

Compra una recompensa con puntos del usuario.

**Parámetros:**
- `p_usuario_id` - UUID del usuario
- `p_recompensa_id` - ID de la recompensa a comprar

**Retorna:**
- `success` - Si la compra fue exitosa
- `error` - Mensaje de error (si aplica)
- `puntos_restantes` - Puntos restantes después de la compra

**Ejemplo:**
```sql
SELECT comprar_recompensa('user-uuid-here', 'theme_sunset');
```

---

### 3. `agregar_puntos_usuario(p_usuario_id UUID, p_puntos INTEGER, p_descripcion TEXT)`

Agrega puntos a un usuario.

**Parámetros:**
- `p_usuario_id` - UUID del usuario
- `p_puntos` - Cantidad de puntos a agregar
- `p_descripcion` - Descripción de la transacción (opcional, default: 'Puntos ganados')

**Retorna:**
- `success` - Si fue exitoso
- `puntos_agregados` - Puntos agregados
- `puntos_totales` - Total de puntos actuales

**Ejemplo:**
```sql
SELECT agregar_puntos_usuario('user-uuid-here', 50, 'Completaste un día');
```

---

## ⚙️ Triggers

### 1. `update_updated_at_column()`

Actualiza automáticamente el campo `updated_at` cuando se modifica un registro.

**Aplicado a:**
- `usuarios`
- `emociones`
- `recompensas`
- `recompensas_usuario`
- `puntos_usuario`

---

### 2. `actualizar_puntos_usuario()`

Actualiza automáticamente la tabla `puntos_usuario` cuando se crea una transacción en `transacciones_puntos`.

**Aplicado a:**
- `transacciones_puntos` (AFTER INSERT)

**Funcionalidad:**
- Crea el registro en `puntos_usuario` si no existe
- Actualiza `puntos_totales`, `puntos_actuales` y `puntos_gastados`
- Actualiza `last_updated` y `updated_at`

---

## 📊 Datos Iniciales

### Tipos de Recompensas
- `theme` - Temas de colores para personalizar la aplicación
- `font` - Tipografías para personalizar la aplicación
- `message` - Colecciones de mensajes motivacionales
- `badge` - Insignias y logros por completar objetivos

### Recompensas por Defecto
- **Temas**: Océano Azul (gratis)
- **Fuentes**: Roboto (gratis)
- **Mensajes**: Diarios (gratis)
- **Badges**: Primeros Pasos (gratis)

---

## 🛠️ Script SQL para Crear las Tablas

```sql
-- Tabla: usuarios
CREATE TABLE IF NOT EXISTS public.usuarios (
    id_usuario SERIAL PRIMARY KEY,
    auth_user_id UUID UNIQUE,
    nombre VARCHAR(255) NOT NULL,
    edad INTEGER NOT NULL CHECK (edad > 0 AND edad < 150),
    genero VARCHAR(50) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    idioma_preferido VARCHAR(50),
    frecuencia_uso_facebook VARCHAR(100),
    usuario_facebook VARCHAR(255) DEFAULT '',
    contraseña VARCHAR(255) NOT NULL,
    foto_perfil TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Tabla: emociones
CREATE TABLE IF NOT EXISTS public.emociones (
    id SERIAL PRIMARY KEY,
    emotion VARCHAR(50) NOT NULL CHECK (emotion IN ('feliz', 'triste', 'neutro', 'ansioso', 'enojado')),
    comment TEXT,
    user_id UUID NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON public.usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_auth_user_id ON public.usuarios(auth_user_id);
CREATE INDEX IF NOT EXISTS idx_emociones_user_id ON public.emociones(user_id);
CREATE INDEX IF NOT EXISTS idx_emociones_created_at ON public.emociones(created_at DESC);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_usuarios_updated_at 
    BEFORE UPDATE ON public.usuarios 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_emociones_updated_at 
    BEFORE UPDATE ON public.emociones 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Habilitar RLS
ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.emociones ENABLE ROW LEVEL SECURITY;
```

**Nota**: Para el esquema completo del sistema de recompensas, ver el archivo `supabase_rewards_schema.sql`

---

## 📋 Tablas de Límites de Uso

Estas tablas gestionan los límites de uso de forma dinámica, permitiendo tracking en tiempo real del tiempo de uso.

### 1. Tabla: `limites_uso`

Almacena las configuraciones de límites de uso por usuario.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | SERIAL | ID único del límite | PRIMARY KEY |
| `usuario_id` | UUID | ID del usuario en Supabase Auth | NOT NULL, UNIQUE, FOREIGN KEY |
| `limite_diario_minutos` | INTEGER | Límite diario en minutos | NOT NULL, DEFAULT 60, CHECK (1-1440) |
| `bloqueo_nocturno_activo` | BOOLEAN | Si el bloqueo nocturno está activo | NOT NULL, DEFAULT false |
| `bloqueo_nocturno_inicio` | TIME | Hora de inicio del bloqueo | NOT NULL, DEFAULT '22:00:00' |
| `bloqueo_nocturno_fin` | TIME | Hora de fin del bloqueo | NOT NULL, DEFAULT '07:00:00' |
| `pausas_obligatorias_activas` | BOOLEAN | Si las pausas obligatorias están activas | NOT NULL, DEFAULT false |
| `intervalo_pausa_minutos` | INTEGER | Intervalo entre pausas en minutos | NOT NULL, DEFAULT 30 |
| `duracion_pausa_minutos` | INTEGER | Duración de cada pausa en minutos | NOT NULL, DEFAULT 5 |
| `meta_semanal_horas` | INTEGER | Meta semanal en horas | NOT NULL, DEFAULT 10, CHECK (1-168) |
| `notificaciones_activas` | BOOLEAN | Si las notificaciones están activas | NOT NULL, DEFAULT true |
| `intervalo_notificacion_minutos` | INTEGER | Intervalo de notificaciones en minutos | NOT NULL, DEFAULT 15 |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

---

### 2. Tabla: `registros_uso_diario`

Registra el tiempo de uso por día para cada usuario.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | SERIAL | ID único del registro | PRIMARY KEY |
| `usuario_id` | UUID | ID del usuario en Supabase Auth | NOT NULL, FOREIGN KEY |
| `fecha` | DATE | Fecha del registro | NOT NULL, DEFAULT CURRENT_DATE |
| `tiempo_usado_minutos` | INTEGER | Tiempo usado en minutos | NOT NULL, DEFAULT 0, CHECK (>= 0) |
| `limite_del_dia_minutos` | INTEGER | Límite del día en minutos | NOT NULL |
| `numero_sesiones` | INTEGER | Número de sesiones en el día | NOT NULL, DEFAULT 0, CHECK (>= 0) |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

**Índice único**: `(usuario_id, fecha)` - Un usuario solo puede tener un registro por día

**Nota**: El nombre de la tabla está en plural (`registros_uso_diario`) para seguir la convención de las demás tablas del sistema.

---

### 3. Tabla: `sesiones_uso`

Registra sesiones individuales de uso para tracking preciso.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | SERIAL | ID único de la sesión | PRIMARY KEY |
| `usuario_id` | UUID | ID del usuario en Supabase Auth | NOT NULL, FOREIGN KEY |
| `registro_diario_id` | INTEGER | ID del registro diario asociado | FOREIGN KEY, opcional |
| `inicio_sesion` | TIMESTAMP WITH TIME ZONE | Inicio de la sesión | NOT NULL, DEFAULT NOW() |
| `fin_sesion` | TIMESTAMP WITH TIME ZONE | Fin de la sesión | Opcional |
| `duracion_minutos` | INTEGER | Duración en minutos (calculada) | CHECK (>= 0) |
| `estado` | VARCHAR(20) | Estado de la sesión | NOT NULL, DEFAULT 'activa', CHECK (IN ('activa', 'finalizada', 'interrumpida')) |
| `created_at` | TIMESTAMP WITH TIME ZONE | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP WITH TIME ZONE | Fecha de última actualización | DEFAULT NOW() |

---

### Funciones RPC Disponibles

1. **`obtener_o_crear_limites_uso(p_usuario_id UUID)`**
   - Obtiene los límites de uso del usuario o crea unos nuevos con valores por defecto
   - Retorna: `limites_uso`

2. **`obtener_registro_dia_actual(p_usuario_id UUID)`**
   - Obtiene el registro de uso del día actual o crea uno nuevo
   - Retorna: `registros_uso_diario`

3. **`iniciar_sesion_uso(p_usuario_id UUID)`**
   - Inicia una nueva sesión de uso
   - Retorna: `INTEGER` (ID de la sesión)

4. **`finalizar_sesion_uso(p_sesion_id INTEGER)`**
   - Finaliza una sesión de uso y actualiza el registro diario
   - Retorna: `sesiones_uso`

---

### Triggers Automáticos

1. **Actualización de `updated_at`**: Se actualiza automáticamente al modificar registros
2. **Cálculo de duración**: Calcula automáticamente la duración de la sesión al finalizarla
3. **Actualización de registro diario**: Actualiza automáticamente el registro diario cuando se finaliza una sesión

---

---

### Script SQL para Crear las Tablas de Límites de Uso

```sql
-- ============================================
-- ESQUEMA DE LÍMITES DE USO - NoFaceZone
-- ============================================

-- Tabla: limites_uso
CREATE TABLE IF NOT EXISTS public.limites_uso (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    limite_diario_minutos INTEGER NOT NULL DEFAULT 60 CHECK (limite_diario_minutos > 0 AND limite_diario_minutos <= 1440),
    bloqueo_nocturno_activo BOOLEAN NOT NULL DEFAULT false,
    bloqueo_nocturno_inicio TIME NOT NULL DEFAULT '22:00:00',
    bloqueo_nocturno_fin TIME NOT NULL DEFAULT '07:00:00',
    pausas_obligatorias_activas BOOLEAN NOT NULL DEFAULT false,
    intervalo_pausa_minutos INTEGER NOT NULL DEFAULT 30 CHECK (intervalo_pausa_minutos > 0),
    duracion_pausa_minutos INTEGER NOT NULL DEFAULT 5 CHECK (duracion_pausa_minutos > 0),
    meta_semanal_horas INTEGER NOT NULL DEFAULT 10 CHECK (meta_semanal_horas > 0 AND meta_semanal_horas <= 168),
    notificaciones_activas BOOLEAN NOT NULL DEFAULT true,
    intervalo_notificacion_minutos INTEGER NOT NULL DEFAULT 15 CHECK (intervalo_notificacion_minutos > 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id)
);

-- Tabla: registros_uso_diario
CREATE TABLE IF NOT EXISTS public.registros_uso_diario (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    fecha DATE NOT NULL DEFAULT CURRENT_DATE,
    tiempo_usado_minutos INTEGER NOT NULL DEFAULT 0 CHECK (tiempo_usado_minutos >= 0),
    limite_del_dia_minutos INTEGER NOT NULL CHECK (limite_del_dia_minutos > 0),
    numero_sesiones INTEGER NOT NULL DEFAULT 0 CHECK (numero_sesiones >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(usuario_id, fecha)
);

-- Tabla: sesiones_uso
CREATE TABLE IF NOT EXISTS public.sesiones_uso (
    id SERIAL PRIMARY KEY,
    usuario_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    registro_diario_id INTEGER REFERENCES public.registros_uso_diario(id) ON DELETE CASCADE,
    inicio_sesion TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    fin_sesion TIMESTAMP WITH TIME ZONE,
    duracion_minutos INTEGER CHECK (duracion_minutos >= 0),
    estado VARCHAR(20) NOT NULL DEFAULT 'activa' CHECK (estado IN ('activa', 'finalizada', 'interrumpida')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Índices
CREATE INDEX IF NOT EXISTS idx_limites_uso_usuario_id ON public.limites_uso(usuario_id);
CREATE INDEX IF NOT EXISTS idx_registros_uso_diario_usuario_id ON public.registros_uso_diario(usuario_id);
CREATE INDEX IF NOT EXISTS idx_registros_uso_diario_fecha ON public.registros_uso_diario(fecha DESC);
CREATE INDEX IF NOT EXISTS idx_registros_uso_diario_usuario_fecha ON public.registros_uso_diario(usuario_id, fecha DESC);
CREATE INDEX IF NOT EXISTS idx_sesiones_uso_usuario_id ON public.sesiones_uso(usuario_id);
CREATE INDEX IF NOT EXISTS idx_sesiones_uso_registro_diario_id ON public.sesiones_uso(registro_diario_id);
CREATE INDEX IF NOT EXISTS idx_sesiones_uso_inicio_sesion ON public.sesiones_uso(inicio_sesion DESC);
CREATE INDEX IF NOT EXISTS idx_sesiones_uso_estado ON public.sesiones_uso(estado);

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Función para calcular duración de sesión
CREATE OR REPLACE FUNCTION calcular_duracion_sesion()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fin_sesion IS NOT NULL AND NEW.inicio_sesion IS NOT NULL THEN
        NEW.duracion_minutos = EXTRACT(EPOCH FROM (NEW.fin_sesion - NEW.inicio_sesion)) / 60;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Función para actualizar registro diario cuando se finaliza una sesión
CREATE OR REPLACE FUNCTION actualizar_registro_diario()
RETURNS TRIGGER AS $$
DECLARE
    fecha_sesion DATE;
    registro_id INTEGER;
BEGIN
    IF NEW.estado = 'finalizada' AND OLD.estado != 'finalizada' THEN
        fecha_sesion := DATE(NEW.inicio_sesion);
        
        SELECT id INTO registro_id
        FROM public.registros_uso_diario
        WHERE usuario_id = NEW.usuario_id AND fecha = fecha_sesion;
        
        IF registro_id IS NULL THEN
            INSERT INTO public.registros_uso_diario (
                usuario_id, fecha, tiempo_usado_minutos, limite_del_dia_minutos, numero_sesiones
            )
            SELECT 
                NEW.usuario_id, fecha_sesion, COALESCE(NEW.duracion_minutos, 0),
                COALESCE((SELECT limite_diario_minutos FROM public.limites_uso WHERE usuario_id = NEW.usuario_id), 60),
                1
            RETURNING id INTO registro_id;
        ELSE
            UPDATE public.registros_uso_diario
            SET 
                tiempo_usado_minutos = tiempo_usado_minutos + COALESCE(NEW.duracion_minutos, 0),
                numero_sesiones = numero_sesiones + 1,
                updated_at = NOW()
            WHERE id = registro_id;
        END IF;
        
        NEW.registro_diario_id = registro_id;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers
CREATE TRIGGER update_limites_uso_updated_at 
    BEFORE UPDATE ON public.limites_uso 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_registros_uso_diario_updated_at 
    BEFORE UPDATE ON public.registros_uso_diario 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_sesiones_uso_updated_at 
    BEFORE UPDATE ON public.sesiones_uso 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER calcular_duracion_sesion_trigger
    BEFORE UPDATE ON public.sesiones_uso
    FOR EACH ROW
    WHEN (NEW.fin_sesion IS NOT NULL AND (OLD.fin_sesion IS NULL OR NEW.fin_sesion != OLD.fin_sesion))
    EXECUTE FUNCTION calcular_duracion_sesion();

CREATE TRIGGER actualizar_registro_diario_trigger
    AFTER UPDATE ON public.sesiones_uso
    FOR EACH ROW
    WHEN (NEW.estado = 'finalizada' AND OLD.estado != 'finalizada')
    EXECUTE FUNCTION actualizar_registro_diario();

-- Habilitar RLS
ALTER TABLE public.limites_uso ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.registros_uso_diario ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sesiones_uso ENABLE ROW LEVEL SECURITY;

-- Políticas RLS para limites_uso
CREATE POLICY "Usuarios pueden ver sus propios límites"
    ON public.limites_uso FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden insertar sus propios límites"
    ON public.limites_uso FOR INSERT WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden actualizar sus propios límites"
    ON public.limites_uso FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden eliminar sus propios límites"
    ON public.limites_uso FOR DELETE USING (auth.uid() = usuario_id);

-- Políticas RLS para registros_uso_diario
CREATE POLICY "Usuarios pueden ver sus propios registros diarios"
    ON public.registros_uso_diario FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden insertar sus propios registros diarios"
    ON public.registros_uso_diario FOR INSERT WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden actualizar sus propios registros diarios"
    ON public.registros_uso_diario FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);

-- Políticas RLS para sesiones_uso
CREATE POLICY "Usuarios pueden ver sus propias sesiones"
    ON public.sesiones_uso FOR SELECT USING (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden insertar sus propias sesiones"
    ON public.sesiones_uso FOR INSERT WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden actualizar sus propias sesiones"
    ON public.sesiones_uso FOR UPDATE USING (auth.uid() = usuario_id) WITH CHECK (auth.uid() = usuario_id);
CREATE POLICY "Usuarios pueden eliminar sus propias sesiones"
    ON public.sesiones_uso FOR DELETE USING (auth.uid() = usuario_id);

-- Funciones RPC
CREATE OR REPLACE FUNCTION obtener_o_crear_limites_uso(p_usuario_id UUID)
RETURNS public.limites_uso AS $$
DECLARE
    v_limites public.limites_uso;
BEGIN
    SELECT * INTO v_limites FROM public.limites_uso WHERE usuario_id = p_usuario_id;
    
    IF v_limites IS NULL THEN
        INSERT INTO public.limites_uso (
            usuario_id, limite_diario_minutos, bloqueo_nocturno_activo,
            bloqueo_nocturno_inicio, bloqueo_nocturno_fin, pausas_obligatorias_activas,
            intervalo_pausa_minutos, duracion_pausa_minutos, meta_semanal_horas,
            notificaciones_activas, intervalo_notificacion_minutos
        )
        VALUES (p_usuario_id, 60, false, '22:00:00', '07:00:00', false, 30, 5, 10, true, 15)
        RETURNING * INTO v_limites;
    END IF;
    
    RETURN v_limites;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION obtener_registro_dia_actual(p_usuario_id UUID)
RETURNS public.registros_uso_diario AS $$
DECLARE
    v_registro public.registros_uso_diario;
    v_limite_diario INTEGER;
BEGIN
    SELECT limite_diario_minutos INTO v_limite_diario
    FROM public.limites_uso WHERE usuario_id = p_usuario_id;
    
    IF v_limite_diario IS NULL THEN
        v_limite_diario := 60;
    END IF;
    
    SELECT * INTO v_registro
    FROM public.registros_uso_diario
    WHERE usuario_id = p_usuario_id AND fecha = CURRENT_DATE;
    
    IF v_registro IS NULL THEN
        INSERT INTO public.registros_uso_diario (
            usuario_id, fecha, tiempo_usado_minutos, limite_del_dia_minutos, numero_sesiones
        )
        VALUES (p_usuario_id, CURRENT_DATE, 0, v_limite_diario, 0)
        RETURNING * INTO v_registro;
    END IF;
    
    RETURN v_registro;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION iniciar_sesion_uso(p_usuario_id UUID)
RETURNS INTEGER AS $$
DECLARE
    v_sesion_id INTEGER;
BEGIN
    INSERT INTO public.sesiones_uso (usuario_id, inicio_sesion, estado)
    VALUES (p_usuario_id, NOW(), 'activa')
    RETURNING id INTO v_sesion_id;
    
    RETURN v_sesion_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION finalizar_sesion_uso(p_sesion_id INTEGER)
RETURNS public.sesiones_uso AS $$
DECLARE
    v_sesion public.sesiones_uso;
BEGIN
    UPDATE public.sesiones_uso
    SET fin_sesion = NOW(), estado = 'finalizada', updated_at = NOW()
    WHERE id = p_sesion_id AND estado = 'activa'
    RETURNING * INTO v_sesion;
    
    RETURN v_sesion;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 📝 Notas Importantes

1. **auth_user_id**: Se llena automáticamente al registrar usuarios. Relaciona la tabla `usuarios` con `auth.users` de Supabase.

2. **user_id** (en emociones): Debe ser el UUID del usuario autenticado en Supabase Auth.

3. **RLS**: Las políticas de seguridad están habilitadas para proteger los datos de los usuarios.

4. **Triggers**: Los campos `updated_at` se actualizan automáticamente al modificar registros.

5. **Puntos iniciales**: Los usuarios nuevos no tienen puntos automáticamente. Se crea el registro en `puntos_usuario` cuando se registran o cuando obtienen su primer punto.

6. **Recompensas por defecto**: Las recompensas con `is_default = true` se desbloquean automáticamente al crear el usuario.

7. **Idiomas**: El sistema soporta español e inglés. Usa `name_es`/`description_es` para español y `name_en`/`description_en` para inglés.

---

## 🔗 Enlaces Útiles

- **Dashboard**: https://app.supabase.com
- **Proyecto**: NoFaceZone_
- **SQL Editor**: Disponible en el Dashboard de Supabase

