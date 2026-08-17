-- טופס הצטרפות ציבורי לבעלי מקצוע. להריץ פעם אחת ב-Supabase SQL Editor.
create table if not exists public.professional_applications (
  id uuid primary key default gen_random_uuid(),
  full_name text not null check (char_length(full_name) between 2 and 100),
  phone text not null check (phone ~ '^[0-9+() -]{8,20}$'),
  service text not null,
  region text not null,
  city text not null,
  experience text not null check (char_length(experience) between 10 and 1000),
  status text not null default 'ממתין לאישור' check (status in ('ממתין לאישור','אושר','נדחה')),
  created_at timestamptz not null default now()
);

alter table public.professional_applications enable row level security;
create policy "Public can submit professional applications"
on public.professional_applications for insert to anon, authenticated with check (true);
create policy "Administrators can manage professional applications"
on public.professional_applications for all to authenticated
using (public.is_admin()) with check (public.is_admin());
grant insert on public.professional_applications to anon, authenticated;
grant select, update, delete on public.professional_applications to authenticated;
