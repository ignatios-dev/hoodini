-- Add tags array to markers
alter table public.markers add column if not exists tags text[] not null default '{}';
