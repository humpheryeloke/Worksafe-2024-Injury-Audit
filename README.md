# WorkSafe: 2024 Occupational Injury Classification Audit

I re-coded 100 narratives from OSHA's 2024 Severe Injury Reports against the OIICS 3.03 manual and compared my codes with the recorded ones. Exact agreement is 71% for Nature, 63% for Part of body, 56% for Event, 65% for Source and 51% for Secondary source. Agreement is high at broad levels (99% of Nature codes fall in the same division) and falls as detail increases. Only 21 of 500 field comparisons remain potential discrepancies, and 17 of those are recorded codes that are less specific than the narrative supports. Full write-up: [findings report](documentation/findings_report.md). Review data: [sample review workbook](review/sample_review.xlsx) and [discrepancy log](review/discrepancy_log.xlsx).

> **How to read this:** differences are *potential* discrepancies, not errors. OSHA coded 2024 incidents with OIICS 3.0 and I used the later 3.03 manual, and the original coders may have had more information than the short public narrative. The 100 incidents are a stratified sample and do not represent all 2024 incidents. This is a classification-consistency check, not an injury-rate study.

## Question

How closely do the recorded OIICS codes (Nature, Part of body, Event, Source, Secondary source) match an independent reading of the incident narrative, where do they differ, and which differences deserve a closer look?

## Data

- **Source:** OSHA Severe Injury Reports, January 2015 to November 2025 (employer-reported hospitalizations, amputations and loss of an eye). Download the CSV from the [OSHA Severe Injury Reports page](https://www.osha.gov/severeinjury). The file is not stored in this repository.
- **Reference:** BLS OIICS Version 3.03 code workbook (2,891 codes).
- **Row flow:** 105,996 incidents, filtered to 9,034 dated 2024, then 9,023 eligible for sampling (9 narratives under 60 characters and one duplicated narrative excluded), then 100 reviewed.
- **Privacy:** employer names, addresses and coordinates are dropped at import and never used.
- **Data quality:** 26 checks (`results/r10_data_quality_summary.csv`). The main finding is that 24% to 37% of recorded codes are "unspecified" or "n.e.c." depending on the field.

## Method

- Stratified sample of 100 incidents by recorded Event division, with a seeded, reproducible ordering.
- Narrative-only coding of all five fields using the OIICS 3.03 rules of selection, with acceptable alternates, inconclusive flags and confidence recorded before the recorded codes were consulted.
- Agreement measured at exact code, 3-digit, 2-digit and 1-digit level, with inconclusive fields removed from each denominator and 95% Wilson score intervals for exact agreement (Wilson, 1927).
- Every one of the 194 differing fields re-read against the narrative and manual and placed in a category: recorded code supported, rule-interpretation difference, potential discrepancy (less specific or conflicting), or insufficient information. This second step was done knowing the recorded codes, so the blind agreement figures are the primary result.

## Key results

| Field | Exact agreement (eligible fields) | Same division |
|---|---|---|
| Nature | 71.1% (69 of 97) | 99.0% |
| Part of body | 63.2% (60 of 95) | 91.6% |
| Event/Exposure | 55.8% (53 of 95) | 88.4% |
| Source | 64.9% (61 of 94) | 90.4% |
| Secondary source | 51.0% (51 of 100) | 66.0% |

- 194 of 500 field comparisons differed: 145 are explained by manual rules or by my first proposal being less accurate, 28 could not be judged from the narrative, and 21 are potential discrepancies (17 less specific than the narrative supports, 4 that appear to conflict with it).
- Event and Secondary source carry most rule-interpretation differences (event order of precedence; secondary source 990 vs 991).
- Only 10 of 100 incidents had all five fields exactly equal.

## Run it yourself

1. Download the OSHA CSV and extract it.
2. Put your local paths in the `/path/to/` placeholders in the SQL scripts.
3. Run the scripts in this order with `--local-infile=1`: `01_import_and_filter.sql`, `00_load_oiics_reference.sql`, `02_data_quality_checks.sql`, `02b_select_review_sample.sql`, `03_classification_audit.sql`.

Re-running from scratch reproduces the same sample and the same results.

## Structure

```
.
├── README.md
├── sql/
│   ├── 00_load_oiics_reference.sql
│   ├── 01_import_and_filter.sql
│   ├── 02_data_quality_checks.sql
│   ├── 02b_select_review_sample.sql
│   └── 03_classification_audit.sql
├── review/
│   ├── blind_coding.csv
│   ├── adjudication.csv
│   ├── sample_review.xlsx
│   └── discrepancy_log.xlsx
├── documentation/
│   ├── data_dictionary.md
│   ├── methodology.md
│   ├── findings_report.md
│   └── reference/
└── results/            summary tables r01 to r11
```

## Limitations

- One reviewer, not a certified OIICS coder, so agreement with the recorded codes is not the same as correctness. 43 of the 100 incidents were coded at low confidence.
- Public narratives are shorter than the case files the original coders may have used.
- OIICS 3.0 (recorded) versus 3.03 (my reference).
- The sample is not representative and the intervals are wide, about plus or minus 10 points.
- The adjudication step was not blind.
- Scripts were verified on MariaDB 10.11 (MySQL-compatible), not on Oracle MySQL 8.

## Tools

- **MySQL (verified on MariaDB 10.11):** import, data-quality checks, sampling and all comparison calculations.
- **Microsoft Excel:** review workbooks with filters, conditional formatting and summary formulas.
- **Markdown:** methodology, data dictionary and findings report.

## References

- U.S. Bureau of Labor Statistics. [Occupational Injury and Illness Classification (OIICS) Manual](https://www.bls.gov/iif/definitions/occupational-injuries-and-illnesses-classification-manual.htm).
- U.S. Occupational Safety and Health Administration. [Severe Injury Reports](https://www.osha.gov/severeinjury).
- U.S. Occupational Safety and Health Administration. [2024 Annual Report of Severe Injuries and Illnesses](https://www.osha.gov/sites/default/files/2024_Annual_Report_of_Fed_OSHA_SIRs.pdf).
- Wilson, E. B. (1927). Probable inference, the law of succession, and statistical inference. *Journal of the American Statistical Association*, 22(158), 209-212.

## Author

Humphery Chinedu Eloke. Pharmacology (Delta State University, Abraka), pharmacology research assistant, based in Lagos, Nigeria. Target field: occupational safety and health data analysis.
