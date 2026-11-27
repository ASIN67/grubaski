-- =============================================================================
-- Migration: Supabase Advisor Security & Performance Fixes
-- Project: wyrgagwstoscxhstyzmf
-- =============================================================================
-- 1. Security: Restrict public.seed_public_products(jsonb) execution to
--    service_role only (revoke EXECUTE from PUBLIC, anon, authenticated).
-- 2. Security: Move pg_trgm extension out of public schema into extensions.
-- 3. Performance: Wrap auth.uid() in (select auth.uid()) inside RLS policy
--    "Authors can update recipes" on public.public_recipes to avoid per-row
--    re-evaluation (auth_rls_initplan).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Security: Restrict public.seed_public_products(jsonb) to service_role
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF to_regprocedure('public.seed_public_products(jsonb)') IS NOT NULL THEN
    REVOKE EXECUTE ON FUNCTION public.seed_public_products(jsonb) FROM PUBLIC;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
      REVOKE EXECUTE ON FUNCTION public.seed_public_products(jsonb) FROM anon;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
      REVOKE EXECUTE ON FUNCTION public.seed_public_products(jsonb) FROM authenticated;
    END IF;

    IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
      GRANT EXECUTE ON FUNCTION public.seed_public_products(jsonb) TO service_role;
    END IF;
  END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- 2. Security: Move pg_trgm extension out of public into extensions schema
-- -----------------------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS extensions;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    GRANT USAGE ON SCHEMA extensions TO anon;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN
    GRANT USAGE ON SCHEMA extensions TO authenticated;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN
    GRANT USAGE ON SCHEMA extensions TO service_role;
  END IF;

  IF EXISTS (
    SELECT 1
    FROM pg_extension e
    JOIN pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname = 'pg_trgm'
      AND n.nspname = 'public'
      AND e.extrelocatable
  ) THEN
    -- Moving pg_trgm automatically updates its operator classes (e.g. gin_trgm_ops
    -- referenced by idx_public_products_trgm via OID) without breaking indexes.
    ALTER EXTENSION pg_trgm SET SCHEMA extensions;
  END IF;
END
$$;

-- -----------------------------------------------------------------------------
-- 3. Performance: Optimize RLS policy on public.public_recipes
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.public_recipes') IS NOT NULL THEN
    IF EXISTS (
      SELECT 1
      FROM pg_policies
      WHERE schemaname = 'public'
        AND tablename = 'public_recipes'
        AND policyname = 'Authors can update recipes'
    ) THEN
      ALTER POLICY "Authors can update recipes"
        ON public.public_recipes
        USING ((select auth.uid()) = author_id)
        WITH CHECK ((select auth.uid()) = author_id);
    ELSE
      CREATE POLICY "Authors can update recipes"
        ON public.public_recipes
        FOR UPDATE
        TO authenticated
        USING ((select auth.uid()) = author_id)
        WITH CHECK ((select auth.uid()) = author_id);
    END IF;
  END IF;
END
$$;
