

## 2. 카드 혜택 기준 테이블 구조

---

## 2.1 카드 마스터 (card_master)

> 카드 자체에 대한 고정 정보

```sql
card_master
- id (uuid)
- card_name
- issuer
- annual_fee
- created_at
```

---

## 2.2 카드 혜택 기준 (card_benefit_rules) ⭐ 핵심

> “이 카드가 언제, 어떤 조건에서, 어떤 혜택을 주는가”

```sql
card_benefit_rules
- id (uuid)
- card_id (FK → card_master.id)

- category              -- 식비 / 교통 / 쇼핑 등
- min_monthly_spend     -- 전월 실적 기준
- benefit_type          -- cashback / point
- benefit_rate          -- % or 고정 금액
- max_benefit_amount    -- 월 최대 혜택
- start_day             -- 공여기간 시작 (1)
- end_day               -- 공여기간 종료 (말일)
- priority              -- 중복 혜택 우선순위

- created_at




## 2.3 혜택 구간 기준 (card_benefit_thresholds)

> “얼마 이상 써야 혜택이 시작되는가”

sql
card_benefit_thresholds
- id
- benefit_rule_id (FK)
- min_spend_amount
- max_spend_amount
- benefit_rate


📌 **이 테이블 덕분에**

* 30만 / 50만 / 100만 구간 혜택 처리 가능
* 카드사 현실 구조 반영 가능

---

## 3. 사용자 카드 매핑 구조

---

## 3.1 사용자 카드 보유 정보 (user_cards)

sql
user_cards
- id
- user_id
- card_master_id
- nickname          -- "월급카드", "교통카드"
- created_at


---

## 3.2 사용자 카드 상태 (user_card_status)

> 공여기간 내 누적 실적 관리용

sql
user_card_status
- id
- user_card_id
- current_spend
- current_benefit
- period_start
- period_end
- updated_at


---

## 4. 소비 내역과 혜택 계산 연결

---

## 4.1 소비 테이블 (transactions) – 유지

sql
transactions
- id
- user_id
- user_card_id
- amount
- category
- transaction_date


---

## 4.2 혜택 계산 로직 (Rule Engine 개념)

### 계산 순서

1. 소비 발생
2. 해당 카드의 **benefit_rules 조회**
3. 카테고리 + 실적 조건 필터
4. thresholds 매칭
5. 최대 혜택 한도 체크
6. user_card_status 업데이트

---

### 의사 코드

text
if total_spend >= min_monthly_spend:
  apply benefit_rule
  if threshold matched:
    calculate benefit


---

## 5. MVP용 단순화 규칙 (과설계 방지)

| 항목    | MVP 정책          |
| ----- | --------------- |
| 카드 수  | 10개 내외          |
| 혜택 수  | 카드당 1~3개        |
| 중복 혜택 | priority로 단순 처리 |
| 공여기간  | 월 단위 고정         |
| 업종 분류 | 6~7개            |

---

## 6. 관리자/데이터 입력 전략 (1인 개발 현실)

### 방법 1 (초기 추천)

* Supabase Dashboard에서 직접 입력
* CSV 업로드

### 방법 2 (v1 이후)

* Admin 페이지
* 카드사 API

---

## 7. RLS 정책 보완

### 기준 테이블

sql
-- 읽기 전용
ALLOW SELECT ON card_benefit_rules TO authenticated;


### 사용자 카드

sql
auth.uid() = user_id


---

## 8. UI 반영 방식

### 대시보드 표시 예시

* ○○카드 (교통)
* 혜택까지 12,000원 남음
* 현재 혜택 예상: 8,400원

---

## 9. 이 구조의 장점 (중요)

* ✅ 카드 추가 시 코드 수정 없음
* ✅ 혜택 변경 대응 쉬움
* ✅ 사용자 입력 최소화
* ✅ 실제 카드사 구조와 유사
* ✅ “혜택 엔진”으로 확장 가능


