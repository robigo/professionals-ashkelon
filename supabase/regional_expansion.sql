-- הרחבה לאזורים וערים. להריץ פעם אחת ב-Supabase SQL Editor.

create table if not exists public.service_areas (
  id uuid primary key default gen_random_uuid(),
  region text not null,
  city text not null unique,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.service_areas (region, city) values
  ('דרום', 'אשקלון'), ('דרום', 'אשדוד'), ('דרום', 'באר שבע'),
  ('מרכז', 'תל אביב-יפו'), ('מרכז', 'ראשון לציון'), ('מרכז', 'פתח תקווה'),
  ('צפון', 'חיפה'), ('צפון', 'הקריות'), ('צפון', 'נהריה')
on conflict (city) do nothing;

alter table public.professionals add column if not exists region text;
alter table public.professionals add column if not exists city text;
alter table public.service_requests add column if not exists region text;
alter table public.service_requests add column if not exists city text;

-- כל הנתונים הקיימים שייכים לאשקלון, כדי שלא ייעלמו לאחר המעבר.
update public.professionals set region = 'דרום', city = 'אשקלון'
where region is null or city is null;
update public.service_requests set region = 'דרום', city = 'אשקלון'
where region is null or city is null;

alter table public.professionals alter column region set not null;
alter table public.professionals alter column city set not null;
alter table public.service_requests alter column region set not null;
alter table public.service_requests alter column city set not null;

create index if not exists professionals_city_active_idx
on public.professionals (city, is_active, is_verified);
create index if not exists service_requests_city_created_idx
on public.service_requests (city, created_at desc);

alter table public.service_areas enable row level security;

drop policy if exists "Public can view active service areas" on public.service_areas;
create policy "Public can view active service areas"
on public.service_areas for select to anon, authenticated
using (is_active = true);

drop policy if exists "Administrators can manage service areas" on public.service_areas;
create policy "Administrators can manage service areas"
on public.service_areas for all to authenticated
using (public.is_admin()) with check (public.is_admin());

grant select on public.service_areas to anon, authenticated;
grant insert, update, delete on public.service_areas to authenticated;
