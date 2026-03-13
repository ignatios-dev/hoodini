-- Players table (synced from Supabase Auth)
create table public.players (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (length(nickname) >= 2 and length(nickname) <= 24),
  email text,
  created_at timestamptz default now() not null
);

-- Lobbies
create table public.lobbies (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(name) >= 1),
  visibility text not null default 'public' check (visibility in ('public', 'private')),
  created_by uuid not null references public.players(id),
  created_at timestamptz default now() not null
);

-- Lobby members
create table public.lobby_members (
  lobby_id uuid not null references public.lobbies(id) on delete cascade,
  user_id uuid not null references public.players(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz default now() not null,
  primary key (lobby_id, user_id)
);

-- Markers
create table public.markers (
  id uuid primary key default gen_random_uuid(),
  lobby_id uuid not null references public.lobbies(id) on delete cascade,
  created_by uuid not null references public.players(id),
  creator_nickname text not null,
  type text not null check (type in ('note', 'photo', 'ctaFlag')),
  lat double precision not null,
  lng double precision not null,
  text text not null check (length(text) >= 1),
  image_url text,
  visibility text not null default 'instant' check (visibility in ('instant', 'proximityUnlock')),
  unlock_radius_meters int not null default 50,
  expires_at timestamptz,
  created_at timestamptz default now() not null
);

-- Enable RLS on all tables
alter table public.players enable row level security;
alter table public.lobbies enable row level security;
alter table public.lobby_members enable row level security;
alter table public.markers enable row level security;

-- RLS Policies: Players
create policy "Players can read all players" on public.players
  for select using (true);

create policy "Players can insert own record" on public.players
  for insert with check (auth.uid() = id);

create policy "Players can update own record" on public.players
  for update using (auth.uid() = id);

-- RLS Policies: Lobbies
create policy "Anyone can read public lobbies" on public.lobbies
  for select using (visibility = 'public' or created_by = auth.uid());

create policy "Authenticated users can create lobbies" on public.lobbies
  for insert with check (auth.uid() = created_by);

-- RLS Policies: Lobby Members
create policy "Members can read lobby membership" on public.lobby_members
  for select using (
    exists (
      select 1 from public.lobby_members lm
      where lm.lobby_id = lobby_members.lobby_id and lm.user_id = auth.uid()
    )
  );

create policy "Users can join lobbies" on public.lobby_members
  for insert with check (auth.uid() = user_id);

create policy "Users can leave lobbies" on public.lobby_members
  for delete using (auth.uid() = user_id);

-- RLS Policies: Markers
create policy "Lobby members can read markers" on public.markers
  for select using (
    exists (
      select 1 from public.lobby_members lm
      where lm.lobby_id = markers.lobby_id and lm.user_id = auth.uid()
    )
  );

create policy "Lobby members can create markers" on public.markers
  for insert with check (
    auth.uid() = created_by and
    exists (
      select 1 from public.lobby_members lm
      where lm.lobby_id = markers.lobby_id and lm.user_id = auth.uid()
    )
  );

create policy "Owners can delete own markers" on public.markers
  for delete using (auth.uid() = created_by);

-- Enable Realtime for markers and lobby_members
alter publication supabase_realtime add table public.markers;
alter publication supabase_realtime add table public.lobby_members;

-- Index for geo queries
create index markers_lobby_id_idx on public.markers(lobby_id);
create index markers_created_at_idx on public.markers(created_at desc);
create index lobby_members_user_id_idx on public.lobby_members(user_id);
