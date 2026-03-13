# Hoodini – Moderation & Admin Access

## Status
> **OPEN TODO** – Moderation is not yet implemented. The community lobby is currently fully public and unmoderated.

---

## Community Lobby

**ID:** `00000000-0000-0000-0000-000000000001`
**Name:** 🚨 Rechtsextreme Symbole melden
**Purpose:** Users report right-wing extremist graffiti, stickers, and symbols in their area.

This lobby is globally visible (geo-filter bypassed), seeded via SQL migration, and cannot be deleted or renamed through the app.

---

## Admin Requirements (to be built)

### 1. Admin Role
- Add `role` column to `players` table: `'user' | 'moderator' | 'admin'`
- Admin assignment via Supabase Dashboard (manual SQL update for now)
- Row-level security: moderators can delete any marker in the community lobby

### 2. Moderation Dashboard
- Dedicated admin view (web-only is fine initially)
- Shows all markers in the community lobby sorted by newest
- Actions per marker: **Approve** (keep), **Remove** (delete), **Flag as duplicate**
- Optional: email notification to submitter on removal

### 3. Report/Flag Feature (user-facing)
- "Flag this marker" option in marker detail sheet
- Writes to a `reports` table: `marker_id`, `reported_by`, `reason`, `created_at`
- Moderator sees report count badge on flagged markers

### 4. Rate Limiting
- Max N markers per user per day in community lobby (e.g. 10)
- Enforce via Supabase Edge Function or RLS check

### 5. Access Control
- Admin login: reuse existing anonymous auth, but require a separate **admin password** (stored as env secret, checked in Edge Function)
- OR: use Supabase Studio directly until a proper UI is built

---

## Supabase RLS Changes Needed (when implementing)

```sql
-- Allow moderators to delete any marker in the community lobby
create policy "Moderators can delete community markers"
  on public.markers for delete
  using (
    markers.lobby_id = '00000000-0000-0000-0000-000000000001'
    and exists (
      select 1 from public.players
      where id = auth.uid() and role in ('moderator', 'admin')
    )
  );
```

---

## Notes
- Until moderation is live, the community lobby should be considered **beta/experimental**
- Consider adding a disclaimer in the onboarding slide that content is user-generated
- Geo-coordinates in markers make this legally sensitive – review GDPR implications before public launch
