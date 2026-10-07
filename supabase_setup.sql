-- =====================================================================
--  PLASMA 2K26  |  COMPLETE DATABASE SETUP  (single file)
--  Paste this whole file into Supabase > SQL Editor > New query > Run.
--  It is safe to run again at any time (it never deletes your data).
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. TABLES
-- ---------------------------------------------------------------------
create table if not exists public.events (
  id                 bigint generated always as identity primary key,
  name               text not null,
  track              text not null default 'General',
  description        text,
  event_date         date,
  start_time         time,
  end_time           time,
  venue              text,
  team_size          text default '1-4',
  fee                numeric default 0,
  prize              text,
  coordinator_name   text,
  coordinator_phone  text,
  rulebook_url       text,
  reg_open           boolean default true,
  is_published       boolean default true
);

create table if not exists public.registrations (
  id            bigint generated always as identity primary key,
  event_id      bigint not null references public.events(id) on delete cascade,
  name          text not null,
  email         text not null,
  phone         text,
  college       text,
  team_members                 text,
  payment_ref                  text,
  accommodation_required      boolean,
  accommodation_member_count  integer,
  accommodation_amount        numeric(10,2),
  accommodation_utr            text,
  created_at                   timestamptz default now()
);

create table if not exists public.admins (
  email text primary key
);


-- ---------------------------------------------------------------------
-- 2. UPGRADE OLDER VERSIONS (adds anything that is missing)
--    A missing column is the usual cause of "Save failed (400)".
-- ---------------------------------------------------------------------
alter table public.events add column if not exists description       text;
alter table public.events add column if not exists event_date        date;
alter table public.events add column if not exists start_time        time;
alter table public.events add column if not exists end_time          time;
alter table public.events add column if not exists venue             text;
alter table public.events add column if not exists team_size         text default '1-4';
alter table public.events add column if not exists fee               numeric default 0;
alter table public.events add column if not exists prize             text;
alter table public.events add column if not exists coordinator_name  text;
alter table public.events add column if not exists coordinator_phone text;
alter table public.events add column if not exists rulebook_url      text;
alter table public.events add column if not exists reg_open          boolean default true;
alter table public.events add column if not exists is_published      boolean default true;

alter table public.events alter column event_date drop not null;
alter table public.events alter column start_time drop not null;
alter table public.events alter column track set default 'General';

alter table public.registrations add column if not exists phone        text;
alter table public.registrations add column if not exists college      text;
alter table public.registrations add column if not exists team_members text;
alter table public.registrations add column if not exists payment_ref  text;
alter table public.registrations add column if not exists created_at   timestamptz default now();
alter table public.registrations add column if not exists accommodation_required      boolean;
alter table public.registrations add column if not exists accommodation_member_count  integer;
alter table public.registrations add column if not exists accommodation_amount        numeric(10,2);
alter table public.registrations add column if not exists accommodation_utr           text;

-- Accommodation data consistency:
-- If accommodation is not required, clear any accidental payment details.
update public.registrations
set accommodation_member_count = null,
    accommodation_amount = null,
    accommodation_utr = null
where accommodation_required is not true;

-- If accommodation is required and an amount is missing, calculate it at ₹150 per member.
update public.registrations
set accommodation_amount = accommodation_member_count * 150
where accommodation_required is true
  and accommodation_member_count is not null
  and accommodation_amount is null;

-- Keep accommodation amounts consistent with the ₹150/member rule.
alter table public.registrations
drop constraint if exists registrations_accommodation_amount_check;

alter table public.registrations
add constraint registrations_accommodation_amount_check
check (
  accommodation_required is not true
  or (
    accommodation_member_count is not null
    and accommodation_member_count > 0
    and accommodation_amount = accommodation_member_count * 150
  )
);

-- deleting an event also removes its registrations
alter table public.registrations drop constraint if exists registrations_event_id_fkey;
alter table public.registrations
  add constraint registrations_event_id_fkey
  foreign key (event_id) references public.events(id) on delete cascade;

-- one registration per email per event (case-insensitive)
create unique index if not exists registrations_event_email_uq
  on public.registrations (event_id, lower(email));

update public.events set is_published = true where is_published is null;
update public.events set reg_open     = true where reg_open     is null;


-- ---------------------------------------------------------------------
-- 3. SECURITY  (who can read / write what)
-- ---------------------------------------------------------------------
-- Helper: is the logged-in user listed in the admins table?
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

alter table public.events        enable row level security;
alter table public.registrations enable row level security;
alter table public.admins        enable row level security;

-- remove every older policy name so this file always leaves a clean state
drop policy if exists "public read events"          on public.events;
drop policy if exists "admin manages events"        on public.events;
drop policy if exists "public can register"         on public.registrations;
drop policy if exists "admin reads registrations"   on public.registrations;
drop policy if exists "admin deletes registrations" on public.registrations;
drop policy if exists "admin reads self"            on public.admins;

-- Visitors: see published events, and submit a registration. Nothing else.
create policy "public read events" on public.events
  for select to anon, authenticated
  using (is_published = true);

create policy "public can register" on public.registrations
  for insert to anon, authenticated
  with check (true);

-- Admins: full control of events, read + delete registrations.
create policy "admin manages events" on public.events
  for all to authenticated
  using (public.is_admin())
  with check (public.is_admin());

create policy "admin reads registrations" on public.registrations
  for select to authenticated
  using (public.is_admin());

create policy "admin deletes registrations" on public.registrations
  for delete to authenticated
  using (public.is_admin());

create policy "admin reads self" on public.admins
  for select to authenticated
  using (lower(email) = lower(coalesce(auth.jwt() ->> 'email', '')));

-- table permissions (row rules above still apply on top of these)
grant usage  on schema public to anon, authenticated;
grant select on public.events        to anon;
grant all    on public.events        to authenticated;
grant insert on public.registrations to anon;
grant select, insert, delete on public.registrations to authenticated;
grant select on public.admins        to authenticated;


-- ---------------------------------------------------------------------
-- 4. YOUR EVENTS  (2026 lineup: 7 events, fest dates 27 & 28 Oct 2026)
--    Fee is in rupees. Date / venue / prize stay empty = "to be announced".
--    Fill them in later from the Admin panel.
--
--    If you already ran an OLDER version of this file, the two lines
--    below first migrate your existing data so nothing is lost:
--      - "Hardware Hackathon" is renamed in place (keeps its id and any
--        registrations) rather than being deleted and re-added.
--      - "RC Car Race" and "Paper Presentation" are no longer in this
--        year's lineup, so they are hidden (is_published = false)
--        rather than deleted, in case anyone already registered.
--        Delete them yourself once you've confirmed that's fine:
--          delete from public.events where name in ('RC Car Race','Paper Presentation');
-- ---------------------------------------------------------------------
update public.events set name = 'H/W Hackathon + PCB Design'
where name = 'Hardware Hackathon';

update public.events set is_published = false
where name in ('RC Car Race', 'Paper Presentation');

insert into public.events (name, track, description, team_size, fee, rulebook_url)
select v.name, v.track, v.description, v.team_size, v.fee, v.rulebook_url
from (values
  ('Robo Race',                 'Robotics',       'Navigate your bot through the obstacle track.',                 '2-4', 200, 'rulebooks/robo-race.pdf'),
  ('Sumo War',                  'Robotics',       'Push your opponent''s bot out of the ring.',                    '1-3', 200, 'rulebooks/sumo-war.pdf'),
  ('Line Follower',             'Robotics',       'Build a bot that follows the line fastest.',                    '1-3', 200, 'rulebooks/line-follower.pdf'),
  ('Robo Tug of War',           'Robotics',       'Remote-controlled bots pull head-to-head across the line.',     '1-3', 200, 'rulebooks/robo-tug-of-war.pdf'),
  ('H/W Hackathon + PCB Design','Code & Compute',  'Build a working hardware prototype and design its PCB against the clock.', '2-4', 400, 'rulebooks/hardware-hackathon.pdf'),
  ('Robo Climbing',             'Robotics',       'Climb a vertical or inclined track as high and fast as you can.', '1-3', 200, 'rulebooks/robo-climbing.pdf'),
  ('Robo Soccer',               'Robotics',       'Bot-vs-bot soccer knockout matches.',                           '2-4', 200, 'rulebooks/robo-soccer.pdf')
) as v(name, track, description, team_size, fee, rulebook_url)
where not exists (select 1 from public.events e where e.name = v.name);

-- make sure rulebook links exist on every event above, even one added earlier without one
update public.events e set rulebook_url = 'rulebooks/' || x.slug || '.pdf'
from (values
  ('Robo Race','robo-race'), ('Line Follower','line-follower'), ('Robo Soccer','robo-soccer'),
  ('Sumo War','sumo-war'), ('Robo Tug of War','robo-tug-of-war'), ('Robo Climbing','robo-climbing'),
  ('H/W Hackathon + PCB Design','hardware-hackathon')
) as x(name, slug)
where e.name = x.name and (e.rulebook_url is null or e.rulebook_url = '');


-- ---------------------------------------------------------------------
-- 5. COORDINATOR / ADMIN ACCESS
--    EDIT the emails below: use the exact emails you create in
--    Supabase > Authentication > Users. Add one line per coordinator.
--    (Anything ending in @example.com is ignored, so running this file
--    without editing is harmless.)
--    To remove someone later:  delete from public.admins where email = '...';
-- ---------------------------------------------------------------------
insert into public.admins (email)
select lower(t.e)
from (values
  ('head.coordinator@example.com'),
  ('coordinator2@example.com'),
  ('coordinator3@example.com')
) as t(e)
where t.e not like '%@example.com'
on conflict (email) do nothing;


-- ---------------------------------------------------------------------
-- 6. REFRESH THE API SO NEW COLUMNS ARE VISIBLE IMMEDIATELY
-- ---------------------------------------------------------------------
notify pgrst, 'reload schema';