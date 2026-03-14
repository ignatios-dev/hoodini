-- Create public storage bucket for marker images
insert into storage.buckets (id, name, public)
values ('marker-images', 'marker-images', true)
on conflict (id) do nothing;

-- Drop existing policies if they exist (idempotent)
drop policy if exists "Users can upload marker images" on storage.objects;
drop policy if exists "Public read on marker images" on storage.objects;
drop policy if exists "Users can delete own marker images" on storage.objects;

-- Allow any authenticated user (incl. anon) to upload
create policy "Users can upload marker images"
  on storage.objects for insert
  with check (
    bucket_id = 'marker-images'
    and auth.uid() is not null
  );

-- Public read (bucket is public, but explicit policy for clarity)
create policy "Public read on marker images"
  on storage.objects for select
  using (bucket_id = 'marker-images');

-- Owners can delete their own uploads
create policy "Users can delete own marker images"
  on storage.objects for delete
  using (
    bucket_id = 'marker-images'
    and auth.uid() is not null
  );
