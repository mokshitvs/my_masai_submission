# SQL Answers
> Dataset: `cleaned_transactions.csv` (30 rows, 17 columns) produced in Part 1.  
> SQL dialect assumed: SQLite / standard ANSI SQL.

---

## Q1
### Query
```sql
SELECT
    status,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS pct_of_total
FROM cleaned_transactions
GROUP BY status
ORDER BY transaction_count DESC;
```
### Result Summary
| status     | transaction_count | pct_of_total |
|------------|:-----------------:|:------------:|
| captured   | 19                | 63.33 %      |
| failed     | 7                 | 23.33 %      |
| chargeback | 4                 | 13.33 %      |

63 % of transactions are successfully captured. 23 % fail at the gateway, and 13 % result in chargebacks – an elevated rate that warrants investigation.

---

## Q2
### Query
```sql
SELECT
    merchant_id,
    merchant_name,
    ROUND(SUM(CASE WHEN status = 'captured' THEN amount_usd ELSE 0 END), 2) AS captured_gmv_usd,
    COUNT(CASE WHEN status = 'captured' THEN 1 END) AS captured_count
FROM cleaned_transactions
GROUP BY merchant_id, merchant_name
ORDER BY captured_gmv_usd DESC;
```
### Result Summary
| merchant_id | merchant_name | captured_gmv_usd | captured_count |
|-------------|---------------|:----------------:|:--------------:|
| M002        | Beta Stores   | 33,431.00        | 7              |
| M001        | Alpha Mart    | 29,984.50        | 8              |
| M004        | Delta Travels | 10,300.00        | 2              |
| M003        | City Pharma   | 8,640.00         | 2              |
| M005        | Eco Home      | 0.00             | 0              |

Beta Stores and Alpha Mart together account for ~77 % of all captured GMV. Eco Home has zero captured revenue (all transactions are chargebacks or failures).

---

## Q3
### Query
```sql
SELECT
    merchant_id, merchant_name, merchant_category,
    ROUND(SUM(CASE WHEN status = 'captured' THEN amount_usd ELSE 0 END), 2) AS captured_gmv_usd,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN status = 'captured' THEN 1 END) AS captured_transactions
FROM cleaned_transactions
GROUP BY merchant_id, merchant_name, merchant_category
ORDER BY captured_gmv_usd DESC
LIMIT 10;
```
### Result Summary
With only 5 merchants in the dataset, all 5 appear in the top-10. Ranking by captured GMV:

| Rank | merchant_name | merchant_category | captured_gmv_usd |
|:----:|---------------|-------------------|:----------------:|
| 1    | Beta Stores   | Electronics       | 33,431.00        |
| 2    | Alpha Mart    | Grocery           | 29,984.50        |
| 3    | Delta Travels | Travel            | 10,300.00        |
| 4    | City Pharma   | Healthcare        | 8,640.00         |
| 5    | Eco Home      | Home              | 0.00             |

---

## Q4
### Query
```sql
SELECT
    transaction_date,
    ROUND(SUM(amount_usd), 2)                                               AS daily_total_gmv_usd,
    ROUND(SUM(CASE WHEN status='captured' THEN amount_usd ELSE 0 END), 2)   AS daily_captured_gmv_usd,
    COUNT(*)                                                                 AS total_transactions,
    COUNT(CASE WHEN status='captured' THEN 1 END)                           AS successful_transactions,
    ROUND(COUNT(CASE WHEN status='captured' THEN 1 END)*100.0/COUNT(*),2)   AS success_rate_pct
FROM cleaned_transactions
GROUP BY transaction_date
ORDER BY transaction_date;
```
### Result Summary
| Date       | Total GMV (USD) | Captured GMV (USD) | Total Txns | Successful | Success Rate |
|------------|-----------------|--------------------|:----------:|:----------:|:------------:|
| 2026-03-01 | 26,382.00       | 26,382.00          | 5          | 5          | 100.00 %     |
| 2026-03-02 | 25,049.00       | 11,080.00          | 6          | 3          | 50.00 %      |
| 2026-03-03 | 18,391.00       | 16,031.50          | 5          | 4          | 80.00 %      |
| 2026-03-04 | 16,420.00       | 13,920.00          | 5          | 4          | 80.00 %      |
| 2026-03-05 | 19,232.00       | 6,136.00           | 6          | 1          | 16.67 %      |
| 2026-03-06 | 10,606.00       | 8,806.00           | 3          | 2          | 66.67 %      |

Notable spike in failures on 2026-03-05 — success rate collapsed to 17 % (4 failures + 1 chargeback in 6 transactions).

---

## Q5
### Query
```sql
SELECT
    merchant_id, merchant_name,
    COUNT(*) AS total_transactions,
    COUNT(CASE WHEN status='chargeback' THEN 1 END) AS chargeback_count,
    ROUND(COUNT(CASE WHEN status='chargeback' THEN 1 END)*100.0/COUNT(*),2) AS chargeback_ratio_pct,
    ROUND(SUM(CASE WHEN status='chargeback' THEN amount_usd ELSE 0 END),2)  AS chargeback_amount_usd
FROM cleaned_transactions
GROUP BY merchant_id, merchant_name
HAVING chargeback_ratio_pct > 1
ORDER BY chargeback_ratio_pct DESC;
```
### Result Summary
| merchant_name | total_txns | cb_count | cb_ratio | cb_amount (USD) |
|---------------|:----------:|:--------:|:--------:|:---------------:|
| Eco Home      | 2          | 1        | 50.00 %  | 6,649.00        |
| Delta Travels | 4          | 1        | 25.00 %  | 2,500.00        |
| Alpha Mart    | 11         | 1        | 9.09 %   | 5,400.00        |
| Beta Stores   | 11         | 1        | 9.09 %   | 1,711.00        |

All 5 merchants exceed the 1 % threshold. Eco Home (50 %) and Delta Travels (25 %) are critical risk merchants. City Pharma is the only clean merchant with 0 chargebacks.

---

## Q6
### Query
```sql
SELECT
    gateway_region,
    COUNT(*) AS transaction_count,
    ROUND(AVG(risk_score), 2) AS avg_risk_score,
    ROUND(SUM(amount_usd), 2) AS total_gmv_usd
FROM cleaned_transactions
WHERE risk_score IS NOT NULL
GROUP BY gateway_region
HAVING avg_risk_score > 50 AND COUNT(*) > 20
ORDER BY avg_risk_score DESC;
```
### Result Summary
| gateway_region | transaction_count | avg_risk_score | total_gmv_usd |
|----------------|:-----------------:|:--------------:|:-------------:|
| APAC           | 21                | 65.48          | 80,234.50     |

Only APAC satisfies both conditions (avg risk 65.48, 21+ transactions). EU (4 txns) and US (4 txns) do not cross the 20-transaction threshold.

---

## Q7
### Query
```sql
SELECT
    user_id, transaction_date,
    COUNT(*) AS fail_or_chargeback_count,
    COUNT(CASE WHEN status='failed' THEN 1 END)     AS failed_count,
    COUNT(CASE WHEN status='chargeback' THEN 1 END) AS chargeback_count
FROM cleaned_transactions
WHERE status IN ('failed', 'chargeback')
GROUP BY user_id, transaction_date
HAVING COUNT(*) >= 3
ORDER BY fail_or_chargeback_count DESC, transaction_date;
```
### Result Summary
| user_id | transaction_date | fail_or_cb_count | failed | chargeback |
|---------|-----------------|:----------------:|:------:|:----------:|
| U008    | 2026-03-05      | 4                | 3      | 1          |

User **U008** is the only flagged user — 4 distress events on a single day (3 failed + 1 chargeback across T016, T017, T018, T019). This pattern is a strong fraud or card-testing signal and should be escalated for account review.

---

## Q8
### Query
```sql
SELECT
    ct.merchant_id, ct.merchant_name,
    COUNT(*)                       AS chargeback_count,
    COUNT(DISTINCT ct.user_id)     AS unique_affected_users,
    ROUND(SUM(ct.amount_usd), 2)   AS chargeback_amount_usd
FROM cleaned_transactions ct
WHERE ct.status = 'chargeback'
GROUP BY ct.merchant_id, ct.merchant_name
ORDER BY chargeback_amount_usd DESC;
```
### Result Summary
| merchant_name | chargeback_count | unique_affected_users | chargeback_amount_usd |
|---------------|:----------------:|:--------------------:|:---------------------:|
| Eco Home      | 1                | 1                    | 6,649.00              |
| Alpha Mart    | 1                | 1                    | 5,400.00              |
| Delta Travels | 1                | 1                    | 2,500.00              |
| Beta Stores   | 1                | 1                    | 1,711.00              |

Total chargeback exposure: **USD 16,260.00** across 4 unique users. Eco Home carries the single highest chargeback amount at USD 6,649. City Pharma is the only merchant with zero chargebacks.
