-- Add description and geo fields to lobbies
alter table public.lobbies add column if not exists description text;
alter table public.lobbies add column if not exists center_lat double precision;
alter table public.lobbies add column if not exists center_lng double precision;
alter table public.lobbies add column if not exists radius_km integer not null default 30;

-- Allow system lobbies with no creator (community/seeded lobbies)
alter table public.lobbies alter column created_by drop not null;

-- Seed the community lobby (globally visible, no geo restriction)
insert into public.lobbies (id, name, description, visibility, created_by, center_lat, center_lng, radius_km)
values (
  '00000000-0000-0000-0000-000000000001',
  '🚨 Rechtsextreme Symbole melden',
  'Melde rechtsextreme Graffitis, Sticker und Symbole in deiner Umgebung. Gemeinsam dokumentieren wir – für eine offene Gesellschaft.',
  'public',
  null,
  null,
  null,
  999999
) on conflict (id) do nothing;
