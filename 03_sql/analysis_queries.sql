-- QuickPay FinTech Operations – SQL Business Analysis
-- All queries written against: cleaned_transactions (ct), merchant_master (mm), users (u)
-- Table alias convention:
--   cleaned_transactions → ct
--   merchant_master      → mm
--   users                → u

-- ─────────────────────────────────────────────────────────────────
-- Q1: Count transactions by status
-- ─────────────────────────────────────────────────────────────────
-- Q1
SELECT
    status,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;

-- ─────────────────────────────────────────────────────────────────
-- Q2: Calculate total captured GMV by merchant
-- ─────────────────────────────────────────────────────────────────
-- Q2
SELECT
    ct.merchant_id,
    ct.merchant_name,
    ROUND(SUM(CASE WHEN ct.status = 'captured' THEN ct.amount_usd ELSE 0 END), 2) AS captured_gmv_usd,
    COUNT(CASE WHEN ct.status = 'captured' THEN 1 END) AS captured_count
FROM cleaned_transactions ct
GROUP BY ct.merchant_id, ct.merchant_name
ORDER BY captured_gmv_usd DESC;

-- ─────────────────────────────────────────────────────────────────
-- Q3: Top 10 merchants by captured GMV
-- ─────────────────────────────────────────────────────────────────
-- Q3
SELECT
    ct.merchant_id,
    ct.merchant_name,
    ct.merchant_category,
    ROUND(SUM(CASE WHEN ct.status = 'captured' THEN ct.amount_usd ELSE 0 END), 2) AS captured_gmv_usd,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN ct.status = 'captured' THEN 1 END) AS captured_transactions
FROM cleaned_transactions ct
GROUP BY ct.merchant_id, ct.merchant_name, ct.merchant_category
ORDER BY captured_gmv_usd DESC
LIMIT 10;

-- ─────────────────────────────────────────────────────────────────
-- Q4: Daily GMV and successful transaction count
-- ─────────────────────────────────────────────────────────────────
-- Q4
SELECT
    transaction_date,
    ROUND(SUM(amount_usd), 2)                                        AS daily_total_gmv_usd,
    ROUND(SUM(CASE WHEN status = 'captured' THEN amount_usd ELSE 0 END), 2) AS daily_captured_gmv_usd,
    COUNT(*)                                                          AS total_transactions,
    COUNT(CASE WHEN status = 'captured' THEN 1 END)                  AS successful_transactions,
    ROUND(
        COUNT(CASE WHEN status = 'captured' THEN 1 END) * 100.0 / COUNT(*),
        2
    )                                                                 AS success_rate_pct
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date;

-- ─────────────────────────────────────────────────────────────────
-- Q5: Merchants with chargeback ratio above 1%
-- ─────────────────────────────────────────────────────────────────
-- Q5
SELECT
    merchant_id,
    merchant_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN status = 'chargeback' THEN 1 END) AS chargeback_count,
    ROUND(
        COUNT(CASE WHEN status = 'chargeback' THEN 1 END) * 100.0 / COUNT(*),
        2
    ) AS chargeback_ratio_pct,
    ROUND(SUM(CASE WHEN status = 'chargeback' THEN amount_usd ELSE 0 END), 2) AS chargeback_amount_usd
FROM cleaned_transactions
GROUP BY merchant_id, merchant_name
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;

-- ─────────────────────────────────────────────────────────────────
-- Q6: Regions with average risk score above 50 and more than 20 transactions
-- ─────────────────────────────────────────────────────────────────
-- Q6
SELECT
    gateway_region,
    COUNT(*) AS transaction_count,
    ROUND(AVG(risk_score), 2) AS avg_risk_score,
    ROUND(SUM(amount_usd), 2) AS total_gmv_usd
FROM cleaned_transactions
WHERE risk_score IS NOT NULL
GROUP BY gateway_region
HAVING avg_risk_score > 50
   AND COUNT(*) > 20
ORDER BY avg_risk_score DESC;

-- ─────────────────────────────────────────────────────────────────
-- Q7: Users with 3 or more failed or chargeback transactions on the same day
-- ─────────────────────────────────────────────────────────────────
-- Q7
SELECT
    user_id,
    transaction_date,
    COUNT(*) AS fail_or_chargeback_count,
    COUNT(CASE WHEN status = 'failed' THEN 1 END)     AS failed_count,
    COUNT(CASE WHEN status = 'chargeback' THEN 1 END) AS chargeback_count
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY fail_or_chargeback_count DESC, transaction_date;

-- ─────────────────────────────────────────────────────────────────
-- Q8: Chargeback count, unique affected users, and chargeback amount by merchant
-- ─────────────────────────────────────────────────────────────────
-- Q8
SELECT
    ct.merchant_id,
    ct.merchant_name,
    COUNT(*)                                                 AS chargeback_count,
    COUNT(DISTINCT ct.user_id)                               AS unique_affected_users,
    ROUND(SUM(ct.amount_usd), 2)                             AS chargeback_amount_usd,
    ROUND(SUM(ct.amount_usd) * 100.0 /
        SUM(SUM(ct.amount_usd)) OVER (), 2)                 AS pct_of_total_chargeback_usd
FROM cleaned_transactions ct
WHERE ct.status = 'chargeback'
GROUP BY ct.merchant_id, ct.merchant_name
ORDER BY chargeback_amount_usd DESC;
