# QuickPay FinTech Operations – Case Study Assignment

## Student Information
| Field           | Detail                    |
|-----------------|---------------------------|
| Student Name    | Mokshit                   |
| Student ID      | [Your Student ID Here]    |
| Program         | B.Sc. Finance, Semester IV |
| Institute       | NMIMS ASMSOC, Mumbai      |

## Repository
**Public GitHub Repository:** `https://github.com/[your-username]/quickpay-fintech-ops`

---

## Project Overview

End-to-end data analytics pipeline for QuickPay, a fintech payments processor. The project covers:

| Part | Task | Tools |
|------|------|-------|
| 1    | Transaction data cleaning & business logic | Python / Excel |
| 2    | SQL business analysis (8 queries) | SQL (SQLite/ANSI) |
| 3    | Reconciliation workflow (ledger vs gateway) | Python / Pandas |
| 4    | JSON API normalization | Python |
| 5    | Business monitoring dashboard | Looker Studio |

---

## Quick Run Instructions

### Prerequisites
```bash
pip install pandas openpyxl numpy
```

### Run the Python Pipeline
```bash
cd 04_python
jupyter notebook fintech_pipeline.ipynb
```
Run all cells top-to-bottom. All output CSVs and JSON will be generated in `01_data/processed/` and `04_python/`.

### SQL Queries
Queries in `03_sql/analysis_queries.sql` are written in standard ANSI SQL (SQLite-compatible).
Load `01_data/processed/cleaned_transactions.csv` as the `cleaned_transactions` table.

### Excel Workbook
Open `02_spreadsheet/spreadsheet_workbook.xlsx`. Contains 6 sheets:
1. `1_Raw_Transactions` — original raw data
2. `2_Exchange_Rates` — FX rates reference
3. `3_Merchant_Master` — merchant reference data
4. `4_Cleaned_Transactions` — fully cleaned, enriched, flagged
5. `5_Merchant_Risk_Summary` — aggregated merchant analytics
6. `6_KPI_Summary` — headline KPIs and region breakdown

---

## Key Findings

### Data Quality
- 30 raw transactions, all retained after cleaning
- 11 rows with missing gateway_region — filled via merchant_master lookup
- 1 row with unrecoverable risk_score (T011) — treated as null

### Business Insights
- **Top Merchant:** Beta Stores — USD 33,431 captured GMV
- **Top Region:** APAC — USD 82,594 total GMV (71% of total)
- **Chargeback Alert:** Eco Home (50% rate), Delta Travels (25%)
- **Fraud Signal:** User U008 had 4 fail/chargeback events on a single day (2026-03-05)
- **Reconciliation:** 6 issues found — 2 missing in gateway, 1 missing in ledger, 2 amount mismatches, 1 status mismatch

### KPIs
| KPI | Value |
|-----|-------|
| Total GMV | USD 116,080 |
| Confirmed GMV | USD 82,355 |
| Amount at Risk | USD 43,610 |
| Success Rate | 63.33% |

---

## Repository Structure
```
quickpay-fintech-ops/
├── README.md
├── 01_data/
│   ├── raw/
│   │   ├── transactions_raw.csv
│   │   ├── merchant_master.csv
│   │   ├── users.csv
│   │   ├── ledger.csv
│   │   ├── gateway.csv
│   │   ├── exchange_rates.csv
│   │   └── api_response_sample.json
│   └── processed/
│       ├── cleaned_transactions.csv
│       ├── merchant_risk_summary.csv
│       ├── missing_in_gateway.csv
│       ├── missing_in_ledger.csv
│       ├── amount_mismatches.csv
│       ├── status_mismatches.csv
│       ├── reconciliation_report.csv
│       ├── api_normalized.csv
│       ├── daily_summary.csv
│       ├── payment_method_breakdown.csv
│       ├── region_breakdown.csv
│       └── merchant_performance_summary.csv
├── 02_spreadsheet/
│   ├── spreadsheet_workbook.xlsx
│   └── spreadsheet_answers.md
├── 03_sql/
│   ├── analysis_queries.sql
│   └── sql_answers.md
├── 04_python/
│   ├── fintech_pipeline.ipynb
│   └── summary_metrics.json
└── 05_visualization/
    └── dashboard_link.txt
```

---

## Tools Used
- **Python 3.10+** — Pandas, NumPy, openpyxl, json
- **SQL** — ANSI SQL (tested on SQLite)
- **Excel** — openpyxl-generated `.xlsx` workbook
- **Looker Studio** — Dashboard visualization
- **Jupyter Notebook** — Interactive Python pipeline
