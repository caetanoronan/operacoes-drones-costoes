-- Supabase/Postgres schema for app_campo_drones.html
-- Run this file in Supabase SQL Editor before using the Nuvem tab.

create table if not exists public.drone_campaigns (
  slug text primary key,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.drone_devices (
  id text primary key,
  campaign_slug text not null references public.drone_campaigns(slug) on delete cascade,
  label text,
  created_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now()
);

create table if not exists public.drone_missions (
  id text primary key,
  campaign_slug text not null references public.drone_campaigns(slug) on delete cascade,
  device_id text references public.drone_devices(id) on delete set null,
  mission_code text,
  mission_date date,
  location text,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  synced_at timestamptz not null default now()
);

create table if not exists public.drone_sync_events (
  id bigint generated always as identity primary key,
  campaign_slug text not null references public.drone_campaigns(slug) on delete cascade,
  device_id text references public.drone_devices(id) on delete set null,
  mission_count integer not null default 0,
  sync_status text not null,
  message text,
  created_at timestamptz not null default now()
);

create index if not exists drone_missions_campaign_idx
  on public.drone_missions(campaign_slug);

create index if not exists drone_missions_date_idx
  on public.drone_missions(mission_date);

alter table public.drone_campaigns enable row level security;
alter table public.drone_devices enable row level security;
alter table public.drone_missions enable row level security;
alter table public.drone_sync_events enable row level security;

drop policy if exists "anon can read drone campaigns" on public.drone_campaigns;
drop policy if exists "anon can write drone campaigns" on public.drone_campaigns;
drop policy if exists "anon can read drone devices" on public.drone_devices;
drop policy if exists "anon can write drone devices" on public.drone_devices;
drop policy if exists "anon can read drone missions" on public.drone_missions;
drop policy if exists "anon can write drone missions" on public.drone_missions;
drop policy if exists "anon can read drone sync events" on public.drone_sync_events;
drop policy if exists "anon can write drone sync events" on public.drone_sync_events;

create policy "anon can read drone campaigns"
  on public.drone_campaigns for select
  to anon
  using (true);

create policy "anon can write drone campaigns"
  on public.drone_campaigns for all
  to anon
  using (true)
  with check (true);

create policy "anon can read drone devices"
  on public.drone_devices for select
  to anon
  using (true);

create policy "anon can write drone devices"
  on public.drone_devices for all
  to anon
  using (true)
  with check (true);

create policy "anon can read drone missions"
  on public.drone_missions for select
  to anon
  using (true);

create policy "anon can write drone missions"
  on public.drone_missions for all
  to anon
  using (true)
  with check (true);

create policy "anon can read drone sync events"
  on public.drone_sync_events for select
  to anon
  using (true);

create policy "anon can write drone sync events"
  on public.drone_sync_events for insert
  to anon
  with check (true);

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'drone_missions'
  ) then
    alter publication supabase_realtime add table public.drone_missions;
  end if;
end $$;
