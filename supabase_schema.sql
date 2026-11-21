-- =============================================================================
-- GRUBASEK - SUPABASE PRODUCTION DATABASE SCHEMA
-- Multi-user Cloud Sync, Authentication, and Shared Public Food Catalog
-- =============================================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pg_trgm";

-- -----------------------------------------------------------------------------
-- 1. PUBLIC FOOD PRODUCTS (Katalog produktów online)
-- -----------------------------------------------------------------------------
create table if not exists public.public_products (
  id text primary key,
  barcode text,
  name text not null,
  brand text,
  calories_per_100g numeric(7, 2) not null check (calories_per_100g >= 0),
  protein_per_100g numeric(7, 2) not null check (protein_per_100g >= 0),
  carbs_per_100g numeric(7, 2) not null check (carbs_per_100g >= 0),
  fat_per_100g numeric(7, 2) not null check (fat_per_100g >= 0),
  fiber_per_100g numeric(7, 2) check (fiber_per_100g is null or fiber_per_100g >= 0),
  serving_size_grams numeric(7, 2) not null default 100.0 check (serving_size_grams > 0),
  serving_name text,
  is_custom boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Trigram GIN index for ultra-fast fuzzy and substring search across Polish names and brands
create index if not exists idx_public_products_trgm on public.public_products using gin (
  (lower(name) || ' ' || coalesce(lower(brand), '')) gin_trgm_ops
);

-- Index for instant barcode scan lookups
create index if not exists idx_public_products_barcode on public.public_products (barcode)
where barcode is not null;

-- Covering index for created_by foreign key
create index if not exists idx_public_products_created_by on public.public_products (created_by);

-- RLS: public read for everyone, insert/update by authenticated users
alter table public.public_products enable row level security;

create policy "Public products are viewable by everyone"
  on public.public_products for select
  using (true);

create policy "Authenticated users can insert products"
  on public.public_products for insert
  to authenticated
  with check ((select auth.uid()) = created_by or created_by is null);

create policy "Users can update their own authored products"
  on public.public_products for update
  to authenticated
  using ((select auth.uid()) = created_by)
  with check ((select auth.uid()) = created_by);

-- -----------------------------------------------------------------------------
-- 2. USER PROFILES (Profile użytkowników i cele kaloryczne)
-- -----------------------------------------------------------------------------
create table if not exists public.user_profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  gender text not null check (gender in ('male', 'female')),
  age integer not null check (age between 10 and 120),
  start_weight_kg numeric(5, 2) not null check (start_weight_kg > 0),
  target_weight_kg numeric(5, 2) not null check (target_weight_kg > 0),
  height_cm numeric(5, 2) not null check (height_cm between 50 and 260),
  activity_level text not null check (activity_level in ('sedentary', 'light', 'moderate', 'active', 'veryActive')),
  goal text not null check (goal in ('reduction', 'maintenance', 'surplus')),
  weekly_pace_kg numeric(4, 2) not null default 0.50,
  daily_calories_goal integer not null check (daily_calories_goal >= 500),
  protein_goal_grams integer not null check (protein_goal_grams >= 0),
  carbs_goal_grams integer not null check (carbs_goal_grams >= 0),
  fat_goal_grams integer not null check (fat_goal_grams >= 0),
  water_goal_ml integer not null check (water_goal_ml >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_profiles enable row level security;

create policy "Users can view their own profile"
  on public.user_profiles for select
  to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can insert their own profile"
  on public.user_profiles for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

create policy "Users can update their own profile"
  on public.user_profiles for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "Users can delete their own profile"
  on public.user_profiles for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 3. MEAL ENTRIES (Wpisy posiłków w dzienniku żywieniowym)
-- -----------------------------------------------------------------------------
create table if not exists public.meal_entries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key text not null, -- Format YYYY-MM-DD
  meal_type text not null check (meal_type in ('breakfast', 'secondBreakfast', 'lunch', 'snack', 'dinner')),
  grams numeric(7, 2) not null check (grams > 0),
  product_snapshot jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_meal_entries_user_date on public.meal_entries (user_id, date_key);

alter table public.meal_entries enable row level security;

create policy "Users manage their own meal entries"
  on public.meal_entries for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 4. DAILY WATER LOGS (Dziennik nawodnienia)
-- -----------------------------------------------------------------------------
create table if not exists public.daily_water_logs (
  user_id uuid not null references auth.users(id) on delete cascade,
  date_key text not null, -- Format YYYY-MM-DD
  amount_ml integer not null check (amount_ml >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, date_key)
);

create index if not exists idx_water_logs_user on public.daily_water_logs (user_id);

alter table public.daily_water_logs enable row level security;

create policy "Users manage their own water logs"
  on public.daily_water_logs for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 5. WEIGHT ENTRIES (Pomiary wagi ciała)
-- -----------------------------------------------------------------------------
create table if not exists public.weight_entries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz not null,
  weight_kg numeric(5, 2) not null check (weight_kg > 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_weight_entries_user_date on public.weight_entries (user_id, date desc);

alter table public.weight_entries enable row level security;

create policy "Users manage their own weight entries"
  on public.weight_entries for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 6. BODY MEASUREMENTS ENTRIES (Pomiary obwodów ciała)
-- -----------------------------------------------------------------------------
create table if not exists public.body_measurements_entries (
  id text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  date timestamptz not null,
  waist_cm numeric(5, 2) check (waist_cm is null or waist_cm > 0),
  chest_cm numeric(5, 2) check (chest_cm is null or chest_cm > 0),
  arm_cm numeric(5, 2) check (arm_cm is null or arm_cm > 0),
  hips_cm numeric(5, 2) check (hips_cm is null or hips_cm > 0),
  thigh_cm numeric(5, 2) check (thigh_cm is null or thigh_cm > 0),
  created_at timestamptz not null default now()
);

create index if not exists idx_body_measurements_user_date on public.body_measurements_entries (user_id, date desc);

alter table public.body_measurements_entries enable row level security;

create policy "Users manage their own body measurements"
  on public.body_measurements_entries for all
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- -----------------------------------------------------------------------------
-- 7. HELPER TRIGGERS FOR UPDATED_AT
-- -----------------------------------------------------------------------------
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create or replace trigger on_public_products_updated
  before update on public.public_products
  for each row execute function public.handle_updated_at();

create or replace trigger on_user_profiles_updated
  before update on public.user_profiles
  for each row execute function public.handle_updated_at();

create or replace trigger on_meal_entries_updated
  before update on public.meal_entries
  for each row execute function public.handle_updated_at();

create or replace trigger on_daily_water_logs_updated
  before update on public.daily_water_logs
  for each row execute function public.handle_updated_at();

-- -----------------------------------------------------------------------------
-- 8. APP RELEASES & IN-APP AUTO-UPDATES (OTA)
-- -----------------------------------------------------------------------------
create table if not exists public.app_releases (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('android', 'web', 'windows', 'ios')),
  version_name text not null,
  version_code integer not null,
  download_url text not null,
  changelog text,
  is_mandatory boolean not null default false,
  is_active boolean not null default true,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);

alter table public.app_releases enable row level security;

create policy "App releases are viewable by everyone"
  on public.app_releases for select
  using (true);

create index if not exists idx_app_releases_platform_code
  on public.app_releases (platform, version_code desc)
  where is_active = true;
