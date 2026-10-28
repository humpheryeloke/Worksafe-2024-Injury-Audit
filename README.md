# WorkSafe: 2024 Occupational Injury Classification Audit

A classification-consistency audit of OSHA Severe Injury Report incidents against the OIICS Version 3.03 coding manual.

## 1. Business problem

Occupational injury data are only as useful as their classification. If the recorded Nature, Part of body, Event, Source and Secondary source codes for an incident do not reflect what its narrative describes, trend reports, hazard targeting and prevention work built on those codes inherit the problem. A data-quality team needs to know **how closely recorded classifications match an independent reading of the narrative, where they differ, and which differences deserve a closer look**.

## 2. Healthcare and public-health context

OSHA requires employers to report every work-related in-patient hospitalization, amputation and loss of an eye. The public Severe Injury Report (SIR) dataset records each incident with a short plain-language narrative and five codes from the BLS Occupational Injury and Illness Classification System (OIICS). Analysts, safety professionals and researchers use those codes to describe which injuries happen, how, and with what equipment. The audit follows the day-to-day work of an occupational safety and health data analyst: reading narratives in plain language, applying a classification manual, checking quality and documenting reasoning.

## 3. Objectives

* Primary: compare recorded OIICS classifications for a 2024 sample with independent classifications of the same narratives, and measure agreement by field and level of detail.
* Secondary: audit data quality of the 2024 file; investigate and categorise differences as potential discrepancies versus differences explainable by the manual; identify where narratives lack detail; recommend follow-up that the evidence supports.

## 4. Dataset

OSHA Severe Injury Reports, January 2015 to November 2025 (105,996 incidents; severe injuries only; federal OSHA and state-plan states). Filtered to incidents dated in 2024: **9,034 incidents**. Reference: OIICS Version 3.03 code workbook (May 2026; 2,891 codes). Details and caveats: `documentation/data_dictionary.md`. Employer names and addresses were removed at import and are not used.

## 5. Data preparation

Raw file loaded unchanged into MySQL-compatible tables; filtered by event date; 26 data-quality checks run (identifiers, duplicates, narratives, codes against the 3.03 reference, non-specific codes, amputation flag consistency); a reference table of all 3.03 codes built. See `sql/01`, `sql/00`, `sql/02` and `results/r10_data_quality_summary.csv`.

## 6. Methodology

Stratified review sample of 100 incidents (strata: recorded Event division; seeded and reproducible); narrative-only independent coding of all five fields with alternates, inconclusive flags and confidence; comparison at exact, 3-digit, 2-digit and 1-digit levels with explicit denominators and Wilson intervals; adjudication of all 194 differing fields into explainable, potential-discrepancy and insufficient-information categories. Differences are **potential discrepancies**, never automatic errors. This is a **retrospective comparison**: OSHA coded 2024 incidents with OIICS 3.0, the review uses 3.03. Full detail: `documentation/methodology.md`.

## 7. Key findings

| Field | Exact agreement (eligible fields) | Same division |
|---|---|---|
| Nature | 71.1% (69 of 97) | 99.0% |
| Part of body | 63.2% (60 of 95) | 91.6% |
| Event/Exposure | 55.8% (53 of 95) | 88.4% |
| Source | 64.9% (61 of 94) | 90.4% |
| Secondary source | 51.0% (51 of 100) | 66.0% |

* Agreement is high at broad levels and drops with detail.
* Of 500 field comparisons, 194 differed; 145 are explainable by manual rules or by the first proposal being less accurate; 28 could not be judged from the narrative; **21 remain potential discrepancies**, of which 17 are recorded codes less specific than the narrative supports and 4 appear to conflict with it.
* Event and Secondary source carry most rule-interpretation differences (order of precedence; 990 vs 991).
* Across all 9,034 incidents, 24% to 37% of recorded codes are unspecified or n.e.c.
* The 100-incident sample is not representative; no recorded code is declared wrong.

Full report: `documentation/findings_report.md`.

## 8. KPIs

| KPI | Formula | Population | Interpretation and limit |
|---|---|---|---|
| Exact agreement rate (per field) | exact matches / (reviewed minus inconclusive) | 100 reviewed incidents | Share of reviewable narratives where recorded and proposed code are identical; reflects coder agreement, not correctness |
| Division / group agreement rate | agreements at 1-, 2- or 3-digit level / eligible | same | Shows how far apart codes are when they differ |
| Inconclusive rate | fields flagged inconclusive / reviewed | same | Proxy for narrative detail; also depends on the reviewer |
| Potential discrepancy rate | Ps + Pc fields / conclusive fields | same | Candidates for full-record review, not error rate |
| Non-specific code share | records with "unspecified" or n.e.c. code / all records | all 9,034 incidents | Limits analytic value of the field |

## 9. Dashboard

Not part of this project. Results are in tables and review workbooks (`results/`, `review/`).

## 10. Recommendations

Re-examine the 21 potential discrepancies against full case records; add a queue check for non-specific codes where the narrative names something specific; document team conventions for Event order of precedence and 990 vs 991; give narrative writers a short list of details that decide OIICS fields; repeat the audit with a second independent coder. Evidence and success measures: `documentation/findings_report.md`.

## 11. Limitations

Single non-certified reviewer; narratives shorter than the case file; OIICS 3.0 vs 3.03; 100-incident non-representative sample; non-blind adjudication; 43 of 100 incidents coded at low confidence; scripts verified on MariaDB 10.11 (MySQL-compatible), not on Oracle MySQL 8.

## 12. Tools used

MySQL-compatible SQL (verified on MariaDB 10.11), Microsoft Excel workbooks (formulas, conditional formatting, filters; recalculated in LibreOffice), Markdown.

## 13. Project structure

```
WorkSafe-2024-Injury-Audit/
├── README.md
├── sql/
│   ├── 00_load_oiics_reference.sql      OIICS 3.03 code table
│   ├── 01_import_and_filter.sql         import raw file, filter to 2024
│   ├── 02_data_quality_checks.sql       26 data-quality checks
│   ├── 02b_select_review_sample.sql     stratified, reproducible 100-incident sample
│   └── 03_classification_audit.sql      comparison, agreement, categories, results tables
├── review/
│   ├── blind_coding.csv                 independent codes (narrative only)
│   ├── adjudication.csv                 category and justification per differing field
│   ├── sample_review.xlsx               100 incidents: recorded vs proposed codes
│   └── discrepancy_log.xlsx             194 differing fields with rule and justification
├── documentation/
│   ├── data_dictionary.md
│   ├── methodology.md
│   ├── findings_report.md
│   └── reference/ (oiics_303_codes.csv, oiics_reference_sheet.md)
└── results/                             r01 to r11 summary tables (CSV)
```

**To reproduce:** download the SIR CSV and place the project folder path in the `/path/to/` placeholders; run scripts in the order 01, 00, 02, 02b, 03 with `--local-infile=1`.

## 14. Sources

* BLS, [OIICS Manual](https://www.bls.gov/iif/definitions/occupational-injuries-and-illnesses-classification-manual.htm) (Version 3.03 workbook supplied with the project).
* OSHA, [Severe Injury Reports](https://www.osha.gov/severeinjury).
* OSHA, [2024 Annual Report of Severe Injuries and Illnesses](https://www.osha.gov/sites/default/files/2024_Annual_Report_of_Fed_OSHA_SIRs.pdf).
