-- job radar — multi-user migration
-- Run AFTER the original schema, in Project → SQL Editor → New query → Run.
-- Adds real per-user isolation via Supabase Auth, while keeping job postings
-- and broken-link flags shared across everyone (that's the "smarter over
-- time" part — the postings pool grows collectively, everything personal
-- to a candidate stays private to them).

-- ============ add user_id to every private table ============
alter table scans add column user_id uuid references auth.users(id);
alter table job_scan_results add column user_id uuid references auth.users(id);
alter table plans add column user_id uuid references auth.users(id);
alter table skill_signal add column user_id uuid references auth.users(id);
alter table portfolio_repos add column user_id uuid references auth.users(id);
alter table saved_jobs add column user_id uuid references auth.users(id);
alter table watch_companies add column user_id uuid references auth.users(id);

-- app_settings held one row per key globally — now it's one row per (user, key)
alter table app_settings drop constraint app_settings_pkey;
alter table app_settings add column user_id uuid references auth.users(id);
alter table app_settings add primary key (user_id, key);

-- company tracking and saved jobs must be unique per-user now, not globally
alter table watch_companies drop constraint watch_companies_company_name_key;
alter table watch_companies add constraint watch_companies_user_company_unique unique (user_id, company_name);
alter table saved_jobs drop constraint saved_jobs_pkey;
alter table saved_jobs add primary key (user_id, job_id);

-- ============ replace permissive policies with real per-user ones ============
drop policy "allow all - scans" on scans;
drop policy "allow all - job_scan_results" on job_scan_results;
drop policy "allow all - plans" on plans;
drop policy "allow all - skill_signal" on skill_signal;
drop policy "allow all - portfolio_repos" on portfolio_repos;
drop policy "allow all - saved_jobs" on saved_jobs;
drop policy "allow all - watch_companies" on watch_companies;
drop policy "allow all - app_settings" on app_settings;

create policy "own rows only - scans" on scans for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - job_scan_results" on job_scan_results for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - plans" on plans for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - skill_signal" on skill_signal for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - portfolio_repos" on portfolio_repos for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - saved_jobs" on saved_jobs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - watch_companies" on watch_companies for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own rows only - app_settings" on app_settings for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- jobs and broken_links stay shared, but now require SOME logged-in user,
-- not literally anyone with the anon key
drop policy "allow all - jobs" on jobs;
drop policy "allow all - broken_links" on broken_links;
create policy "authenticated - jobs" on jobs for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');
create policy "authenticated - broken_links" on broken_links for all using (auth.role() = 'authenticated') with check (auth.role() = 'authenticated');

-- ============ analytics — for you, the operator ============
-- These are plain views. As project owner, RLS doesn't restrict what you see in
-- the SQL Editor regardless — but these give you clean aggregate numbers instead
-- of hand-rolling a query each time. Nothing here exposes individual identities.

create or replace view analytics_usage_summary as
select
  count(distinct user_id) as total_users,
  count(*) as total_scans,
  count(*) filter (where scan_type = 'scan') as general_scans,
  count(*) filter (where scan_type = 'watchlist') as watchlist_scans,
  min(ran_at) as first_scan_at,
  max(ran_at) as most_recent_scan_at
from scans;

create or replace view analytics_search_trends as
select
  keywords,
  location,
  scan_type,
  count(*) as times_searched,
  date_trunc('day', ran_at) as day
from scans
group by keywords, location, scan_type, day
order by day desc, times_searched desc;

create or replace view analytics_skill_demand as
select skill, count(*) as times_seen
from skill_signal
group by skill
order by times_seen desc;

create or replace view analytics_watched_companies as
select company_name, count(*) as times_tracked
from watch_companies
group by company_name
order by times_tracked desc;

-- quick reference once this is deployed:
--   select * from analytics_usage_summary;
--   select * from analytics_search_trends limit 20;
--   select * from analytics_skill_demand limit 20;
--   select * from analytics_watched_companies limit 20;
