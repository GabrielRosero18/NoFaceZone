-- Rewards revamp: analytics + loadout + compat helpers
-- Safe to run multiple times.

create extension if not exists "pgcrypto";

create table if not exists public.reward_events (
  id uuid primary key default gen_random_uuid(),
  usuario_id uuid not null references auth.users(id) on delete cascade,
  recompensa_id text null,
  event_type text not null check (char_length(event_type) > 0),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_reward_events_usuario_created
  on public.reward_events (usuario_id, created_at desc);

create index if not exists idx_reward_events_type
  on public.reward_events (event_type);

create table if not exists public.reward_loadout (
  usuario_id uuid primary key references auth.users(id) on delete cascade,
  active_theme_id text null,
  active_font_id text null,
  active_message_collections text[] not null default array[]::text[],
  updated_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_reward_loadout_updated_at
  on public.reward_loadout (updated_at desc);

create or replace function public.set_reward_loadout_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists trg_reward_loadout_updated_at on public.reward_loadout;
create trigger trg_reward_loadout_updated_at
before update on public.reward_loadout
for each row execute function public.set_reward_loadout_updated_at();

alter table public.reward_events enable row level security;
alter table public.reward_loadout enable row level security;

drop policy if exists "reward_events_select_own" on public.reward_events;
create policy "reward_events_select_own"
on public.reward_events for select
to authenticated
using (auth.uid() = usuario_id);

drop policy if exists "reward_events_insert_own" on public.reward_events;
create policy "reward_events_insert_own"
on public.reward_events for insert
to authenticated
with check (auth.uid() = usuario_id);

drop policy if exists "reward_loadout_select_own" on public.reward_loadout;
create policy "reward_loadout_select_own"
on public.reward_loadout for select
to authenticated
using (auth.uid() = usuario_id);

drop policy if exists "reward_loadout_insert_own" on public.reward_loadout;
create policy "reward_loadout_insert_own"
on public.reward_loadout for insert
to authenticated
with check (auth.uid() = usuario_id);

drop policy if exists "reward_loadout_update_own" on public.reward_loadout;
create policy "reward_loadout_update_own"
on public.reward_loadout for update
to authenticated
using (auth.uid() = usuario_id)
with check (auth.uid() = usuario_id);

-- RPC: resumen de catálogo + inventario + puntos en una sola llamada.
create or replace function public.obtener_resumen_rewards_usuario(p_usuario_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  result jsonb;
begin
  if auth.uid() is null or auth.uid() <> p_usuario_id then
    raise exception 'No autorizado';
  end if;

  select jsonb_build_object(
    'puntos', coalesce(
      (select to_jsonb(pu) from public.puntos_usuario pu where pu.usuario_id = p_usuario_id),
      jsonb_build_object('puntos_totales', 0, 'puntos_actuales', 0, 'puntos_gastados', 0)
    ),
    'inventario', coalesce(
      (select jsonb_agg(to_jsonb(ru)) from public.recompensas_usuario ru where ru.usuario_id = p_usuario_id),
      '[]'::jsonb
    ),
    'catalogo', coalesce(
      (select jsonb_agg(to_jsonb(r) order by r.display_order) from public.recompensas r where r.is_active = true),
      '[]'::jsonb
    )
  ) into result;

  return result;
end;
$$;

grant execute on function public.obtener_resumen_rewards_usuario(uuid) to authenticated;
