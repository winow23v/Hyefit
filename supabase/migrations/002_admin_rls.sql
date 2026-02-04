-- ============================================
-- Admin RLS: 인증된 사용자가 카드 마스터 + 혜택 규칙 관리 가능
-- Supabase SQL Editor에서 실행
-- ============================================

-- card_master: INSERT, DELETE 허용
CREATE POLICY "card_master_insert" ON card_master
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_master_delete" ON card_master
  FOR DELETE TO authenticated USING (true);

-- card_benefit_rules: INSERT, DELETE 허용
CREATE POLICY "card_benefit_rules_insert" ON card_benefit_rules
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_benefit_rules_delete" ON card_benefit_rules
  FOR DELETE TO authenticated USING (true);

-- card_benefit_thresholds: INSERT, DELETE 허용
CREATE POLICY "card_benefit_thresholds_insert" ON card_benefit_thresholds
  FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "card_benefit_thresholds_delete" ON card_benefit_thresholds
  FOR DELETE TO authenticated USING (true);
