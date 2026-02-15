-- ============================================
-- 008: 스키마 무결성/권한/인덱스 보강
-- 생성일: 2026-02-13
-- 목적: 기존 운영 DB에 유지보수 보강 사항 적용
-- ============================================

BEGIN;

-- 관리자 판별 함수 (서버측 권한 강제)
CREATE OR REPLACE FUNCTION public.is_admin_user()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY INVOKER
SET search_path = public
AS $$
  SELECT LOWER(COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', '')) = 'admin';
$$;

GRANT EXECUTE ON FUNCTION public.is_admin_user() TO authenticated;

-- 무결성 제약 추가 (기존 데이터와 충돌을 피하기 위해 NOT VALID로 추가)
DO $$
BEGIN
  -- 구버전 스키마 호환: display_order 컬럼이 없다면 먼저 추가
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'user_cards'
      AND column_name = 'display_order'
  ) THEN
    ALTER TABLE public.user_cards
      ADD COLUMN display_order INTEGER NOT NULL DEFAULT 0;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_annual_fee_non_negative'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_annual_fee_non_negative
      CHECK (annual_fee >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_monthly_cap_non_negative'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_monthly_cap_non_negative
      CHECK (monthly_benefit_cap >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_base_rate_range'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_base_rate_range
      CHECK (base_benefit_rate >= 0 AND base_benefit_rate <= 100) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_base_type_allowed'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_base_type_allowed
      CHECK (base_benefit_type IN ('cashback', 'point', 'discount', 'mileage')) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_image_color_hex'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_image_color_hex
      CHECK (image_color ~ '^#[0-9A-Fa-f]{6}$') NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_benefit_tiers_min_non_negative'
  ) THEN
    ALTER TABLE public.card_benefit_tiers
      ADD CONSTRAINT card_benefit_tiers_min_non_negative
      CHECK (min_prev_spend >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_benefit_tiers_max_not_less_than_min'
  ) THEN
    ALTER TABLE public.card_benefit_tiers
      ADD CONSTRAINT card_benefit_tiers_max_not_less_than_min
      CHECK (max_prev_spend IS NULL OR max_prev_spend >= min_prev_spend) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_benefit_tiers_order_positive'
  ) THEN
    ALTER TABLE public.card_benefit_tiers
      ADD CONSTRAINT card_benefit_tiers_order_positive
      CHECK (tier_order > 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_tier_rules_category_not_blank'
  ) THEN
    ALTER TABLE public.card_tier_rules
      ADD CONSTRAINT card_tier_rules_category_not_blank
      CHECK (BTRIM(category) <> '') NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_tier_rules_benefit_type_allowed'
  ) THEN
    ALTER TABLE public.card_tier_rules
      ADD CONSTRAINT card_tier_rules_benefit_type_allowed
      CHECK (benefit_type IN ('cashback', 'point', 'discount', 'mileage')) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_tier_rules_benefit_rate_range'
  ) THEN
    ALTER TABLE public.card_tier_rules
      ADD CONSTRAINT card_tier_rules_benefit_rate_range
      CHECK (benefit_rate >= 0 AND benefit_rate <= 100) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_tier_rules_max_benefit_non_negative'
  ) THEN
    ALTER TABLE public.card_tier_rules
      ADD CONSTRAINT card_tier_rules_max_benefit_non_negative
      CHECK (max_benefit_amount >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_tier_rules_priority_positive'
  ) THEN
    ALTER TABLE public.card_tier_rules
      ADD CONSTRAINT card_tier_rules_priority_positive
      CHECK (priority > 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'user_cards_display_order_non_negative'
  ) THEN
    ALTER TABLE public.user_cards
      ADD CONSTRAINT user_cards_display_order_non_negative
      CHECK (display_order >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'user_cards_id_user_id_key'
  ) THEN
    ALTER TABLE public.user_cards
      ADD CONSTRAINT user_cards_id_user_id_key UNIQUE (id, user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'user_card_status_spend_non_negative'
  ) THEN
    ALTER TABLE public.user_card_status
      ADD CONSTRAINT user_card_status_spend_non_negative
      CHECK (current_spend >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'user_card_status_benefit_non_negative'
  ) THEN
    ALTER TABLE public.user_card_status
      ADD CONSTRAINT user_card_status_benefit_non_negative
      CHECK (current_benefit >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'user_card_status_period_valid'
  ) THEN
    ALTER TABLE public.user_card_status
      ADD CONSTRAINT user_card_status_period_valid
      CHECK (period_end >= period_start) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'transactions_amount_positive'
  ) THEN
    ALTER TABLE public.transactions
      ADD CONSTRAINT transactions_amount_positive
      CHECK (amount > 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'transactions_category_not_blank'
  ) THEN
    ALTER TABLE public.transactions
      ADD CONSTRAINT transactions_category_not_blank
      CHECK (BTRIM(category) <> '') NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'transactions_user_card_owner_fk'
  ) THEN
    ALTER TABLE public.transactions
      ADD CONSTRAINT transactions_user_card_owner_fk
      FOREIGN KEY (user_card_id, user_id)
      REFERENCES public.user_cards(id, user_id)
      ON DELETE CASCADE
      NOT VALID;
  END IF;
END $$;

-- 쿼리 패턴 기반 인덱스 보강
CREATE INDEX IF NOT EXISTS idx_user_card_status_period
  ON public.user_card_status(user_card_id, period_start);

CREATE INDEX IF NOT EXISTS idx_transactions_user_card_date
  ON public.transactions(user_id, user_card_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_transactions_user_card_category_date
  ON public.transactions(user_id, user_card_id, category, transaction_date);

-- 관리자 테이블 RLS 정책 강화
ALTER TABLE public.card_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_benefit_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.card_tier_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "card_master_insert" ON public.card_master;
DROP POLICY IF EXISTS "card_master_update" ON public.card_master;
DROP POLICY IF EXISTS "card_master_delete" ON public.card_master;
CREATE POLICY "card_master_insert" ON public.card_master
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_user());
CREATE POLICY "card_master_update" ON public.card_master
  FOR UPDATE TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "card_master_delete" ON public.card_master
  FOR DELETE TO authenticated USING (public.is_admin_user());

DROP POLICY IF EXISTS "card_benefit_tiers_insert" ON public.card_benefit_tiers;
DROP POLICY IF EXISTS "card_benefit_tiers_update" ON public.card_benefit_tiers;
DROP POLICY IF EXISTS "card_benefit_tiers_delete" ON public.card_benefit_tiers;
CREATE POLICY "card_benefit_tiers_insert" ON public.card_benefit_tiers
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_user());
CREATE POLICY "card_benefit_tiers_update" ON public.card_benefit_tiers
  FOR UPDATE TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "card_benefit_tiers_delete" ON public.card_benefit_tiers
  FOR DELETE TO authenticated USING (public.is_admin_user());

DROP POLICY IF EXISTS "card_tier_rules_insert" ON public.card_tier_rules;
DROP POLICY IF EXISTS "card_tier_rules_update" ON public.card_tier_rules;
DROP POLICY IF EXISTS "card_tier_rules_delete" ON public.card_tier_rules;
CREATE POLICY "card_tier_rules_insert" ON public.card_tier_rules
  FOR INSERT TO authenticated WITH CHECK (public.is_admin_user());
CREATE POLICY "card_tier_rules_update" ON public.card_tier_rules
  FOR UPDATE TO authenticated USING (public.is_admin_user()) WITH CHECK (public.is_admin_user());
CREATE POLICY "card_tier_rules_delete" ON public.card_tier_rules
  FOR DELETE TO authenticated USING (public.is_admin_user());

COMMIT;
