-- job radar — Supabase schema
-- Run this once in Project → SQL Editor → New query → Run

-- ============ core job data ============

-- jobs: canonical, deduped list of every posting ever found (by company+title)
create table jobs (
  id uuid primary key default gen_random_uuid(),
  company text not null,
  title text not null,
  location text,
  url text,
  first_seen timestamptz default now(),
  last_seen timestamptz default now(),
  origins text[] default '{}',           -- 'scan', 'watchlist', or both
  unique (company, title)
);

-- scans: one row per "run scan" / "check open roles" click — the audit log
create table scans (
  id uuid primary key default gen_random_uuid(),
  scan_type text not null check (scan_type in ('scan','watchlist')),
  keywords text,
  location text,
  tags text[],
  companies text[],
  ran_at timestamptz default now()
);

-- job_scan_results: THIS is what makes "watch it again" real — the score/fit/gate
-- a job got on a SPECIFIC scan, not a single overwritten value. Same job can have
-- many rows here across many scans, so you can see how its score moved over time.
create table job_scan_results (
  id uuid primary key default gen_random_uuid(),
  job_id uuid references jobs(id) on delete cascade,
  scan_id uuid references scans(id) on delete cascade,
  score int,
  gate text,
  fit text,
  jd_summary text,
  skills_required text[],
  source text,
  created_at timestamptz default now()
);

-- ============ plans ============

-- plans: every six-month plan ever generated, kept — not overwritten like before
create table plans (
  id uuid primary key default gen_random_uuid(),
  skill_gaps jsonb,
  side_projects jsonb,
  cadence text,
  market_tally_snapshot jsonb,
  generated_at timestamptz default now()
);

-- skill_signal: a proper time series (skill, when, which scan) instead of one
-- flattened running counter — lets you see trend, not just current total
create table skill_signal (
  id uuid primary key default gen_random_uuid(),
  skill text not null,
  scan_id uuid references scans(id) on delete cascade,
  seen_at timestamptz default now()
);

-- ============ portfolio & tracking ============

create table portfolio_repos (
  id uuid primary key default gen_random_uuid(),
  project_title text not null,
  repo_url text not null,
  created_at timestamptz default now()
);

create table saved_jobs (
  job_id uuid references jobs(id) on delete cascade primary key,
  saved_at timestamptz default now()
);

create table broken_links (
  job_id uuid references jobs(id) on delete cascade primary key,
  flagged_at timestamptz default now()
);

create table watch_companies (
  id uuid primary key default gen_random_uuid(),
  company_name text not null unique
);

-- app_settings: single-row-per-key store for everything else that doesn't need
-- its own table — skills profile text, custom search tags, removed presets,
-- prompt overrides. Deliberately NOT storing the GitHub token here (see note below).
create table app_settings (
  key text primary key,
  value jsonb,
  updated_at timestamptz default now()
);

-- ============ row level security ============
-- Enabled on every table, with a permissive "allow all" policy for now since this
-- is a single-user personal tool with no login system yet. IMPORTANT: this means
-- anyone who has your anon key (which lives in the HTML file itself) can read and
-- write this data. Fine for personal use on a file only you run. NOT fine the
-- moment this becomes multi-user or gets shared — that needs real Supabase Auth
-- and per-user policies before going further, and I'd want to do that as a
-- deliberate step, not something quietly skipped.

alter table jobs enable row level security;
alter table scans enable row level security;
alter table job_scan_results enable row level security;
alter table plans enable row level security;
alter table skill_signal enable row level security;
alter table portfolio_repos enable row level security;
alter table saved_jobs enable row level security;
alter table broken_links enable row level security;
alter table watch_companies enable row level security;
alter table app_settings enable row level security;

create policy "allow all - jobs" on jobs for all using (true) with check (true);
create policy "allow all - scans" on scans for all using (true) with check (true);
create policy "allow all - job_scan_results" on job_scan_results for all using (true) with check (true);
create policy "allow all - plans" on plans for all using (true) with check (true);
create policy "allow all - skill_signal" on skill_signal for all using (true) with check (true);
create policy "allow all - portfolio_repos" on portfolio_repos for all using (true) with check (true);
create policy "allow all - saved_jobs" on saved_jobs for all using (true) with check (true);
create policy "allow all - broken_links" on broken_links for all using (true) with check (true);
create policy "allow all - watch_companies" on watch_companies for all using (true) with check (true);
create policy "allow all - app_settings" on app_settings for all using (true) with check (true);

-- ============ helpful indexes ============
create index idx_job_scan_results_job on job_scan_results(job_id);
create index idx_job_scan_results_scan on job_scan_results(scan_id);
create index idx_skill_signal_skill on skill_signal(skill);
create index idx_scans_ran_at on scans(ran_at desc);
