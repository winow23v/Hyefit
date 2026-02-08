-- ============================================
-- 혜핏(HyeFit) 전체 데이터베이스 스키마 (통합본)
-- 생성일: 2026-02-08
-- 목적: 새 환경에서 전체 DB를 한 번에 구축
-- ============================================
-- 이 파일은 001~007 마이그레이션을 모두 통합한 버전입니다.
-- 기존 마이그레이션 파일들은 버전 관리를 위해 계속 보관합니다.
-- ============================================

-- ============================================
-- SECTION 1: 테이블 생성
-- ============================================

-- 1. 카드 마스터 (003에서 확장된 버전)
CREATE TABLE IF NOT EXISTS card_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_name TEXT NOT NULL,
  issuer TEXT NOT NULL,
  annual_fee INTEGER NOT NULL DEFAULT 0,
  image_color TEXT DEFAULT '#7C83FD',
  monthly_benefit_cap INTEGER DEFAULT 0,
  base_benefit_rate NUMERIC(5,2) DEFAULT 0,
  base_benefit_type TEXT DEFAULT 'cashback',
  description TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT card_master_card_name_issuer_key UNIQUE (card_name, issuer)
);

-- 2. 카드 혜택 Tier (전월 실적 구간)
CREATE TABLE IF NOT EXISTS card_benefit_tiers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES card_master(id) ON DELETE CASCADE,
  tier_name TEXT NOT NULL DEFAULT '',
  min_prev_spend INTEGER NOT NULL DEFAULT 0,
  max_prev_spend INTEGER,
  tier_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT card_benefit_tiers_card_id_tier_order_key UNIQUE (card_id, tier_order)
);

-- 3. Tier별 카테고리 혜택 규칙
CREATE TABLE IF NOT EXISTS card_tier_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tier_id UUID NOT NULL REFERENCES card_benefit_tiers(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  benefit_type TEXT NOT NULL DEFAULT 'cashback',
  benefit_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  max_benefit_amount INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT card_tier_rules_tier_id_category_priority_key UNIQUE (tier_id, category, priority)
);

-- 4. 사용자 카드 보유 정보
CREATE TABLE IF NOT EXISTS user_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  card_master_id UUID NOT NULL REFERENCES card_master(id) ON DELETE CASCADE,
  nickname TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, card_master_id)
);

-- 5. 사용자 카드 상태 (공여기간 내 누적)
CREATE TABLE IF NOT EXISTS user_card_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_card_id UUID NOT NULL REFERENCES user_cards(id) ON DELETE CASCADE,
  current_spend INTEGER NOT NULL DEFAULT 0,
  current_benefit INTEGER NOT NULL DEFAULT 0,
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_card_id, period_start)
);

-- 6. 소비 내역
CREATE TABLE IF NOT EXISTS transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  user_card_id UUID NOT NULL REFERENCES user_cards(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL,
  category TEXT NOT NULL,
  memo TEXT,
  transaction_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- SECTION 2: 인덱스
-- ============================================

-- card_master 인덱스 (없음, UNIQUE 제약으로 충분)

-- card_benefit_tiers 인덱스
CREATE INDEX IF NOT EXISTS idx_benefit_tiers_card_id ON card_benefit_tiers(card_id);
CREATE INDEX IF NOT EXISTS idx_benefit_tiers_order ON card_benefit_tiers(card_id, tier_order);

-- card_tier_rules 인덱스
CREATE INDEX IF NOT EXISTS idx_tier_rules_tier_id ON card_tier_rules(tier_id);
CREATE INDEX IF NOT EXISTS idx_card_tier_rules_category ON card_tier_rules(category);

-- user_cards 인덱스
CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_user_order ON user_cards(user_id, display_order, created_at);

-- user_card_status 인덱스
CREATE INDEX IF NOT EXISTS idx_user_card_status_card_id ON user_card_status(user_card_id);

-- transactions 인덱스
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);

-- ============================================
-- SECTION 3: RLS 정책
-- ============================================

-- card_master: 인증된 사용자 읽기, 삽입, 업데이트, 삭제
ALTER TABLE card_master ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_master_select" ON card_master
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "card_master_insert" ON card_master
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_master_update" ON card_master
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "card_master_delete" ON card_master
  FOR DELETE TO authenticated USING (true);

-- card_benefit_tiers: 인증된 사용자 읽기, 삽입, 업데이트, 삭제
ALTER TABLE card_benefit_tiers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_benefit_tiers_select" ON card_benefit_tiers
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "card_benefit_tiers_insert" ON card_benefit_tiers
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_benefit_tiers_update" ON card_benefit_tiers
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "card_benefit_tiers_delete" ON card_benefit_tiers
  FOR DELETE TO authenticated USING (true);

-- card_tier_rules: 인증된 사용자 읽기, 삽입, 업데이트, 삭제
ALTER TABLE card_tier_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_tier_rules_select" ON card_tier_rules
  FOR SELECT TO authenticated USING (true);
CREATE POLICY "card_tier_rules_insert" ON card_tier_rules
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_tier_rules_update" ON card_tier_rules
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "card_tier_rules_delete" ON card_tier_rules
  FOR DELETE TO authenticated USING (true);

-- user_cards: 본인 데이터만
ALTER TABLE user_cards ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_cards_select" ON user_cards
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "user_cards_insert" ON user_cards
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_cards_update" ON user_cards
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "user_cards_delete" ON user_cards
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- user_card_status: 본인 카드 상태만
ALTER TABLE user_card_status ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_card_status_select" ON user_card_status
  FOR SELECT TO authenticated
  USING (
    user_card_id IN (SELECT id FROM user_cards WHERE user_id = auth.uid())
  );
CREATE POLICY "user_card_status_insert" ON user_card_status
  FOR INSERT TO authenticated
  WITH CHECK (
    user_card_id IN (SELECT id FROM user_cards WHERE user_id = auth.uid())
  );
CREATE POLICY "user_card_status_update" ON user_card_status
  FOR UPDATE TO authenticated
  USING (
    user_card_id IN (SELECT id FROM user_cards WHERE user_id = auth.uid())
  );

-- transactions: 본인 데이터만
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "transactions_select" ON transactions
  FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE POLICY "transactions_insert" ON transactions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);
CREATE POLICY "transactions_delete" ON transactions
  FOR DELETE TO authenticated USING (auth.uid() = user_id);

-- ============================================
-- SECTION 4: 뷰 (카드 혜택 조회용)
-- ============================================

CREATE OR REPLACE VIEW public.card_benefit_catalog AS
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
  ctr.priority
FROM card_master cm
JOIN card_benefit_tiers cbt ON cbt.card_id = cm.id
JOIN card_tier_rules ctr ON ctr.tier_id = cbt.id;

-- ============================================
-- SECTION 5: 함수
-- ============================================

-- 5-1. 카드 혜택 검색 함수
CREATE OR REPLACE FUNCTION public.search_cards_by_benefit(
  p_category TEXT DEFAULT NULL
)
RETURNS TABLE (
  card_id UUID,
  card_name TEXT,
  issuer TEXT,
  annual_fee INTEGER,
  image_color TEXT,
  description TEXT,
  monthly_benefit_cap INTEGER,
  tier_name TEXT,
  min_prev_spend INTEGER,
  max_prev_spend INTEGER,
  tier_order INTEGER,
  category TEXT,
  benefit_type TEXT,
  benefit_rate NUMERIC(5,2),
  max_benefit_amount INTEGER,
  priority INTEGER
)
LANGUAGE SQL
STABLE
AS $$
  SELECT
    c.card_id,
    c.card_name,
    c.issuer,
    c.annual_fee,
    c.image_color,
    c.description,
    c.monthly_benefit_cap,
    c.tier_name,
    c.min_prev_spend,
    c.max_prev_spend,
    c.tier_order,
    c.category,
    c.benefit_type,
    c.benefit_rate,
    c.max_benefit_amount,
    c.priority
  FROM public.card_benefit_catalog c
  WHERE p_category IS NULL
     OR c.category = p_category
  ORDER BY
    c.benefit_rate DESC,
    c.annual_fee ASC,
    c.card_name ASC,
    c.tier_order ASC,
    c.priority ASC;
$$;

-- 5-2. 입력값 정규화 함수 (숫자)
CREATE OR REPLACE FUNCTION public.safe_to_int(
  p_text TEXT,
  p_default INTEGER DEFAULT 0
)
RETURNS INTEGER
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_clean TEXT;
BEGIN
  v_clean := regexp_replace(COALESCE(p_text, ''), '[^0-9\-]', '', 'g');
  IF v_clean = '' OR v_clean = '-' THEN
    RETURN p_default;
  END IF;
  RETURN v_clean::INTEGER;
EXCEPTION
  WHEN OTHERS THEN
    RETURN p_default;
END $$;

CREATE OR REPLACE FUNCTION public.safe_to_numeric(
  p_text TEXT,
  p_default NUMERIC DEFAULT 0
)
RETURNS NUMERIC
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_clean TEXT;
BEGIN
  v_clean := regexp_replace(COALESCE(p_text, ''), '[^0-9\.\-]', '', 'g');
  IF v_clean = '' OR v_clean = '-' OR v_clean = '.' THEN
    RETURN p_default;
  END IF;
  RETURN v_clean::NUMERIC;
EXCEPTION
  WHEN OTHERS THEN
    RETURN p_default;
END $$;

-- 5-3. 카테고리 정규화 함수
CREATE OR REPLACE FUNCTION public.normalize_import_category(p_raw TEXT)
RETURNS TEXT
LANGUAGE SQL
IMMUTABLE
AS $$
  SELECT CASE LOWER(TRIM(COALESCE(p_raw, '')))
    WHEN '외식' THEN '외식'
    WHEN '식비' THEN '외식'
    WHEN '푸드' THEN '외식'
    WHEN 'food' THEN '외식'
    WHEN 'restaurant' THEN '외식'
    WHEN '카페' THEN '카페'
    WHEN '커피' THEN '카페'
    WHEN 'cafe' THEN '카페'
    WHEN 'coffee' THEN '카페'
    WHEN '교통' THEN '교통'
    WHEN '대중교통' THEN '교통'
    WHEN 'transport' THEN '교통'
    WHEN 'transit' THEN '교통'
    WHEN '생활' THEN '생활'
    WHEN '통신' THEN '생활'
    WHEN '공과금' THEN '생활'
    WHEN 'life' THEN '생활'
    WHEN 'utility' THEN '생활'
    WHEN '디지털구독' THEN '디지털구독'
    WHEN '구독' THEN '디지털구독'
    WHEN 'ott' THEN '디지털구독'
    WHEN 'subscription' THEN '디지털구독'
    WHEN 'streaming' THEN '디지털구독'
    WHEN '쇼핑' THEN '쇼핑'
    WHEN 'shopping' THEN '쇼핑'
    WHEN 'store' THEN '쇼핑'
    WHEN '편의점' THEN '편의점'
    WHEN 'convenience' THEN '편의점'
    WHEN 'conveniencestore' THEN '편의점'
    WHEN '온라인쇼핑' THEN '온라인쇼핑'
    WHEN 'online' THEN '온라인쇼핑'
    WHEN 'online_shopping' THEN '온라인쇼핑'
    WHEN '마트' THEN '마트'
    WHEN 'mart' THEN '마트'
    WHEN 'grocery' THEN '마트'
    WHEN '전통시장' THEN '전통시장'
    WHEN '시장' THEN '전통시장'
    WHEN 'traditional' THEN '전통시장'
    WHEN '해외' THEN '해외'
    WHEN '해외결제' THEN '해외'
    WHEN 'overseas' THEN '해외'
    WHEN 'foreign' THEN '해외'
    WHEN '무이자할부' THEN '무이자할부'
    WHEN '할부' THEN '무이자할부'
    WHEN 'installment' THEN '무이자할부'
    WHEN '주유' THEN '주유'
    WHEN '기름' THEN '주유'
    WHEN 'gas' THEN '주유'
    WHEN '문화' THEN '문화'
    WHEN '영화' THEN '문화'
    WHEN 'culture' THEN '문화'
    WHEN 'movie' THEN '문화'
    WHEN '배달앱' THEN '배달앱'
    WHEN '배달' THEN '배달앱'
    WHEN 'delivery' THEN '배달앱'
    WHEN '기타' THEN '기타'
    WHEN 'etc' THEN '기타'
    WHEN 'other' THEN '기타'
    ELSE COALESCE(NULLIF(TRIM(p_raw), ''), '기타')
  END;
$$;

-- 5-4. 카드 일괄 등록/업데이트 함수 (JSON)
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
  v_monthly_cap INTEGER;
  v_base_rate NUMERIC(5,2);
  v_base_type TEXT;
  v_description TEXT;
  v_image_color TEXT;

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

    INSERT INTO card_master (
      card_name, issuer, annual_fee, image_color,
      monthly_benefit_cap, base_benefit_rate, base_benefit_type, description
    )
    VALUES (
      v_card_name, v_issuer, v_annual_fee, v_image_color,
      v_monthly_cap, v_base_rate, v_base_type, v_description
    )
    ON CONFLICT (card_name, issuer) DO UPDATE
    SET
      annual_fee = EXCLUDED.annual_fee,
      image_color = EXCLUDED.image_color,
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

-- ============================================
-- SECTION 6: 권한 부여
-- ============================================

GRANT SELECT ON public.card_benefit_catalog TO authenticated;
GRANT EXECUTE ON FUNCTION public.search_cards_by_benefit(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.upsert_cards_from_json(JSONB) TO authenticated;

-- ============================================
-- 완료!
-- ============================================
-- 이제 Supabase SQL Editor에서 이 파일을 실행하면
-- 전체 데이터베이스 구조가 생성됩니다.
--
-- 다음 단계:
-- 1. 004_seed_card_data.sql 실행 (샘플 카드 데이터)
-- 2. AdminCardAddScreen에서 카드 추가
-- 3. 또는 AdminCardWebImportScreen에서 JSON 대량 등록
-- ============================================
