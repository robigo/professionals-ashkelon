-- מקצוענים אשקלון: הקמת מסד נתונים ראשוני
-- להריץ פעם אחת ב-Supabase Dashboard > SQL Editor > New query

create table if not exists public.professionals (
  id uuid primary key default gen_random_uuid(),
  full_name text not null,
  service text not null check (service in ('אינסטלטור', 'חשמלאי', 'מנעולן', 'טכנאי מזגנים')),
  phone text,
  bio text,
  rating numeric(2,1) not null default 5.0 check (rating >= 0 and rating <= 5),
  review_count integer not null default 0 check (review_count >= 0),
  is_verified boolean not null default false,
  is_available boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.service_requests (
  id uuid primary key default gen_random_uuid(),
  service text not null check (service in ('אינסטלטור', 'חשמלאי', 'מנעולן', 'טכנאי מזגנים')),
  description text not null,
  address text not null,
  phone text not null,
  urgency text not null check (urgency in ('עכשיו', 'היום', 'לתאם')),
  status text not null default 'ממתין להצעות' check (status in ('ממתין להצעות', 'התקבלה הצעה', 'אושר', 'הושלם', 'בוטל')),
  created_at timestamptz not null default now()
);

alter table public.professionals enable row level security;
alter table public.service_requests enable row level security;

-- רשימת מנהלי המערכת. הוספת מנהל מתבצעת רק מתוך SQL Editor.
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

-- כל מבקר יכול לראות רק פרטי פרופיל מאומתים של בעלי מקצוע.
create policy "Public can view verified professionals"
on public.professionals for select
to anon, authenticated
using (is_verified = true);

-- מבקר יכול לשלוח בקשה; אין לו גישה לקרוא בקשות של לקוחות אחרים.
create policy "Public can create service requests"
on public.service_requests for insert
to anon, authenticated
with check (true);

create policy "Administrators can view their own admin role"
on public.admin_users for select to authenticated
using (user_id = auth.uid());

create policy "Administrators can add professionals"
on public.professionals for insert to authenticated
with check (public.is_admin());

grant usage on schema public to anon, authenticated;
grant select on public.professionals to anon, authenticated;
grant insert on public.service_requests to anon, authenticated;

-- נתוני דוגמה ראשוניים. אפשר לערוך או למחוק מה-Table Editor.
insert into public.professionals (full_name, service, phone, bio, rating, review_count, is_verified, is_available)
values
  ('יוסי כהן', 'אינסטלטור', '050-0000001', 'אינסטלטור מקומי עם ניסיון בתקלות דחופות.', 4.9, 38, true, true),
  ('אלון לוי', 'חשמלאי', '050-0000002', 'חשמלאי מוסמך לשירותי בית ועסק.', 4.8, 24, true, true),
  ('דניאל אדרי', 'מנעולן', '050-0000003', 'שירות מהיר לכל סוגי המנעולים.', 5.0, 17, true, true),
  ('רועי פרץ', 'טכנאי מזגנים', '050-0000004', 'טיפול ותיקון מזגנים באשקלון.', 4.9, 31, true, true)
on conflict do nothing;
