# Spreadsheet Answers

---

## Cleaning Steps

1. **Loaded raw data** — `transactions_raw.csv` (30 rows × 10 columns) into Excel / Python.
2. **Removed leading/trailing whitespace** from all text columns (merchant_name, status, gateway_region, risk_score).
3. **Collapsed multi-space gaps** in merchant names (e.g., `"Alpha  Mart"` → `"Alpha Mart"`, `"Beta  Stores"` → `"Beta Stores"`).
4. **Standardized merchant name case** to Title Case using string functions (PROPER() in Excel / `.str.title()` in Python), so all variants (`"alpha mart"`, `"ALPHA MART"`, `"Alpha  Mart"`) resolve to the canonical form.
5. **Standardized status** using a lookup/IF logic:
   - Any value containing `"chargeback"` (case-insensitive) → `chargeback`
   - Any value containing `"captured"` → `captured`
   - Any value containing `"failed"` → `failed`
6. **Extracted numeric risk scores** — raw values included prefixes like `"score:62"`, `"risk-83"`. Used SUBSTITUTE / regex to strip non-numeric characters and retain the integer.
7. **Standardized gateway_region** to UPPER CASE (`apac` → `APAC`, `eu` → `EU`, `us` → `US`).
8. **Filled missing gateway_region** via VLOOKUP against `merchant_master.csv` using the cleaned merchant name as the key (joining on `default_region`). 11 of 30 rows had a missing region; all were filled from the master.
9. **Validated 1 missing risk_score** (T011) — left as blank/NULL because no numeric value could be recovered.

---

## Standardization Rules

| Field           | Raw Issue                                  | Rule Applied                                                      |
|-----------------|--------------------------------------------|-------------------------------------------------------------------|
| merchant_name   | Mixed case, extra spaces                   | TRIM + PROPER → Title Case, single-space normalization            |
| transaction_date| Already ISO 8601 (YYYY-MM-DD)              | Parsed as Date; reformatted consistently                          |
| status          | "Captured", "CAPTURED", "failed e05 timeout", etc. | Contains-logic: chargeback / captured / failed buckets      |
| risk_score      | "score:62", "risk-83", plain int, NaN      | Extract first integer group; NaN where absent                     |
| gateway_region  | Mixed case, NaN                            | UPPER; fill NaN from merchant_master.default_region               |
| currency        | Already clean (INR / EUR / USD)            | No change needed                                                  |

---

## Lookup and Enrichment Logic

### Currency Conversion to USD
- Joined `exchange_rates.csv` on `(transaction_date, currency)` to get `usd_rate`.
- `amount_usd = raw_amount × usd_rate`
- For INR: rates ranged from 0.0118–0.0121 across the date range.
- For EUR: rates ranged from 1.07–1.09.
- USD transactions: rate = 1.00 (no conversion needed).

### Merchant Enrichment
- VLOOKUP / LEFT JOIN on cleaned `merchant_name` → `merchant_master`:
  - Added: `merchant_id`, `merchant_category`, `default_region`, `account_manager`
- All 30 transactions matched to a merchant successfully.

### High-Value Flag Logic
```
high_value_flag = 1  IF  (gateway_region = "APAC"  AND amount_usd > 5,000)
                      OR  (gateway_region = "EU"    AND amount_usd > 6,000)
                      OR  (gateway_region = "US"    AND amount_usd > 7,000)
                      ELSE 0
```

### High-Risk Flag Logic
```
high_risk_flag = 1  IF  risk_score >= 70  OR  status = "chargeback"
                    ELSE 0
```

---

## Final Answers

| Metric                           | Value                              |
|----------------------------------|------------------------------------|
| Total raw rows                   | 30                                 |
| Total cleaned rows               | 30                                 |
| Invalid or missing rows handled  | 1 (T011 — missing risk_score); 11 rows with missing gateway_region (filled via lookup) |
| Top region by GMV                | **APAC** — USD 82,594.00           |
| Number of high-value transactions | **7**                             |
| Number of high-risk transactions  | **9**                             |
| Top merchant by captured GMV     | **Beta Stores** — USD 33,431.00    |

---

## Formula Samples

### Amount USD (Excel)
```excel
=VLOOKUP(B2 & "|" & F2, exchange_rates_lookup_range, 3, FALSE) * E2
```
*(where B2 = transaction_date, F2 = currency, E2 = raw_amount)*

Or using INDEX-MATCH for the two-key lookup:
```excel
=E2 * INDEX(exchange_rates[usd_rate],
            MATCH(1,
              (exchange_rates[rate_date]=B2)*(exchange_rates[currency]=F2),
              0))
```

### Risk Score Extraction (Excel)
```excel
=IFERROR(VALUE(TRIM(SUBSTITUTE(SUBSTITUTE(G2,"score:",""),"risk-",""))), "")
```

### Gateway Region Fill (Excel)
```excel
=IF(H2<>"", UPPER(H2),
    VLOOKUP(cleaned_merchant_name, merchant_master[merchant_name:default_region], 2, FALSE))
```

### High-Value Flag (Excel)
```excel
=IF(OR(
    AND(gateway_region="APAC", amount_usd>5000),
    AND(gateway_region="EU",   amount_usd>6000),
    AND(gateway_region="US",   amount_usd>7000)
  ), 1, 0)
```

### High-Risk Flag (Excel)
```excel
=IF(OR(risk_score>=70, status="chargeback"), 1, 0)
```
