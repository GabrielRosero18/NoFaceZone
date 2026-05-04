-- Catálogo de estilos de reloj para el diálogo de tiempo restante.
-- Pro queda como default; los demás se desbloquean con puntos.

insert into public.recompensas (
  id, tipo_recompensa_id, name, name_es, name_en, description, description_es, description_en,
  price, icon_name, is_default, is_active, display_order, metadata
)
values
  (
    'clock_pro', 'clock_style',
    'Pro', 'Pro', 'Pro',
    'Balanced premium dial', 'Reloj premium equilibrado', 'Balanced premium dial',
    0, 'watch_later', true, true, 200,
    '{"style_id":"pro","accent":"#4F8CFF"}'::jsonb
  ),
  (
    'clock_classic', 'clock_style',
    'Classic', 'Clásico', 'Classic',
    'Minimal clean style', 'Estilo minimal y limpio', 'Minimal clean style',
    180, 'watch_later', false, true, 210,
    '{"style_id":"classic","accent":"#8FA3B8"}'::jsonb
  ),
  (
    'clock_neon', 'clock_style',
    'Neon', 'Neón', 'Neon',
    'Electric pulse style', 'Estilo eléctrico vibrante', 'Electric pulse style',
    260, 'watch_later', false, true, 220,
    '{"style_id":"neon","accent":"#7A5CFF"}'::jsonb
  ),
  (
    'clock_aurora', 'clock_style',
    'Aurora', 'Aurora', 'Aurora',
    'Calm organic glow', 'Brillo orgánico y suave', 'Calm organic glow',
    320, 'watch_later', false, true, 230,
    '{"style_id":"aurora","accent":"#2BD6B4"}'::jsonb
  ),
  (
    'clock_quantum', 'clock_style',
    'Quantum', 'Quantum', 'Quantum',
    'High-tech energetic style', 'Estilo futurista de alta energía', 'High-tech energetic style',
    420, 'watch_later', false, true, 240,
    '{"style_id":"quantum","accent":"#1DEBFF"}'::jsonb
  )
on conflict (id) do update
set
  tipo_recompensa_id = excluded.tipo_recompensa_id,
  name = excluded.name,
  name_es = excluded.name_es,
  name_en = excluded.name_en,
  description = excluded.description,
  description_es = excluded.description_es,
  description_en = excluded.description_en,
  price = excluded.price,
  icon_name = excluded.icon_name,
  is_default = excluded.is_default,
  is_active = excluded.is_active,
  display_order = excluded.display_order,
  metadata = excluded.metadata,
  updated_at = timezone('utc', now());
