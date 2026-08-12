-- הרץ פעם אחת ב-Supabase SQL Editor כדי לאפשר ניהול מאובטח מתוך האפליקציה.

alter table public.professionals add column if not exists phone text;
alter table public.professionals add column if not exists bio text;

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$ select exists (select 1 from public.admin_users where user_id = auth.uid()) $$;

drop policy if exists "Administrators can view their own admin role" on public.admin_users;
create policy "Administrators can view their own admin role"
on public.admin_users for select to authenticated
using (user_id = auth.uid());

drop policy if exists "Administrators can add professionals" on public.professionals;
create policy "Administrators can add professionals"
on public.professionals for insert to authenticated
with check (public.is_admin());

grant usage on schema public to authenticated;
grant select on public.admin_users to authenticated;
grant insert on public.professionals to authenticated;
grant execute on function public.is_admin() to authenticated;
