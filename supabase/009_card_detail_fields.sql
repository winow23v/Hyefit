-- ============================================
-- 009: 카드 상세보기 전용 필드 확장
-- 생성일: 2026-02-13
-- 목적: 상세보기 UI(연회비/브랜드/주요혜택/전월실적)에 필요한 필드 추가
-- ============================================

BEGIN;

ALTER TABLE public.card_master
  ADD COLUMN IF NOT EXISTS annual_fee_domestic INTEGER,
  ADD COLUMN IF NOT EXISTS annual_fee_overseas INTEGER,
  ADD COLUMN IF NOT EXISTS brand_options TEXT[],
  ADD COLUMN IF NOT EXISTS main_benefits TEXT[],
  ADD COLUMN IF NOT EXISTS prev_month_spend_text TEXT,
  ADD COLUMN IF NOT EXISTS card_image_url TEXT;

UPDATE public.card_master
SET
  annual_fee_domestic = COALESCE(annual_fee_domestic, annual_fee, 0),
  annual_fee_overseas = COALESCE(annual_fee_overseas, annual_fee, 0),
  brand_options = COALESCE(brand_options, '{}'::TEXT[]),
  main_benefits = COALESCE(main_benefits, '{}'::TEXT[]),
  prev_month_spend_text = COALESCE(prev_month_spend_text, ''),
  card_image_url = COALESCE(card_image_url, '')
WHERE
  annual_fee_domestic IS NULL
  OR annual_fee_overseas IS NULL
  OR brand_options IS NULL
  OR main_benefits IS NULL
  OR prev_month_spend_text IS NULL
  OR card_image_url IS NULL;

ALTER TABLE public.card_master
  ALTER COLUMN annual_fee_domestic SET DEFAULT 0,
  ALTER COLUMN annual_fee_overseas SET DEFAULT 0,
  ALTER COLUMN brand_options SET DEFAULT '{}'::TEXT[],
  ALTER COLUMN main_benefits SET DEFAULT '{}'::TEXT[],
  ALTER COLUMN prev_month_spend_text SET DEFAULT '',
  ALTER COLUMN card_image_url SET DEFAULT '',
  ALTER COLUMN annual_fee_domestic SET NOT NULL,
  ALTER COLUMN annual_fee_overseas SET NOT NULL,
  ALTER COLUMN brand_options SET NOT NULL,
  ALTER COLUMN main_benefits SET NOT NULL,
  ALTER COLUMN prev_month_spend_text SET NOT NULL,
  ALTER COLUMN card_image_url SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_annual_fee_domestic_non_negative'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_annual_fee_domestic_non_negative
      CHECK (annual_fee_domestic >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_annual_fee_overseas_non_negative'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_annual_fee_overseas_non_negative
      CHECK (annual_fee_overseas >= 0) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_brand_options_max_len'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_brand_options_max_len
      CHECK (COALESCE(array_length(brand_options, 1), 0) <= 8) NOT VALID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'card_master_main_benefits_max_len'
  ) THEN
    ALTER TABLE public.card_master
      ADD CONSTRAINT card_master_main_benefits_max_len
      CHECK (COALESCE(array_length(main_benefits, 1), 0) <= 8) NOT VALID;
  END IF;
END $$;

CREATE OR REPLACE VIEW public.card_benefit_catalog
WITH (security_invoker = true) AS
SELECT
  cm.id AS card_id,
  cm.card_name,
  cm.issuer,
  cm.annual_fee,
  cm.image_color,
  cm.description,
  cm.monthly_benefit_cap,
  cbt.id AS tier_id,
  cbt.tier_name,
  cbt.min_prev_spend,
  cbt.max_prev_spend,
  cbt.tier_order,
  ctr.id AS rule_id,
  ctr.category,
  ctr.benefit_type,
  ctr.benefit_rate,
  ctr.max_benefit_amount,
  ctr.priority,
  cm.annual_fee_domestic,
  cm.annual_fee_overseas,
  cm.brand_options,
  cm.main_benefits,
  cm.prev_month_spend_text,
  cm.card_image_url
FROM card_master cm
JOIN card_benefit_tiers cbt ON cbt.card_id = cm.id
JOIN card_tier_rules ctr ON ctr.tier_id = cbt.id;

CREATE OR REPLACE FUNCTION public.upsert_cards_from_json(
  p_cards JSONB
)
RETURNS TABLE (
  card_id UUID,
  card_name TEXT,
  issuer TEXT
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_card JSONB;
  v_tier JSONB;
  v_rule JSONB;

  v_card_id UUID;
  v_tier_id UUID;

  v_card_name TEXT;
  v_issuer TEXT;
  v_tier_name TEXT;

  v_annual_fee INTEGER;
  v_annual_fee_domestic INTEGER;
  v_annual_fee_overseas INTEGER;
  v_monthly_cap INTEGER;
  v_base_rate NUMERIC(5,2);
  v_base_type TEXT;
  v_description TEXT;
  v_image_color TEXT;
  v_brand_options TEXT[];
  v_main_benefits TEXT[];
  v_prev_month_spend_text TEXT;
  v_card_image_url TEXT;

  v_tier_order INTEGER;
  v_min_prev_spend INTEGER;
  v_max_prev_spend INTEGER;

  v_rule_order INTEGER;
  v_priority INTEGER;
  v_category TEXT;
  v_benefit_type TEXT;
  v_benefit_rate NUMERIC(5,2);
  v_max_benefit INTEGER;

  v_tiers JSONB;
  v_rules JSONB;
BEGIN
  IF p_cards IS NULL OR jsonb_typeof(p_cards) <> 'array' THEN
    RAISE EXCEPTION 'p_cards는 JSON 배열이어야 합니다.';
  END IF;

  FOR v_card IN
    SELECT value FROM jsonb_array_elements(p_cards)
  LOOP
    v_card_name := BTRIM(COALESCE(v_card->>'card_name', ''));
    v_issuer := BTRIM(COALESCE(v_card->>'issuer', ''));

    IF v_card_name = '' OR v_issuer = '' THEN
      RAISE EXCEPTION 'card_name, issuer는 필수입니다. 입력값=%', v_card::TEXT;
    END IF;

    v_annual_fee := GREATEST(public.safe_to_int(v_card->>'annual_fee', 0), 0);
    v_annual_fee_domestic := GREATEST(
      public.safe_to_int(v_card->>'annual_fee_domestic', v_annual_fee),
      0
    );
    v_annual_fee_overseas := GREATEST(
      public.safe_to_int(v_card->>'annual_fee_overseas', v_annual_fee_domestic),
      0
    );
    v_monthly_cap := GREATEST(public.safe_to_int(v_card->>'monthly_benefit_cap', 0), 0);
    v_base_rate := GREATEST(public.safe_to_numeric(v_card->>'base_benefit_rate', 0), 0);
    v_base_type := LOWER(BTRIM(COALESCE(v_card->>'base_benefit_type', 'cashback')));
    IF v_base_type NOT IN ('cashback', 'point', 'discount', 'mileage') THEN
      v_base_type := 'cashback';
    END IF;
    v_description := LEFT(BTRIM(COALESCE(v_card->>'description', '')), 1000);
    v_image_color := UPPER(BTRIM(COALESCE(v_card->>'image_color', '#7C83FD')));
    IF v_image_color !~ '^#[0-9A-F]{6}$' THEN
      v_image_color := '#7C83FD';
    END IF;
    v_brand_options := ARRAY(
      SELECT LEFT(BTRIM(value), 30)
      FROM jsonb_array_elements_text(
        CASE
          WHEN jsonb_typeof(v_card->'brand_options') = 'array' THEN v_card->'brand_options'
          ELSE '[]'::JSONB
        END
      ) AS t(value)
      WHERE BTRIM(value) <> ''
      LIMIT 8
    );
    v_main_benefits := ARRAY(
      SELECT LEFT(BTRIM(value), 80)
      FROM jsonb_array_elements_text(
        CASE
          WHEN jsonb_typeof(v_card->'main_benefits') = 'array' THEN v_card->'main_benefits'
          ELSE '[]'::JSONB
        END
      ) AS t(value)
      WHERE BTRIM(value) <> ''
      LIMIT 8
    );
    v_prev_month_spend_text := LEFT(BTRIM(COALESCE(v_card->>'prev_month_spend_text', '')), 160);
    v_card_image_url := LEFT(BTRIM(COALESCE(v_card->>'card_image_url', '')), 500);

    INSERT INTO card_master (
      card_name, issuer, annual_fee, annual_fee_domestic, annual_fee_overseas,
      image_color, brand_options, main_benefits, prev_month_spend_text, card_image_url,
      monthly_benefit_cap, base_benefit_rate, base_benefit_type, description
    )
    VALUES (
      v_card_name, v_issuer, v_annual_fee, v_annual_fee_domestic, v_annual_fee_overseas,
      v_image_color, v_brand_options, v_main_benefits, v_prev_month_spend_text, v_card_image_url,
      v_monthly_cap, v_base_rate, v_base_type, v_description
    )
    ON CONFLICT (card_name, issuer) DO UPDATE
    SET
      annual_fee = EXCLUDED.annual_fee,
      annual_fee_domestic = EXCLUDED.annual_fee_domestic,
      annual_fee_overseas = EXCLUDED.annual_fee_overseas,
      image_color = EXCLUDED.image_color,
      brand_options = EXCLUDED.brand_options,
      main_benefits = EXCLUDED.main_benefits,
      prev_month_spend_text = EXCLUDED.prev_month_spend_text,
      card_image_url = EXCLUDED.card_image_url,
      monthly_benefit_cap = EXCLUDED.monthly_benefit_cap,
      base_benefit_rate = EXCLUDED.base_benefit_rate,
      base_benefit_type = EXCLUDED.base_benefit_type,
      description = EXCLUDED.description
    RETURNING id INTO v_card_id;

    DELETE FROM card_benefit_tiers
    WHERE card_id = v_card_id;

    v_tiers := COALESCE(v_card->'tiers', '[]'::JSONB);
    IF jsonb_typeof(v_tiers) <> 'array' OR jsonb_array_length(v_tiers) = 0 THEN
      RAISE EXCEPTION '%: tiers를 1개 이상 입력해주세요.', v_card_name;
    END IF;

    v_tier_order := 0;
    FOR v_tier IN
      SELECT value FROM jsonb_array_elements(v_tiers)
    LOOP
      v_tier_order := v_tier_order + 1;

      v_min_prev_spend := GREATEST(public.safe_to_int(v_tier->>'min_prev_spend', 0), 0);
      IF BTRIM(COALESCE(v_tier->>'max_prev_spend', '')) = '' THEN
        v_max_prev_spend := NULL;
      ELSE
        v_max_prev_spend := public.safe_to_int(v_tier->>'max_prev_spend', 0);
      END IF;

      IF v_max_prev_spend IS NOT NULL AND v_max_prev_spend < v_min_prev_spend THEN
        RAISE EXCEPTION '%: tier %의 max_prev_spend가 min_prev_spend보다 작습니다.',
          v_card_name, v_tier_order;
      END IF;

      v_tier_name := BTRIM(COALESCE(v_tier->>'tier_name', ''));
      IF v_tier_name = '' THEN
        IF v_min_prev_spend > 0 THEN
          v_tier_name := (v_min_prev_spend / 10000)::TEXT || '만원 이상';
        ELSE
          v_tier_name := '조건없음';
        END IF;
      END IF;

      INSERT INTO card_benefit_tiers (
        card_id, tier_name, min_prev_spend, max_prev_spend, tier_order
      )
      VALUES (
        v_card_id, v_tier_name, v_min_prev_spend, v_max_prev_spend, v_tier_order
      )
      RETURNING id INTO v_tier_id;

      v_rules := COALESCE(v_tier->'rules', '[]'::JSONB);
      IF jsonb_typeof(v_rules) <> 'array' OR jsonb_array_length(v_rules) = 0 THEN
        RAISE EXCEPTION '%: tier %의 rules를 1개 이상 입력해주세요.',
          v_card_name, v_tier_order;
      END IF;

      v_rule_order := 0;
      FOR v_rule IN
        SELECT value FROM jsonb_array_elements(v_rules)
      LOOP
        v_rule_order := v_rule_order + 1;

        v_category := public.normalize_import_category(v_rule->>'category');
        v_benefit_type := LOWER(BTRIM(COALESCE(v_rule->>'benefit_type', 'cashback')));
        IF v_benefit_type NOT IN ('cashback', 'point', 'discount', 'mileage') THEN
          v_benefit_type := 'cashback';
        END IF;
        v_benefit_rate := GREATEST(public.safe_to_numeric(v_rule->>'benefit_rate', 0), 0);
        v_max_benefit := GREATEST(public.safe_to_int(v_rule->>'max_benefit_amount', 0), 0);
        v_priority := public.safe_to_int(v_rule->>'priority', v_rule_order);
        IF v_priority <= 0 THEN
          v_priority := v_rule_order;
        END IF;

        INSERT INTO card_tier_rules (
          tier_id, category, benefit_type, benefit_rate, max_benefit_amount, priority
        )
        VALUES (
          v_tier_id, v_category, v_benefit_type, v_benefit_rate, v_max_benefit, v_priority
        )
        ON CONFLICT (tier_id, category, priority) DO UPDATE
        SET
          benefit_type = EXCLUDED.benefit_type,
          benefit_rate = EXCLUDED.benefit_rate,
          max_benefit_amount = EXCLUDED.max_benefit_amount;
      END LOOP;
    END LOOP;

    card_id := v_card_id;
    card_name := v_card_name;
    issuer := v_issuer;
    RETURN NEXT;
  END LOOP;
END $$;

GRANT EXECUTE ON FUNCTION public.upsert_cards_from_json(JSONB) TO authenticated;

COMMIT;
