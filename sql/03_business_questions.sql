-- =====================================================================
-- 03_business_questions.sql
-- Bank Loan & Card Analytics — Business Question Queries (PostgreSQL)
-- =====================================================================
-- Organized to mirror the Business Requirement Document:
--   SECTION A — BRD1: Core loan KPIs
--   SECTION B — BRD1: Good Loan vs Bad Loan KPIs
--   SECTION C — BRD2: Visualization-support queries (trend/segment)
--   SECTION D — Credit & Debit Card business questions (extension)
--   SECTION E — Cross-product risk & customer value questions
-- =====================================================================


-- =====================================================================
-- SECTION A — Core Loan KPIs
-- =====================================================================

-- A1. Total Loan Applications & MTD (Month-to-Date, most recent month in the data)
SELECT COUNT(*) AS total_applications
FROM loans;

SELECT COUNT(*) AS mtd_applications
FROM loans
WHERE date_trunc('month', issue_date) = (SELECT date_trunc('month', MAX(issue_date)) FROM loans);

-- A2. Total Funded Amount & MTD
SELECT ROUND(SUM(funded_amount), 2) AS total_funded_amount
FROM loans;

SELECT ROUND(SUM(funded_amount), 2) AS mtd_funded_amount
FROM loans
WHERE date_trunc('month', issue_date) = (SELECT date_trunc('month', MAX(issue_date)) FROM loans);

-- A3. Total Amount Received & MTD
SELECT ROUND(SUM(total_payment), 2) AS total_amount_received
FROM loans;

SELECT ROUND(SUM(total_payment), 2) AS mtd_amount_received
FROM loans
WHERE date_trunc('month', issue_date) = (SELECT date_trunc('month', MAX(issue_date)) FROM loans);

-- A4. Average Interest Rate (overall, and by month for trend)
SELECT ROUND(AVG(int_rate) * 100, 2) AS avg_interest_rate_pct
FROM loans;

-- A5. Average Debt-to-Income Ratio (DTI)
SELECT ROUND(AVG(dti) * 100, 2) AS avg_dti_pct
FROM loans;

-- A6. One-shot KPI summary row (useful for a dashboard header / scorecard)
SELECT
    COUNT(*)                                    AS total_applications,
    ROUND(SUM(funded_amount), 2)                AS total_funded_amount,
    ROUND(SUM(total_payment), 2)                AS total_amount_received,
    ROUND(AVG(int_rate) * 100, 2)                AS avg_interest_rate_pct,
    ROUND(AVG(dti) * 100, 2)                     AS avg_dti_pct
FROM loans;


-- =====================================================================
-- SECTION B — Good Loan vs Bad Loan KPIs
-- Good Loan  = loan_status IN ('Fully Paid','Current')  (performing)
-- Bad Loan   = loan_status = 'Charged Off'              (defaulted)
-- =====================================================================

-- B1. Good vs Bad loan application % and counts
SELECT
    CASE WHEN loan_status IN ('Fully Paid','Current') THEN 'Good Loan' ELSE 'Bad Loan' END AS loan_bucket,
    COUNT(*) AS num_applications,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_applications
FROM loans
GROUP BY 1;

-- B2. Good vs Bad — funded amount and amount received
SELECT
    CASE WHEN loan_status IN ('Fully Paid','Current') THEN 'Good Loan' ELSE 'Bad Loan' END AS loan_bucket,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount,
    ROUND(SUM(total_payment), 2) AS total_amount_received,
    ROUND(SUM(total_payment) - SUM(funded_amount), 2) AS net_gain_loss
FROM loans
GROUP BY 1;

-- B3. Charge-off rate by credit grade (A best -> G worst) — underwriting quality check
SELECT
    grade,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS charged_off,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS charge_off_rate_pct,
    ROUND(AVG(int_rate) * 100, 2) AS avg_int_rate_pct
FROM loans
GROUP BY grade
ORDER BY grade;


-- =====================================================================
-- SECTION C — Visualization-support queries (BRD2)
-- =====================================================================

-- C1. Monthly trend of applications, funded amount, amount received (line/area chart)
SELECT
    date_trunc('month', issue_date)::date AS issue_month,
    COUNT(*)                              AS applications,
    ROUND(SUM(funded_amount), 2)          AS funded_amount,
    ROUND(SUM(total_payment), 2)          AS amount_received
FROM loans
GROUP BY 1
ORDER BY 1;

-- C2. Regional analysis by state (bar chart) — top 15 states by funded amount
SELECT
    address_state,
    COUNT(*) AS applications,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount,
    ROUND(AVG(int_rate) * 100, 2) AS avg_int_rate_pct,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS charge_off_rate_pct
FROM loans
GROUP BY address_state
ORDER BY total_funded_amount DESC
LIMIT 15;

-- C3. Loan term analysis (donut chart) — 36 vs 60 months
SELECT
    term_months,
    COUNT(*) AS applications,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_applications,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount
FROM loans
GROUP BY term_months
ORDER BY term_months;

-- C4. Employment length analysis (bar chart)
SELECT
    emp_length,
    COUNT(*) AS applications,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS charge_off_rate_pct
FROM loans
GROUP BY emp_length
ORDER BY
    CASE emp_length
        WHEN '< 1 year' THEN 0 WHEN '1 year' THEN 1 WHEN '2 years' THEN 2
        WHEN '3 years' THEN 3 WHEN '4 years' THEN 4 WHEN '5 years' THEN 5
        WHEN '6 years' THEN 6 WHEN '7 years' THEN 7 WHEN '8 years' THEN 8
        WHEN '9 years' THEN 9 ELSE 10 END;

-- C5. Loan purpose breakdown (bar chart)
SELECT
    purpose,
    COUNT(*) AS applications,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_applications
FROM loans
GROUP BY purpose
ORDER BY total_funded_amount DESC;

-- C6. Home ownership analysis (treemap / heatmap)
SELECT
    home_ownership,
    COUNT(*) AS applications,
    ROUND(SUM(funded_amount), 2) AS total_funded_amount,
    ROUND(SUM(total_payment), 2) AS total_amount_received,
    ROUND(100.0 * SUM(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) / COUNT(*), 2) AS charge_off_rate_pct
FROM loans
GROUP BY home_ownership
ORDER BY total_funded_amount DESC;


-- =====================================================================
-- SECTION D — Credit & Debit Card Business Questions
-- =====================================================================

-- D1. Total spend, transaction count, and average ticket by card type
SELECT
    card_type,
    COUNT(*) AS num_transactions,
    ROUND(SUM(amount), 2) AS total_spend,
    ROUND(AVG(amount), 2) AS avg_transaction_amount
FROM card_transactions
WHERE transaction_type = 'PURCHASE'
GROUP BY card_type;

-- D2. Monthly spend trend by card type (seasonality)
SELECT
    date_trunc('month', transaction_date)::date AS txn_month,
    card_type,
    ROUND(SUM(amount), 2) AS total_spend,
    COUNT(*) AS num_transactions
FROM card_transactions
WHERE transaction_type = 'PURCHASE'
GROUP BY 1, 2
ORDER BY 1, 2;

-- D3. Top merchant categories by spend (where the money goes)
SELECT
    merchant_category,
    COUNT(*) AS num_transactions,
    ROUND(SUM(amount), 2) AS total_spend,
    ROUND(AVG(amount), 2) AS avg_transaction_amount
FROM card_transactions
WHERE transaction_type = 'PURCHASE'
GROUP BY merchant_category
ORDER BY total_spend DESC;

-- D4. Fraud analysis: fraud rate and $ exposure by channel and card type
SELECT
    card_type,
    channel,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct,
    ROUND(SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END), 2) AS fraud_dollar_exposure
FROM card_transactions
GROUP BY card_type, channel
ORDER BY fraud_rate_pct DESC;

-- D5. Fraud by state — where fraud is concentrated geographically
SELECT
    state,
    COUNT(*) AS total_transactions,
    SUM(is_fraud) AS fraud_transactions,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct
FROM card_transactions
GROUP BY state
ORDER BY fraud_rate_pct DESC
LIMIT 15;

-- D6. Credit vs Debit usage by merchant category (behavioral difference)
SELECT
    merchant_category,
    card_type,
    COUNT(*) AS num_transactions,
    ROUND(SUM(amount), 2) AS total_spend
FROM card_transactions
WHERE transaction_type = 'PURCHASE'
GROUP BY merchant_category, card_type
ORDER BY merchant_category, card_type;

-- D7. Online vs in-person (POS) channel mix and average ticket size
SELECT
    channel,
    COUNT(*) AS num_transactions,
    ROUND(SUM(amount), 2) AS total_spend,
    ROUND(AVG(amount), 2) AS avg_transaction_amount,
    ROUND(100.0 * SUM(is_fraud) / COUNT(*), 3) AS fraud_rate_pct
FROM card_transactions
GROUP BY channel
ORDER BY total_spend DESC;

-- D8. Top 20 customers by total card spend (high-value customer identification)
SELECT
    t.customer_id,
    c.first_name, c.last_name, c.address_state, c.credit_score,
    COUNT(*) AS num_transactions,
    ROUND(SUM(t.amount), 2) AS total_spend
FROM card_transactions t
JOIN customers c ON c.customer_id = t.customer_id
WHERE t.transaction_type = 'PURCHASE'
GROUP BY t.customer_id, c.first_name, c.last_name, c.address_state, c.credit_score
ORDER BY total_spend DESC
LIMIT 20;


-- =====================================================================
-- SECTION E — Cross-Product Risk & Customer Value Questions
-- =====================================================================

-- E1. Do customers who carry a charged-off loan also show higher card fraud rates?
-- (tests whether credit risk and fraud risk correlate in this portfolio)
WITH loan_risk AS (
    SELECT customer_id,
           MAX(CASE WHEN loan_status = 'Charged Off' THEN 1 ELSE 0 END) AS has_charge_off
    FROM loans
    GROUP BY customer_id
)
SELECT
    lr.has_charge_off,
    COUNT(*) AS total_transactions,
    ROUND(100.0 * SUM(t.is_fraud) / COUNT(*), 3) AS fraud_rate_pct
FROM card_transactions t
JOIN loan_risk lr ON lr.customer_id = t.customer_id
GROUP BY lr.has_charge_off;

-- E2. Customer 360 view: combined loan exposure + card spend, ranked by total relationship value
SELECT
    c.customer_id, c.first_name, c.last_name, c.address_state, c.credit_score,
    COALESCE(l.total_funded, 0)        AS total_loan_funded,
    COALESCE(l.total_loan_payment, 0)  AS total_loan_repaid,
    COALESCE(t.total_card_spend, 0)    AS total_card_spend,
    COALESCE(l.total_funded, 0) + COALESCE(t.total_card_spend, 0) AS total_relationship_value
FROM customers c
LEFT JOIN (
    SELECT customer_id, SUM(funded_amount) AS total_funded, SUM(total_payment) AS total_loan_payment
    FROM loans GROUP BY customer_id
) l ON l.customer_id = c.customer_id
LEFT JOIN (
    SELECT customer_id, SUM(amount) AS total_card_spend
    FROM card_transactions WHERE transaction_type = 'PURCHASE' GROUP BY customer_id
) t ON t.customer_id = c.customer_id
ORDER BY total_relationship_value DESC
LIMIT 25;

-- E3. Credit-score band vs loan charge-off rate AND card fraud rate (single risk view)
WITH bands AS (
    SELECT customer_id,
        CASE
            WHEN credit_score < 580 THEN '1. Poor (<580)'
            WHEN credit_score < 670 THEN '2. Fair (580-669)'
            WHEN credit_score < 740 THEN '3. Good (670-739)'
            WHEN credit_score < 800 THEN '4. Very Good (740-799)'
            ELSE '5. Exceptional (800+)'
        END AS score_band
    FROM customers
)
SELECT
    b.score_band,
    ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'Charged Off' THEN 1 ELSE 0 END)
          / NULLIF(COUNT(l.loan_id), 0), 2) AS loan_charge_off_rate_pct,
    ROUND(100.0 * SUM(t.is_fraud) / NULLIF(COUNT(t.transaction_id), 0), 3) AS card_fraud_rate_pct
FROM bands b
LEFT JOIN loans l ON l.customer_id = b.customer_id
LEFT JOIN card_transactions t ON t.customer_id = b.customer_id
GROUP BY b.score_band
ORDER BY b.score_band;
