-- =============================================================
-- Bent Tree Tone Lab - Supabase schema
-- Run once in Supabase: SQL Editor > New query > paste > Run.
-- Safe to run in an existing project (tables are prefixed tone_lab_).
-- =============================================================

-- ---------- User presets ----------
create table if not exists public.tone_lab_presets (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  device_id   text not null check (char_length(device_id) between 1 and 64),
  name        text not null check (char_length(name) between 1 and 60),
  settings    jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  unique (user_id, device_id, name)
);

create index if not exists tone_lab_presets_user_device_idx
  on public.tone_lab_presets (user_id, device_id);

alter table public.tone_lab_presets enable row level security;

-- Each signed-in user can only see and change their own presets.
drop policy if exists "own presets: read"   on public.tone_lab_presets;
drop policy if exists "own presets: insert" on public.tone_lab_presets;
drop policy if exists "own presets: update" on public.tone_lab_presets;
drop policy if exists "own presets: delete" on public.tone_lab_presets;

create policy "own presets: read"   on public.tone_lab_presets
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "own presets: insert" on public.tone_lab_presets
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "own presets: update" on public.tone_lab_presets
  for update to authenticated using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "own presets: delete" on public.tone_lab_presets
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ---------- Feedback & gear requests ----------
create table if not exists public.tone_lab_feedback (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid default auth.uid() references auth.users(id) on delete set null,
  kind        text not null check (kind in ('feedback', 'pedal_request', 'amp_request', 'bug')),
  gear        text check (char_length(gear) <= 120),
  message     text check (char_length(message) <= 2000),
  email       text check (char_length(email) <= 200),
  device_id   text check (char_length(device_id) <= 64),
  page_url    text check (char_length(page_url) <= 500),
  status      text not null default 'new' check (status in ('new', 'planned', 'done', 'declined')),
  created_at  timestamptz not null default now(),
  check (gear is not null or message is not null)
);

alter table public.tone_lab_feedback enable row level security;

-- Anyone (signed in or not) can SEND feedback. Nobody can read it
-- through the public API - you read it in the Supabase dashboard
-- (Table Editor > tone_lab_feedback) or via the service role.
drop policy if exists "anyone can send feedback" on public.tone_lab_feedback;
create policy "anyone can send feedback" on public.tone_lab_feedback
  for insert to anon, authenticated
  with check (
    status = 'new'
    and (user_id is null or user_id = (select auth.uid()))
  );

-- Handy view for triage: most-requested gear first.
create or replace view public.tone_lab_request_tally
with (security_invoker = true) as
  select kind, lower(trim(gear)) as gear, count(*) as requests, max(created_at) as last_requested
  from public.tone_lab_feedback
  where kind in ('pedal_request', 'amp_request') and gear is not null
  group by kind, lower(trim(gear))
  order by requests desc, last_requested desc;
