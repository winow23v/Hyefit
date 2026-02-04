-- ============================================
-- 혜핏(HyeFit) MVP 데이터베이스 스키마
-- Supabase 대시보드 > SQL Editor에서 실행
-- ============================================

-- 1. 카드 마스터
CREATE TABLE IF NOT EXISTS card_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_name TEXT NOT NULL,
  issuer TEXT NOT NULL,
  annual_fee INTEGER NOT NULL DEFAULT 0,
  image_color TEXT DEFAULT '#7C83FD',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. 카드 혜택 기준
CREATE TABLE IF NOT EXISTS card_benefit_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id UUID NOT NULL REFERENCES card_master(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  min_monthly_spend INTEGER NOT NULL DEFAULT 0,
  benefit_type TEXT NOT NULL DEFAULT 'cashback',
  benefit_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  max_benefit_amount INTEGER NOT NULL DEFAULT 0,
  start_day INTEGER NOT NULL DEFAULT 1,
  end_day INTEGER NOT NULL DEFAULT 31,
  priority INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. 혜택 구간 기준
CREATE TABLE IF NOT EXISTS card_benefit_thresholds (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  benefit_rule_id UUID NOT NULL REFERENCES card_benefit_rules(id) ON DELETE CASCADE,
  min_spend_amount INTEGER NOT NULL DEFAULT 0,
  max_spend_amount INTEGER,
  benefit_rate NUMERIC(5,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. 사용자 카드 보유 정보
CREATE TABLE IF NOT EXISTS user_cards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  card_master_id UUID NOT NULL REFERENCES card_master(id) ON DELETE CASCADE,
  nickname TEXT,
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
-- 인덱스
-- ============================================
CREATE INDEX IF NOT EXISTS idx_card_benefit_rules_card_id ON card_benefit_rules(card_id);
CREATE INDEX IF NOT EXISTS idx_card_benefit_thresholds_rule_id ON card_benefit_thresholds(benefit_rule_id);
CREATE INDEX IF NOT EXISTS idx_user_cards_user_id ON user_cards(user_id);
CREATE INDEX IF NOT EXISTS idx_user_card_status_card_id ON user_card_status(user_card_id);
CREATE INDEX IF NOT EXISTS idx_transactions_user_id ON transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(transaction_date);

-- ============================================
-- RLS 정책
-- ============================================

-- card_master: 인증된 사용자 읽기 전용
ALTER TABLE card_master ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_master_select" ON card_master
  FOR SELECT TO authenticated USING (true);

-- card_benefit_rules: 인증된 사용자 읽기 전용
ALTER TABLE card_benefit_rules ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_benefit_rules_select" ON card_benefit_rules
  FOR SELECT TO authenticated USING (true);

-- card_benefit_thresholds: 인증된 사용자 읽기 전용
ALTER TABLE card_benefit_thresholds ENABLE ROW LEVEL SECURITY;
CREATE POLICY "card_benefit_thresholds_select" ON card_benefit_thresholds
  FOR SELECT TO authenticated USING (true);

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
-- 샘플 카드 데이터 (시드)
-- ============================================

-- 신한 Deep Dream
INSERT INTO card_master (id, card_name, issuer, annual_fee, image_color)
VALUES (
  'a1b2c3d4-0001-4000-8000-000000000001',
  '신한 Deep Dream',
  '신한카드',
  12000,
  '#2563EB'
);

INSERT INTO card_benefit_rules (id, card_id, category, min_monthly_spend, benefit_type, benefit_rate, max_benefit_amount, priority)
VALUES
  ('b1b2c3d4-0001-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', '외식', 300000, 'cashback', 10.00, 10000, 1),
  ('b1b2c3d4-0002-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', '교통', 300000, 'cashback', 10.00, 10000, 2),
  ('b1b2c3d4-0003-4000-8000-000000000001', 'a1b2c3d4-0001-4000-8000-000000000001', '편의점', 300000, 'cashback', 10.00, 5000, 3);

INSERT INTO card_benefit_thresholds (benefit_rule_id, min_spend_amount, max_spend_amount, benefit_rate)
VALUES
  ('b1b2c3d4-0001-4000-8000-000000000001', 300000, 500000, 5.00),
  ('b1b2c3d4-0001-4000-8000-000000000001', 500000, NULL, 10.00);

-- KB 국민 My WE:SH
INSERT INTO card_master (id, card_name, issuer, annual_fee, image_color)
VALUES (
  'a1b2c3d4-0002-4000-8000-000000000001',
  'KB 국민 My WE:SH',
  'KB국민카드',
  15000,
  '#DC2626'
);

INSERT INTO card_benefit_rules (id, card_id, category, min_monthly_spend, benefit_type, benefit_rate, max_benefit_amount, priority)
VALUES
  ('b1b2c3d4-0004-4000-8000-000000000001', 'a1b2c3d4-0002-4000-8000-000000000001', '쇼핑', 400000, 'point', 5.00, 15000, 1),
  ('b1b2c3d4-0005-4000-8000-000000000001', 'a1b2c3d4-0002-4000-8000-000000000001', '마트', 400000, 'cashback', 5.00, 10000, 2),
  ('b1b2c3d4-0006-4000-8000-000000000001', 'a1b2c3d4-0002-4000-8000-000000000001', '외식', 400000, 'cashback', 3.00, 8000, 3);

INSERT INTO card_benefit_thresholds (benefit_rule_id, min_spend_amount, max_spend_amount, benefit_rate)
VALUES
  ('b1b2c3d4-0004-4000-8000-000000000001', 400000, 700000, 3.00),
  ('b1b2c3d4-0004-4000-8000-000000000001', 700000, NULL, 5.00);

-- 삼성 taptap O
INSERT INTO card_master (id, card_name, issuer, annual_fee, image_color)
VALUES (
  'a1b2c3d4-0003-4000-8000-000000000001',
  '삼성 taptap O',
  '삼성카드',
  10000,
  '#7C3AED'
);

INSERT INTO card_benefit_rules (id, card_id, category, min_monthly_spend, benefit_type, benefit_rate, max_benefit_amount, priority)
VALUES
  ('b1b2c3d4-0007-4000-8000-000000000001', 'a1b2c3d4-0003-4000-8000-000000000001', '온라인쇼핑', 300000, 'cashback', 5.00, 10000, 1),
  ('b1b2c3d4-0008-4000-8000-000000000001', 'a1b2c3d4-0003-4000-8000-000000000001', '교통', 300000, 'cashback', 10.00, 5000, 2);

INSERT INTO card_benefit_thresholds (benefit_rule_id, min_spend_amount, max_spend_amount, benefit_rate)
VALUES
  ('b1b2c3d4-0007-4000-8000-000000000001', 300000, 600000, 3.00),
  ('b1b2c3d4-0007-4000-8000-000000000001', 600000, NULL, 5.00);
