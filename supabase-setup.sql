-- Run this once in Supabase: SQL Editor > New query > paste > Run.
create table if not exists public.character_sheets (
  user_id    uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data       jsonb not null,
  rev        integer not null default 1,
  updated_at timestamptz not null default now()
);

alter table public.character_sheets enable row level security;

drop policy if exists "read own sheet"   on public.character_sheets;
drop policy if exists "add own sheet"    on public.character_sheets;
drop policy if exists "change own sheet" on public.character_sheets;

create policy "read own sheet"   on public.character_sheets for select to authenticated using ((select auth.uid()) = user_id);
create policy "add own sheet"    on public.character_sheets for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "change own sheet" on public.character_sheets for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);

grant select, insert, update on public.character_sheets to authenticated;

create or replace function public.touch_character_sheet() returns trigger
language plpgsql set search_path = '' as $$
begin new.updated_at = now(); return new; end $$;

drop trigger if exists character_sheets_touch on public.character_sheets;
create trigger character_sheets_touch before update on public.character_sheets
  for each row execute function public.touch_character_sheet();
