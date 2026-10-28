# Methodology

## 1. Question and scope

**Question:** For a sample of 2024 OSHA Severe Injury Report incidents, how closely does the recorded OIICS classification match an independent classification of the same narrative using OIICS Version 3.03, and where do the differences occur?

**Scope:** incidents dated 1 January to 31 December 2024; five fields (Nature, Part of body, Event/Exposure, Source, Secondary source); 100 incidents reviewed in detail. Worker activity and location are not in the dataset and are not reviewed.

**Not in scope:** deciding that any recorded code is an error; estimating injury rates; any statement about employers; analysis of individual employers (employer and address fields were never carried into the analysis tables).

**Important framing.** OSHA coded the 2024 incidents with OIICS Version 3.0. This audit uses the 3.03 manual (May 2026). It is therefore a **retrospective comparison against a later manual**. Every difference is a *potential* discrepancy for review, not an automatic error.

## 2. Data preparation (SQL scripts 00 to 02)

1. **Import** (`01_import_and_filter.sql`). The CSV is loaded unchanged into a text-only landing table (105,996 rows). Dates are text in m/d/yyyy form; 0 could not be parsed. Rows per year are listed to confirm the filter.
2. **Filter to 2024.** `STR_TO_DATE(event_date, '%m/%d/%Y')` from 2024-01-01 up to but not including 2025-01-01: 9,034 rows kept, 96,962 excluded. Check: 0 rows outside 2024; date range 2024-01-01 to 2024-12-31. Employer, address and coordinates are dropped.
3. **Reference table** (`00_load_oiics_reference.sql`). The 3.03 code workbook is flattened to 2,891 codes (field, code, title, hierarchy). Heading rows are retained in the reference for context but only leaf codes are assignable.
4. **Data-quality audit** (`02_data_quality_checks.sql`, 26 checks). Highlights: IDs unique; one identical pair of records; 9 narratives under 60 characters; 131 narratives with embedded line breaks; no blank narratives or codes; every recorded code exists in 3.03 and every recorded title matches the 3.03 title after normalisation; non-specific codes are common (24% to 37% depending on field); 80 records where the amputation flag and Nature disagree. Full list: `results/r10_data_quality_summary.csv`.

## 3. Sample design (`02b_select_review_sample.sql`)

* **Frame:** 9,023 of the 9,034 records (excluding narratives under 60 characters, which are too short to code, and the duplicated narrative).
* **Strata:** division of the *recorded* Event code (first digit). Allocation: division 6: 30; 4: 22; 2: 11; 5: 10; 3: 7; 1: 7; 7: 7; 9: 6 (total 100). Rule: at least 6 per division, remaining places roughly proportional to division size.
* **Selection inside a stratum:** records ranked by MD5 of a fixed seed plus incident ID (reproducible, no `RAND()`), with round-robin across Nature groups so that different injury types appear before any is repeated. The final sample covers 44 Nature groups.
* **Review order:** `review_id` is a seeded shuffle, so the order carries no information.
* **The sample is not statistically representative of all 2024 incidents.** It over-represents small Event divisions on purpose, so that each can be examined. Results describe the 100 incidents reviewed.

## 4. Independent classification

1. A narrative-only file was produced with `review_id`, date and narrative. Recorded codes were not in it.
2. Each narrative was coded for all five fields with the 3.03 manual: the code table, the rules of selection for each field, and each code's definition, includes, excludes and "Coding interactions". Steps followed the manual's order: Nature, then Part, then Event, then Source and Secondary source.
3. For each field the review recorded: one proposed code; **acceptable alternates** (other codes defensible for the same narrative, decided at this stage); an **inconclusive** flag where the narrative did not carry enough information; an overall confidence (H/M/L); and a short rationale citing the rule used.
4. All proposed and alternate codes were validated against the reference table (assignable leaf code, correct field). Invalid codes were corrected before comparison.
5. The coding file was frozen (SHA-256 recorded) before it was joined to the recorded codes. Nothing in it changed afterwards.

Overall confidence: 2 incidents H, 55 M, 43 L. A large share of low-confidence cases is expected for short narratives and means the proposed codes are themselves uncertain.

## 5. Comparison (`03_classification_audit.sql`)

* **Levels of agreement:** exact code; same 3-digit minor group; same 2-digit major group; same 1-digit division. Two codes agree at a level when their first digits match to that level, or when one is a heading of the other.
* **Denominators:** *reviewed* = 100 per field; *inconclusive* = fields flagged at the blind stage; *eligible* = reviewed minus inconclusive. Agreement percentages use *eligible*. Inconclusive fields are never counted as agreement or disagreement.
* **Exact or alternate:** a secondary measure counting recorded codes that appear in the alternates written down at the blind stage.
* **Confidence interval:** Wilson 95% interval for the exact-agreement proportion, n = 94 to 100. The intervals are indicative only (the sample is stratified and not random), so they should not be generalised to all 9,034 incidents.

## 6. Adjudication of differences

After the comparison, every field where the codes differ (194 of 500) was re-read against the narrative and the manual and placed in one of:

| Category | Meaning |
|---|---|
| **R** Explained: recorded code supported on re-read | The narrative and manual support the recorded code; the first proposal was less accurate or less specific |
| **G** Explained: guidance / rule interpretation | Both codes are defensible under the rules (for example Event order of precedence, multiple-injury rules, optional secondary source) |
| **Ps** Potential discrepancy: recorded less specific | The narrative supports a more specific code than the one recorded |
| **Pc** Potential discrepancy: conflict | The recorded code appears to conflict with the narrative or manual guidance |
| **N** Insufficient narrative information | The narrative cannot support or refute the recorded code (includes fields flagged inconclusive at the blind stage) |

Four types of finding are kept separate in the reporting: *confirmed inconsistency* (none declared, because a narrative alone cannot confirm an error); *possible discrepancy* (Ps and Pc); *difference explainable by guidance* (R and G); *inconclusive* (N).

Adjudication is **second-stage and not blind**: it was done knowing the recorded codes. It is therefore open to anchoring and is reported separately from the blind agreement figures. The blind figures are the primary result. The adjudicated "consistent after review" percentages are a secondary, more generous view.

## 7. Limitations

1. **Single reviewer.** There is no second independent coder, so inter-rater reliability cannot be estimated, and the reviewer is not a certified OIICS coder. Agreement with the recorded codes is not the same as correctness.
2. **Narratives are shorter than the case file.** Original coders may have had inspection or employer information that the final narrative omits. Differences where the recorded code is more specific than the narrative supports may reflect that fuller information.
3. **Version difference.** Recorded codes follow OIICS 3.0; the manual used is 3.03.
4. **Sample.** 100 incidents, stratified and not representative; intervals are wide (about plus or minus 10 points).
5. **Adjudication bias.** Described above.
6. **Multiple-worker incidents.** Some narratives describe more than one injured worker while the record carries one set of codes; such fields are treated as insufficient information.
7. **Scope.** Findings concern classification consistency, not injury causes, prevention or employer performance.

## 8. Tools and verification

* SQL scripts were run and verified on **MariaDB 10.11**, a MySQL-compatible server, not on Oracle MySQL 8. They use only standard features (CTEs, window functions in the sampling script, `LOAD DATA LOCAL INFILE`, `REGEXP_REPLACE`) that are also available in MySQL 8.
* Review workbooks are generated from the database tables and recalculated in LibreOffice; the summary sheets use live Excel formulas that reproduce the SQL results (checked: Nature 71.1%, Part 63.2%, Event 55.8%, Source 64.9%, Secondary source 51.0%).
* Checks run: all rows in 2024; 500 comparison rows; every difference has an adjudication record and no adjudication exists without a difference; per-field categories sum to 100; denominators reconcile (reviewed = eligible + inconclusive).

## 9. Ethics and privacy

The SIR file is public and contains employer names and addresses. These were removed at the first step and are not used. No attempt was made to identify employers or workers. Narratives are quoted only in the review workbooks as part of the audit record.

## 10. Sources

* Bureau of Labor Statistics, [Occupational Injury and Illness Classification (OIICS) Manual](https://www.bls.gov/iif/definitions/occupational-injuries-and-illnesses-classification-manual.htm). The code workbook used here is Version 3.03, May 2026, as supplied with the project.
* OSHA, [Severe Injury Reports](https://www.osha.gov/severeinjury) (data and reporting requirements).
* OSHA, [2024 Annual Report of Severe Injuries and Illnesses (federal OSHA SIRs)](https://www.osha.gov/sites/default/files/2024_Annual_Report_of_Fed_OSHA_SIRs.pdf).
