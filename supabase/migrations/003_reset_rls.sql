-- Drop ALL existing policies to ensure clean slate
do $$
declare
  pol record;
begin
  for pol in
    select policyname, tablename
    from pg_policies
    where schemaname = 'public'
      and tablename in ('players', 'lobbies', 'lobby_members', 'markers')
  loop
    execute format('drop policy if exists %I on public.%I', pol.policyname, pol.tablename);
  end loop;
end $$;

-- ─── players ───────────────────────────────────────────────────────────────
create policy "players_select" on public.players
  for select using (true);

create policy "players_insert" on public.players
  for insert with check (auth.uid() = id);

create policy "players_update" on public.players
  for update using (auth.uid() = id);

-- ─── lobbies ───────────────────────────────────────────────────────────────
create policy "lobbies_select" on public.lobbies
  for select using (true);

create policy "lobbies_insert" on public.lobbies
  for insert with check (auth.uid() = created_by);

-- ─── lobby_members ─────────────────────────────────────────────────────────
-- NO self-reference → no recursion
create policy "lobby_members_select" on public.lobby_members
  for select using (auth.uid() is not null);

create policy "lobby_members_insert" on public.lobby_members
  for insert with check (auth.uid() = user_id);

create policy "lobby_members_delete" on public.lobby_members
  for delete using (auth.uid() = user_id);

-- ─── markers ───────────────────────────────────────────────────────────────
create policy "markers_select" on public.markers
  for select using (
    exists (
      select 1 from public.lobby_members lm
      where lm.lobby_id = markers.lobby_id
        and lm.user_id = auth.uid()
    )
  );

create policy "markers_insert" on public.markers
  for insert with check (
    auth.uid() = created_by
    and exists (
      select 1 from public.lobby_members lm
      where lm.lobby_id = markers.lobby_id
        and lm.user_id = auth.uid()
    )
  );

create policy "markers_delete" on public.markers
  for delete using (auth.uid() = created_by);
