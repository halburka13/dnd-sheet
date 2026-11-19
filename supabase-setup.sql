-- Full schema for the D&D sheet app (already applied to the project; kept for reference / new projects).
-- v1 table (legacy single sheet)
create table if not exists public.character_sheets (
  user_id uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  data jsonb not null, rev integer not null default 1, updated_at timestamptz not null default now());
alter table public.character_sheets enable row level security;

-- v2
create table if not exists public.characters (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null default '', archived boolean not null default false,
  data jsonb not null, rev integer not null default 1, updated_at timestamptz not null default now());
create index if not exists characters_owner_idx on public.characters(owner);
alter table public.characters enable row level security;
create policy "owner reads characters"   on public.characters for select to authenticated using ((select auth.uid()) = owner);
create policy "owner adds characters"    on public.characters for insert to authenticated with check ((select auth.uid()) = owner);
create policy "owner changes characters" on public.characters for update to authenticated using ((select auth.uid()) = owner) with check ((select auth.uid()) = owner);
grant select, insert, update on public.characters to authenticated;

create table if not exists public.towns (
  id uuid primary key default gen_random_uuid(),
  owner uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name text not null default '', data jsonb not null, rev integer not null default 1, updated_at timestamptz not null default now());
create index if not exists towns_owner_idx on public.towns(owner);
create table if not exists public.town_members (
  town_id uuid not null references public.towns(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('editor','viewer')),
  added_at timestamptz not null default now(), primary key (town_id, user_id));
create index if not exists town_members_user_idx on public.town_members(user_id);

create schema if not exists private;
create or replace function private.town_access(t uuid) returns text
language sql stable security definer set search_path = '' as $$
  select case when exists (select 1 from public.towns where id = t and owner = (select auth.uid())) then 'owner'
    else (select role from public.town_members where town_id = t and user_id = (select auth.uid())) end $$;
revoke all on function private.town_access(uuid) from public, anon;
grant usage on schema private to authenticated;
grant execute on function private.town_access(uuid) to authenticated;

alter table public.towns enable row level security;
create policy "members read towns"   on public.towns for select to authenticated using (private.town_access(id) is not null);
create policy "owner adds towns"     on public.towns for insert to authenticated with check ((select auth.uid()) = owner);
create policy "editors change towns" on public.towns for update to authenticated using (private.town_access(id) in ('owner','editor')) with check (private.town_access(id) in ('owner','editor'));
grant select, insert, update on public.towns to authenticated;

alter table public.town_members enable row level security;
create policy "see own or owned memberships" on public.town_members for select to authenticated using (user_id = (select auth.uid()) or private.town_access(town_id) = 'owner');
create policy "owner adds members"           on public.town_members for insert to authenticated with check (private.town_access(town_id) = 'owner' and user_id <> (select auth.uid()));
create policy "owner removes, member leaves" on public.town_members for delete to authenticated using (private.town_access(town_id) = 'owner' or user_id = (select auth.uid()));
grant select, insert, delete on public.town_members to authenticated;

create or replace function public.touch_row() returns trigger language plpgsql set search_path = '' as $$
begin new.updated_at = now(); if tg_op = 'UPDATE' then new.owner = old.owner; end if; return new; end $$;
create trigger characters_touch before update on public.characters for each row execute function public.touch_row();
create trigger towns_touch      before update on public.towns      for each row execute function public.touch_row();
