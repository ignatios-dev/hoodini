-- Fix: infinite recursion in lobby_members RLS policy
-- The old policy queried lobby_members FROM WITHIN a lobby_members policy → recursion

drop policy if exists "Members can read lobby membership" on public.lobby_members;

-- Simple non-recursive policy: any authenticated user can read memberships
create policy "Authenticated users can read lobby membership" on public.lobby_members
  for select using (auth.uid() is not null);
