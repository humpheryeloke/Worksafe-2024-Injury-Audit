# Data dictionary

## 1. Source data

**OSHA Severe Injury Reports (SIR), January 2015 to November 2025.** File: `January2015toNovember2025.csv`, 105,996 incident records. Produced by the U.S. Occupational Safety and Health Administration (OSHA). Employers must report every work-related in-patient hospitalization, amputation, or loss of an eye to OSHA within 24 hours. Records are published for federal OSHA and for state-plan states that participate. The dataset covers **severe injuries only**; it is not a census of all workplace injuries and not a sample of them.

**One row = one reported severe-injury incident.** Unit of analysis: incident (one narrative and one set of five codes). When an incident injured more than one worker, the record describes one reported injury.

The raw file is never modified. It is loaded unchanged into `raw_sir` (all columns as text) and filtered into `sir_2024`.

| Raw column | Meaning | Used in this project |
|---|---|---|
| ID | OSHA incident record identifier (unique per row in 2024) | Yes (key) |
| UPA | Establishment-incident identifier | Audit only |
| EventDate | Date of the incident, text m/d/yyyy | Yes (filter to 2024) |
| Employer, Address1, Address2, City, Zip, Latitude, Longitude | Employer name and location | **Not carried forward.** Excluded from `sir_2024` and all outputs for privacy and because the audit does not need them |
| State | Establishment state | Kept in `sir_2024` |
| Primary NAICS | Industry code of the establishment | Kept in `sir_2024` |
| Hospitalized, Amputation, Loss of Eye | Counts of workers with each outcome | Kept; used in DQ23 to DQ25 |
| Inspection | OSHA inspection indicator | Not used |
| Final Narrative | Short plain-language description of what happened | Yes: the only input for independent coding |
| Nature, NatureTitle | OIICS Nature code and title as recorded | Yes |
| Part of Body, PartofBodyTitle | OIICS Part of body code and title | Yes |
| Event, EventTitle | OIICS Event or exposure code and title | Yes |
| Source, SourceTitle | OIICS Source code and title | Yes |
| Secondary Source, SecondarySourceTitle | OIICS Secondary source code and title | Yes |
| FederalState | Reporting jurisdiction (federal OSHA or state plan) | Yes (DQ26) |

**What the data can answer:** how often the recorded classification of a narrative differs from an independent reading, at which fields and levels, and what kinds of differences occur.

**What it cannot answer:** whether any recorded code is *wrong*. The recorded coders may have had fuller information (inspection findings, employer reports, follow-up calls) than the short final narrative; narratives are written to protect privacy and are sometimes edited. Nothing here measures the injury rate, risk, or the true distribution of injuries.

## 2. Analysis tables (MySQL schema `worksafe`)

| Table | Created by | Grain | Notes |
|---|---|---|---|
| `raw_sir` | 01 | 105,996 rows | Raw file as text |
| `sir_2024` | 01 | 9,034 rows | Typed; `event_date` between 2024-01-01 and 2024-12-31; employer and address fields dropped |
| `oiics_ref` | 00 | 2,891 rows | OIICS 3.03 codes: `field`, `code`, `title`, `hierarchy`, `title_key` (title lower-cased with non-alphanumerics removed, used only for title matching) |
| `dq_summary` | 02 | 70 rows | Results of 26 data-quality checks (some checks produce several rows) |
| `sample_allocation` | 02b | 8 rows | Sample size per Event division |
| `sampling_frame` | 02b | 9,023 rows | 2024 records eligible for sampling |
| `review_sample` | 02b | 100 rows | The review sample; `review_id` is a shuffled 1 to 100 label |
| `review_coding` | 03 | 100 rows | Independent codes, alternates, inconclusive flags, confidence, rationale |
| `review_adjudication` | 03 | 194 rows | One row per field where proposed and recorded codes differ |
| `category_lookup` | 03 | 6 rows | Category codes and names |
| `review_pairs`, `review_comparison` | 03 | 500 rows | One row per incident and field (5 fields x 100 incidents) |
| `review_incident_summary` | 03 | 100 rows | Counts of categories per incident |
| `result_*` | 03 | various | Tables exported to `results/` |

### Key columns of `review_comparison`

| Column | Meaning |
|---|---|
| `field`, `field_name` | N Nature, P Part of body, E Event/Exposure, S Source, SS Secondary source |
| `rec_code`, `rec_title` | Recorded code and title (the source file removes the dash character from titles, so titles such as "Caught, entangled ... normal operation" appear without it) |
| `my_code`, `my_title`, `my_alt` | Independent proposed code, its title, and the other codes judged acceptable |
| `inconclusive` | 1 if the field was judged inconclusive at the blind stage |
| `exact_match`, `alt_match` | Recorded code equals proposed code; recorded code appears in the alternates list |
| `agree_minor`, `agree_major`, `agree_division` | Agreement at 3-digit, 2-digit and 1-digit level |
| `code_relation` | Exact, same minor group, same major group, same division only, or different division |
| `category_code` | X exact; R recorded supported on re-read; G rule interpretation; Ps potential, less specific; Pc potential, conflict; N insufficient information |
| `reviewer_note` | Justification for the category |

## 3. Review files

| File | Contents |
|---|---|
| `review/blind_coding.csv` | Proposed codes written from the narrative alone before recorded codes were consulted |
| `review/adjudication.csv` | Category and justification for every differing field (written after comparison) |
| `review/sample_review.xlsx` | 100 incidents: narrative, recorded and proposed codes with titles, status by field, rationale. Includes summary formulas and legend |
| `review/discrepancy_log.xlsx` | The 194 differing fields, sorted from most to least concerning, with relationship between codes, applicable manual rule, and justification |

## 4. Results files

| File | Contents |
|---|---|
| `results/r01_agreement_by_field.csv` | Per field: reviewed, inconclusive, eligible, exact, exact-or-alternate, 3-, 2- and 1-digit agreement, Wilson 95% interval for exact |
| `results/r02_adjudicated_categories_by_field.csv` | Every field of every incident in exactly one category (rows sum to 100) |
| `results/r03_category_long.csv` | Same, long format with percentages |
| `results/r04_consistency_after_review.csv` | Exact plus explained, among conclusive fields |
| `results/r05_code_relation_when_different.csv` | How far apart codes are when they differ |
| `results/r06_incident_level.csv` | Incident-level measures |
| `results/r07_potential_discrepancies_by_event_division.csv` | Potential discrepancies by sampling stratum |
| `results/r08_potential_discrepancy_detail.csv` | The 21 potential discrepancies with justification |
| `results/r09_nonspecific_share_all_2024.csv` | Share of unspecified or n.e.c. codes across all 9,034 incidents |
| `results/r10_data_quality_summary.csv` | All 26 data-quality checks |
| `results/r11_sample_allocation.csv` | Frame size and sample size by stratum |

## 5. Known data issues

* Narratives are short (reviewed sample: 65 to 589 characters, mean 227) and 131 of 9,034 contain embedded line breaks.
* One pair of records (IDs 2024054312 and 2024054313) are identical apart from ID, and 9 narratives are under 60 characters. All of these are kept in `sir_2024` but excluded from the sampling frame.
* Recorded titles carry leading whitespace and no dash characters; matching to the manual therefore uses a normalised key.
* Recorded codes use "unspecified" or n.e.c. codes often: Event 27.5%, Nature 29.4%, Part 37.4%, Source 26.7%, Secondary source 24.3%.
* Secondary source is 991 (not applicable) on 2,914 records and 990 (unspecified) on 874.
* Amputation flag and Nature disagree on 80 records (51 with flag 0 but Nature 122*; 29 with flag at least 1 but Nature not 122*). Reported, not corrected.
