-- Add XP to players
alter table public.players add column if not exists xp integer not null default 0;

-- Add creator_level to markers so other players see the right icon
alter table public.markers add column if not exists creator_level integer not null default 0;

-- Allow players to update their own XP
-- (already covered by players_update policy from migration 003)
