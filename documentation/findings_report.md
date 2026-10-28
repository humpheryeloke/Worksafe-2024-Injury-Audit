# Findings report: 2024 OSHA Severe Injury classification audit

**Audience:** a safety-data team lead or quality reviewer who needs to know whether recorded OIICS classifications can be relied on and where a closer look is worthwhile.

**Scope reminder.** 100 of 9,034 incidents dated 2024 in the OSHA Severe Injury Report file were selected with a stratified, non-random design and re-coded independently from the narrative alone against OIICS Version 3.03. OSHA coded these incidents with Version 3.0, and original coders may have had fuller information than the short final narrative. Differences are *potential* discrepancies, not errors. Details: `methodology.md`.

## 1. Headline

Recorded and independently proposed codes agree **closely at the broad level and much less at the detailed level**. Nature agrees on the exact code for 71% of reviewable narratives and on the same division for 99%. Secondary source is the weakest field: 51% exact agreement and 66% at division level.

Of the 500 field-level comparisons (100 incidents x 5 fields), 194 differed. After re-reading each difference against the narrative and manual, **21 (4.2% of all fields) remain potential discrepancies**, 145 are explainable by the manual's rules or by the first proposal being less accurate than the recorded code, and 28 could not be judged from the narrative. The rest agreed exactly.

## 2. Agreement by field (blind comparison, primary result)

Denominator is *eligible* fields: reviewed (100) minus fields judged inconclusive at the blind stage. Exact interval is the Wilson 95% interval and is indicative only.

| Field | Reviewed | Inconclusive | Eligible | Exact | Exact % (95% interval) | Exact or my alternate | 3-digit group | 2-digit group | Division |
|---|---|---|---|---|---|---|---|---|---|
| Nature | 100 | 3 | 97 | 69 | 71.1 (61.4 to 79.2) | 87 (89.7%) | 78.4% | 87.6% | 99.0% |
| Part of body | 100 | 5 | 95 | 60 | 63.2 (53.1 to 72.2) | 77 (81.1%) | 64.2% | 77.9% | 91.6% |
| Event/Exposure | 100 | 5 | 95 | 53 | 55.8 (45.8 to 65.4) | 77 (81.1%) | 68.4% | 83.2% | 88.4% |
| Source | 100 | 6 | 94 | 61 | 64.9 (54.8 to 73.8) | 68 (72.3%) | 73.4% | 84.0% | 90.4% |
| Secondary source | 100 | 0 | 100 | 51 | 51.0 (41.3 to 60.6) | 64 (64.0%) | 53.0% | 62.0% | 66.0% |

*Source: `results/r01_agreement_by_field.csv`.* Only 10 of 100 incidents had all five fields exactly equal; 26 incidents had at least one field judged inconclusive.

**Reading it.** Agreement falls as the level of detail rises (Nature: 99% division, 88% major group, 78% minor group, 71% exact). That pattern is what a hierarchical code with many "unspecified" and "n.e.c." options would produce when two readers differ mainly on how much detail the narrative supports.

## 3. What happened to the differences

Every field of every incident sits in exactly one category (rows sum to 100).

| Field | Exact | Recorded supported on re-read | Rule interpretation | Potential: less specific | Potential: conflict | Insufficient information |
|---|---|---|---|---|---|---|
| Nature | 69 | 10 | 12 | 2 | 1 | 6 |
| Part of body | 60 | 12 | 17 | 2 | 1 | 8 |
| Event/Exposure | 53 | 6 | 25 | 7 | 1 | 8 |
| Source | 61 | 7 | 17 | 5 | 0 | 10 |
| Secondary source | 51 | 10 | 29 | 1 | 1 | 8 |

*Source: `results/r02_adjudicated_categories_by_field.csv`. Adjudication was done after seeing the recorded codes, so this table is a more generous view than the blind figures in section 2.*

Among conclusive fields, exact plus explained is 91% (Event) to 98% (Secondary source); potential discrepancies are 2% to 9% of conclusive fields (`results/r04_consistency_after_review.csv`). At incident level, 18 of 100 incidents have at least one potential discrepancy and 4 have one where the recorded code appears to conflict with the narrative.

## 4. Patterns behind the differences

1. **Rule-interpretation differences dominate.** Event (25) and Secondary source (29) carry most of them. Typical Event cases: the incident involves two events (a slip and contact with a machine, a violent act and a fall) and Event rule 2.b selects by numeric order of precedence; a reviewer can reasonably choose differently when the narrative does not say which event initiated the chain. Typical Secondary-source cases: the manual requires a secondary source for every case (991 if none, 990 if unidentified), but whether an additional item counts is a judgement.
2. **Specificity is the main substantive finding.** 17 of the 21 potential discrepancies are cases where the recorded code is *less specific* than the narrative supports, for example Event 990 (unspecified) where the narrative describes a forklift running over a worker's foot (incident 9) or a shifting load amputating a fingertip (incident 10); Source 360 or 30 (unspecified machinery) where the narrative names paper rollers or a casting drum (incidents 13, 31); Part 330 (abdomen) where the narrative names an injury to the large intestine (incident 77). The reverse also occurs: where codes differ and exactly one of them is non-specific, the recorded code is the more specific one in 50 cases and the less specific one in 43, which fits the idea that original coders often had information beyond the narrative.
3. **Four possible content conflicts** (each needs a look at the full case file): Nature 6121 "Damage to replaced joints" for a knee fracture after a trip (incident 93); Part "lower leg" for a bite behind the knee (4); Event "caught in running equipment" for a table-saw blade amputation (20); a floor as Secondary source where a pipe struck the ladder the worker fell from (44).
4. **Population context.** Across all 9,034 incidents the recorded data use an unspecified or n.e.c. code for 37.4% of Part, 29.4% of Nature, 27.5% of Event, 26.7% of Source and 24.3% of Secondary source. Secondary source is 991 (not applicable) on 2,914 records (32%) and 990 (unspecified) on 874 (10%). A high share of non-specific codes lowers how much the data can say about injury mechanisms and equipment, regardless of the accuracy of any single code.
5. **Narrative limits.** 40 fields (8%) could not be judged either because the narrative lacks the needed detail (for example no indication of intent behind a ladder being shaken, no height for a fall, motive of an assailant) or because it describes two injured workers. Those are narrative-writing problems as much as coding problems.
6. **By stratum.** Potential discrepancies per incident were highest in Event division 9 (0.67 per incident, 6 incidents) and division 3 (0.43, 7 incidents) and lowest in divisions 1, 5 and 7 (none). Strata are too small to compare formally.

## 5. Recommendations (limited to what the data support)

| # | Recommendation | Evidence | How to know it worked |
|---|---|---|---|
| 1 | Re-examine the 21 potential discrepancies (`review/discrepancy_log.xlsx`, sorted most concerning first) against the full case records, starting with the 4 content conflicts | Section 4, items 2 and 3 | Share of the 21 that are confirmed as changes after the full-record review |
| 2 | Add a check to the classification queue that flags Event, Source or Nature recorded as "unspecified" or n.e.c. when the narrative contains terms naming a specific machine, vehicle, body part or substance | 17 less-specific cases; high non-specific share overall | Share of non-specific codes in each field, tracked quarterly |
| 3 | Write down team conventions for Event order of precedence and for 990 vs 991 in Secondary source, with worked examples from the cases in the log | 25 and 29 rule-interpretation differences | Re-run the audit; exact agreement for Event and Secondary source should rise |
| 4 | Ask narrative writers to state the details that decide OIICS fields: body part named, fall height, intent of other person, machine type, whether a second worker was hurt | 40 insufficient-information fields | Share of narratives that let a second coder reach a conclusive code |
| 5 | Repeat the audit with a second independent coder on the same sample and report inter-rater agreement | Single-reviewer limitation | Agreement between two independent coders, compared with agreement with the recorded codes |

The data do **not** support claims about which employers or states code better, about injury frequency, or that any recorded code is wrong.

## 6. Limitations (summary)

Single, non-certified reviewer; short narratives; 3.0 vs 3.03 version difference; 100 incidents in a stratified non-representative sample; adjudication done non-blind; 43 of 100 incidents coded with low confidence; multiple-worker narratives. See `methodology.md` section 7.

## 7. Files behind the numbers

`sql/03_classification_audit.sql` (calculations), `results/` (tables above), `review/sample_review.xlsx` (every incident with recorded and proposed codes), `review/discrepancy_log.xlsx` (all 194 differences with justification and manual rule).
