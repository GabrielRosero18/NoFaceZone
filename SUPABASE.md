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

### Tabla: `usuarios`

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
| `created_at` | TIMESTAMP | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Fecha de última actualización | DEFAULT NOW() |

#### Índices
- `idx_usuarios_email` - Índice en `email`
- `idx_usuarios_auth_user_id` - Índice en `auth_user_id`

---

### Tabla: `emociones`

Almacena las emociones registradas por los usuarios.

#### Estructura

| Columna | Tipo | Descripción | Restricciones |
|---------|------|-------------|---------------|
| `id` | SERIAL | ID único de la emoción (auto-increment) | PRIMARY KEY |
| `emotion` | VARCHAR(50) | Tipo de emoción | NOT NULL, CHECK (emotion IN ('feliz', 'triste', 'neutro', 'ansioso', 'enojado')) |
| `comment` | TEXT | Comentario opcional sobre la emoción | Opcional |
| `user_id` | UUID | ID del usuario de Supabase Auth | NOT NULL |
| `created_at` | TIMESTAMP | Fecha de creación | DEFAULT NOW() |
| `updated_at` | TIMESTAMP | Fecha de última actualización | DEFAULT NOW() |

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

---

## 📝 Notas Importantes

- **auth_user_id**: Se llena automáticamente al registrar usuarios. Relaciona la tabla `usuarios` con `auth.users` de Supabase.
- **user_id** (en emociones): Debe ser el UUID del usuario autenticado en Supabase Auth.
- **RLS**: Las políticas de seguridad están habilitadas para proteger los datos de los usuarios.
- **Triggers**: Los campos `updated_at` se actualizan automáticamente al modificar registros.

---

## 🔗 Enlaces Útiles

- **Dashboard**: https://app.supabase.com
- **Proyecto**: NoFaceZone_
- **SQL Editor**: Disponible en el Dashboard de Supabase

