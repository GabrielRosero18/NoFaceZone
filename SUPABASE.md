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

