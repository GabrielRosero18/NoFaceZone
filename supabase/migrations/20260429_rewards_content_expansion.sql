-- Expansión de catálogo: más colores, fuentes y mensajes
-- Ejecutar después de 20260429_rewards_revamp.sql

insert into public.recompensas (
  id, tipo_recompensa_id, name, name_es, name_en, description, description_es, description_en,
  price, icon_name, is_default, is_active, display_order, metadata
)
values
  (
    'theme_aurora', 'theme',
    'Aurora', 'Aurora', 'Aurora',
    'Cool cyan gradient', 'Gradiente frío y luminoso', 'Cool luminous gradient',
    320, 'wb_twilight', false, true, 70,
    '{"colors":["#173445","#1E4A61","#45E0C5"]}'::jsonb
  ),
  (
    'theme_neon', 'theme',
    'Neon Pulse', 'Neon Pulse', 'Neon Pulse',
    'Electric purple and pink', 'Violeta eléctrico con rosa vibrante', 'Electric purple with vibrant pink',
    360, 'whatshot', false, true, 80,
    '{"colors":["#241743","#2F1F5B","#FF5FDB"]}'::jsonb
  ),
  (
    'theme_ember', 'theme',
    'Ember Glow', 'Brasa', 'Ember Glow',
    'Warm amber atmosphere', 'Ambiente cálido tipo brasa', 'Warm ember atmosphere',
    340, 'local_fire_department', false, true, 90,
    '{"colors":["#3A2218","#4D2E1F","#FF9259"]}'::jsonb
  ),
  (
    'font_inter', 'font',
    'Inter', 'Inter', 'Inter',
    'Clean UI font', 'Tipografía limpia para interfaz', 'Clean interface font',
    260, 'text_fields', false, true, 60,
    '{"fontFamily":"Inter"}'::jsonb
  ),
  (
    'font_nunito', 'font',
    'Nunito', 'Nunito', 'Nunito',
    'Rounded and friendly', 'Suave y amigable', 'Soft and friendly',
    260, 'text_fields', false, true, 70,
    '{"fontFamily":"Nunito"}'::jsonb
  ),
  (
    'font_manrope', 'font',
    'Manrope', 'Manrope', 'Manrope',
    'Modern readability', 'Lectura moderna y clara', 'Modern readability',
    280, 'text_fields', false, true, 80,
    '{"fontFamily":"Manrope"}'::jsonb
  ),
  (
    'font_space', 'font',
    'Space Grotesk', 'Space Grotesk', 'Space Grotesk',
    'Tech style and personality', 'Estilo tech con personalidad', 'Tech style and personality',
    300, 'text_fields', false, true, 90,
    '{"fontFamily":"Space Grotesk"}'::jsonb
  ),
  (
    'message_focus', 'message',
    'Deep Focus', 'Foco Profundo', 'Deep Focus',
    'Messages for concentration', 'Mensajes para concentración y claridad', 'Messages for concentration and clarity',
    210, 'speed', false, true, 50,
    '{"examples":["Lo importante primero","Menos ruido más progreso","Una sesión enfocada cambia tu día"]}'::jsonb
  ),
  (
    'message_discipline', 'message',
    'Discipline', 'Disciplina', 'Discipline',
    'Messages for consistency', 'Mensajes para constancia y compromiso', 'Messages for consistency and commitment',
    220, 'flag', false, true, 60,
    '{"examples":["Haz lo que dijiste","Progreso silencioso también cuenta","Busca continuidad"]}'::jsonb
  ),
  (
    'message_mindfulness', 'message',
    'Mindfulness', 'Mindfulness', 'Mindfulness',
    'Calm and present mindset', 'Mensajes de calma y presencia', 'Calm and present mindset',
    220, 'spa', false, true, 70,
    '{"examples":["Respira","Observa el impulso","Cada pausa consciente te devuelve poder"]}'::jsonb
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
