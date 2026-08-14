-- שדרוג מרקטפלייס: קטגוריות גמישות ומעקב אחר סגירת עבודה.
-- להריץ פעם אחת ב-Supabase SQL Editor.

create table if not exists public.service_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  icon text not null default '🛠️',
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

insert into public.service_categories (name, icon) values
  ('אינסטלטור', '🔧'), ('חשמלאי', '⚡'), ('מנעולן', '🔐'), ('טכנאי מזגנים', '❄️')
on conflict (name) do nothing;

-- מאפשר להוסיף כל מקצוע חדש במקום רשימה סגורה מראש.
alter table public.professionals drop constraint if exists professionals_service_check;
alter table public.service_requests drop constraint if exists service_requests_service_check;
alter table public.professionals add column if not exists icon text not null default '🛠️';
alter table public.professionals add column if not exists is_active boolean not null default true;

alter table public.service_requests add column if not exists professional_id uuid references public.professionals(id);
alter table public.service_requests add column if not exists customer_name text;
alter table public.service_requests add column if not exists customer_rating smallint check (customer_rating between 1 and 5);
alter table public.service_requests add column if not exists billing_status text not null default 'טרם נקבע';
alter table public.service_requests drop constraint if exists service_requests_billing_status_check;
alter table public.service_requests add constraint service_requests_billing_status_check
check (billing_status in ('טרם נקבע', 'חינם (ניסיון)', 'ממתין לתשלום בעל מקצוע', 'שולם', 'לא לחיוב'));
alter table public.service_requests add column if not exists quoted_price numeric(10,2);
alter table public.service_requests add column if not exists platform_fee numeric(10,2);
alter table public.service_requests add column if not exists customer_confirmed_at timestamptz;
alter table public.service_requests add column if not exists completed_at timestamptz;
-- ממיר סטטוסים ישנים לפני אכיפת רשימת הסטטוסים החדשה.
alter table public.service_requests drop constraint if exists service_requests_status_check;
update public.service_requests
set status = case status
  when 'ממתין להצעות' then 'חדש'
  when 'אושר' then 'הלקוח אישר'
  when 'הושלם' then 'בוצע'
  else status
end;
alter table public.service_requests add constraint service_requests_status_check
check (status in ('חדש', 'בטיפול', 'נשלח לבעל מקצוע', 'התקבלה הצעה', 'הלקוח אישר', 'בדרך', 'בוצע', 'אושר על ידי הלקוח', 'עמלה לתשלום', 'בוטל'));

alter table public.service_categories enable row level security;

drop policy if exists "Public can view active categories" on public.service_categories;
create policy "Public can view active categories"
on public.service_categories for select to anon, authenticated
using (is_active = true);

drop policy if exists "Administrators can manage categories" on public.service_categories;
create policy "Administrators can manage categories"
on public.service_categories for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Administrators can manage requests" on public.service_requests;
create policy "Administrators can manage requests"
on public.service_requests for all to authenticated
using (public.is_admin()) with check (public.is_admin());

drop policy if exists "Administrators can update professionals" on public.professionals;
create policy "Administrators can update professionals"
on public.professionals for update to authenticated
using (public.is_admin()) with check (public.is_admin());

grant select on public.service_categories to anon, authenticated;
grant insert, update, delete on public.service_categories to authenticated;
grant select, update on public.service_requests to authenticated;
grant update on public.professionals to authenticated;

-- שלבי עבודה מותרים לשימוש בממשק:
-- חדש → בטיפול → נשלח לבעל מקצוע → התקבלה הצעה → הלקוח אישר → בדרך → בוצע → אושר על ידי הלקוח → עמלה לתשלום
-- כלל חיוב: שלוש עבודות עם אישור לקוח ודירוג 4–5 הן תקופת ניסיון ללא תשלום.
