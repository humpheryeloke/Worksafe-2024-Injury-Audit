-- =====================================================================
-- 03_classification_audit.sql
-- Compare my independent OIICS 3.03 codes with the recorded OSHA SIR codes
-- for the 100-incident review sample and summarise agreement.
--
-- Inputs (CSV files in review/):
--   blind_coding.csv   my proposed codes, written from the narrative ALONE
--                      (recorded codes were hidden at that stage)
--   adjudication.csv   second-stage review of every field where the codes differ
--
-- Run order: 01_import_and_filter -> 00_load_oiics_reference -> 02_data_quality_checks
--            -> 02b_select_review_sample -> this script.
-- Replace /path/to/ with your local project folder before running.
-- Verified on MariaDB 10.11 (MySQL-compatible); uses CTEs, window-free joins,
-- FIND_IN_SET and LEFT only.
-- =====================================================================
USE worksafe;

-- ---------------------------------------------------------------------
-- SECTION 1. LOAD THE REVIEW RECORDS
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS review_coding;
CREATE TABLE review_coding (
    review_id     INT PRIMARY KEY,
    nature        VARCHAR(10), nature_alt    VARCHAR(100),
    part          VARCHAR(10), part_alt      VARCHAR(100),
    event         VARCHAR(10), event_alt     VARCHAR(100),
    source        VARCHAR(10), source_alt    VARCHAR(100),
    secondary     VARCHAR(10), secondary_alt VARCHAR(100),
    inc_fields    VARCHAR(20),   -- fields I judged inconclusive: N,P,E,S,SS
    confidence    CHAR(1),       -- my overall confidence: L / M / H
    rationale     TEXT
);
LOAD DATA LOCAL INFILE '/path/to/review/blind_coding.csv'
INTO TABLE review_coding
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

DROP TABLE IF EXISTS review_adjudication;
CREATE TABLE review_adjudication (
    review_id     INT,
    field         VARCHAR(2),    -- N, P, E, S, SS
    category_code VARCHAR(2),    -- R, G, Ps, Pc, N  (see lookup below)
    reviewer_note TEXT,
    PRIMARY KEY (review_id, field)
);
LOAD DATA LOCAL INFILE '/path/to/review/adjudication.csv'
INTO TABLE review_adjudication
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Category lookup. Differences are POTENTIAL discrepancies, never automatic errors.
DROP TABLE IF EXISTS category_lookup;
CREATE TABLE category_lookup (
    category_code VARCHAR(2) PRIMARY KEY,
    category_name VARCHAR(80),
    category_group VARCHAR(40),
    sort_order INT
);
INSERT INTO category_lookup VALUES
 ('X',  'Exact agreement',                                           'Consistent',        1),
 ('R',  'Explained: recorded code supported on re-read',             'Consistent',        2),
 ('G',  'Explained: guidance / rule-interpretation difference',      'Consistent',        3),
 ('Ps', 'Potential discrepancy: recorded code less specific',        'Potential discrepancy', 4),
 ('Pc', 'Potential discrepancy: recorded code conflicts with text',  'Potential discrepancy', 5),
 ('N',  'Insufficient narrative information',                        'Inconclusive',      6);

-- Validation: sample is complete and every adjudication row is a real difference
SELECT COUNT(*) AS coding_rows,
       (SELECT COUNT(*) FROM review_sample)      AS sample_rows,
       (SELECT COUNT(*) FROM review_adjudication) AS adjudication_rows
FROM review_coding;

-- ---------------------------------------------------------------------
-- SECTION 2. ONE ROW PER INCIDENT x FIELD (500 rows)
-- Columns: recorded code, proposed code, my acceptable alternates,
-- whether I flagged the field inconclusive, and agreement at each level.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS review_pairs;
CREATE TABLE review_pairs AS
SELECT r.review_id, r.incident_id, 1 AS field_no, 'N'  AS field, 'Nature' AS field_name,
       s.nature AS rec_code, s.nature_title AS rec_title, c.nature AS my_code, c.nature_alt AS my_alt,
       FIND_IN_SET('N', c.inc_fields) > 0 AS inconclusive
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id JOIN review_coding c ON c.review_id = r.review_id
UNION ALL
SELECT r.review_id, r.incident_id, 2, 'P', 'Part of body', s.part_of_body, s.part_of_body_title, c.part, c.part_alt,
       FIND_IN_SET('P', c.inc_fields) > 0
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id JOIN review_coding c ON c.review_id = r.review_id
UNION ALL
SELECT r.review_id, r.incident_id, 3, 'E', 'Event/Exposure', s.event, s.event_title, c.event, c.event_alt,
       FIND_IN_SET('E', c.inc_fields) > 0
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id JOIN review_coding c ON c.review_id = r.review_id
UNION ALL
SELECT r.review_id, r.incident_id, 4, 'S', 'Source', s.source, s.source_title, c.source, c.source_alt,
       FIND_IN_SET('S', c.inc_fields) > 0
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id JOIN review_coding c ON c.review_id = r.review_id
UNION ALL
SELECT r.review_id, r.incident_id, 5, 'SS', 'Secondary source', s.secondary_source, s.secondary_source_title, c.secondary, c.secondary_alt,
       FIND_IN_SET('SS', c.inc_fields) > 0
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id JOIN review_coding c ON c.review_id = r.review_id;

-- Add proposed-code titles from the manual reference table
ALTER TABLE review_pairs ADD COLUMN my_title VARCHAR(255);
UPDATE review_pairs p
JOIN oiics_ref o ON o.code = p.my_code
 AND o.field = CASE p.field WHEN 'N' THEN 'nature' WHEN 'P' THEN 'part'
                            WHEN 'E' THEN 'event'  ELSE 'source' END
SET p.my_title = o.title;

-- Comparison table. Level agreement rule: two codes agree at level k when their
-- first k digits match, or when one code is a heading (prefix) of the other.
-- Levels: 1 = division, 2 = major group, 3 = minor group, 4 = exact code.
DROP TABLE IF EXISTS review_comparison;
CREATE TABLE review_comparison AS
SELECT p.*,
       (p.rec_code = p.my_code)                                         AS exact_match,
       (p.rec_code <> p.my_code AND FIND_IN_SET(p.rec_code, p.my_alt) > 0) AS alt_match,
       (LEFT(p.rec_code,3) = LEFT(p.my_code,3)
         OR p.my_code  = LEFT(p.rec_code, LENGTH(p.my_code))
         OR p.rec_code = LEFT(p.my_code,  LENGTH(p.rec_code)))          AS agree_minor,
       (LEFT(p.rec_code,2) = LEFT(p.my_code,2)
         OR p.my_code  = LEFT(p.rec_code, LENGTH(p.my_code))
         OR p.rec_code = LEFT(p.my_code,  LENGTH(p.rec_code)))          AS agree_major,
       (LEFT(p.rec_code,1) = LEFT(p.my_code,1))                         AS agree_division,
       CASE WHEN p.rec_code = p.my_code                              THEN '1 Exact'
            WHEN p.rec_code LIKE CONCAT(p.my_code, '%')              THEN '2 Recorded is a more specific child of proposed'
            WHEN p.my_code  LIKE CONCAT(p.rec_code, '%')             THEN '3 Recorded is a less specific parent of proposed'
            WHEN LEFT(p.rec_code,3) = LEFT(p.my_code,3)             THEN '4 Same minor group (3-digit)'
            WHEN LEFT(p.rec_code,2) = LEFT(p.my_code,2)             THEN '5 Same major group (2-digit)'
            WHEN LEFT(p.rec_code,1) = LEFT(p.my_code,1)             THEN '6 Same division only'
            ELSE '7 Different division' END                          AS code_relation,
       CASE WHEN p.inconclusive = 1 THEN 'N'          -- inconclusive at blind stage
            WHEN p.rec_code = p.my_code THEN 'X'
            ELSE a.category_code END                                 AS category_code,
       a.reviewer_note
FROM review_pairs p
LEFT JOIN review_adjudication a ON a.review_id = p.review_id AND a.field = p.field;

-- Integrity: every difference has an adjudication; no adjudication without a difference
SELECT 'differences without adjudication' AS check_name, COUNT(*) AS n
FROM review_comparison WHERE rec_code <> my_code AND category_code IS NULL
UNION ALL
SELECT 'adjudication rows that are not differences', COUNT(*)
FROM review_adjudication a JOIN review_comparison c ON c.review_id = a.review_id AND c.field = a.field
WHERE c.rec_code = c.my_code
UNION ALL
SELECT 'comparison rows (expect 500)', COUNT(*) FROM review_comparison;

-- ---------------------------------------------------------------------
-- SECTION 3. AGREEMENT BY FIELD (explicit denominators, Wilson 95% CI)
-- eligible = reviewed - inconclusive. Inconclusive fields are reported
-- separately and are NOT counted as agreement or disagreement.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS result_agreement_by_field;
CREATE TABLE result_agreement_by_field AS
WITH f AS (
  SELECT field_no, field_name,
         COUNT(*)                                   AS reviewed,
         SUM(inconclusive)                          AS inconclusive,
         SUM(inconclusive = 0)                      AS eligible,
         SUM(inconclusive = 0 AND exact_match)      AS exact,
         SUM(inconclusive = 0 AND (exact_match OR alt_match)) AS exact_or_alternate,
         SUM(inconclusive = 0 AND agree_minor)      AS minor_group,
         SUM(inconclusive = 0 AND agree_major)      AS major_group,
         SUM(inconclusive = 0 AND agree_division)   AS division
  FROM review_comparison GROUP BY field_no, field_name
)
SELECT field_no, field_name, reviewed, inconclusive, eligible,
       exact, ROUND(100*exact/eligible,1)              AS exact_pct,
       ROUND(100*( (exact/eligible + 1.96*1.96/(2*eligible))
            - 1.96*SQRT(exact/eligible*(1-exact/eligible)/eligible + 1.96*1.96/(4*eligible*eligible)) )
            / (1 + 1.96*1.96/eligible),1)              AS exact_ci_low,
       ROUND(100*( (exact/eligible + 1.96*1.96/(2*eligible))
            + 1.96*SQRT(exact/eligible*(1-exact/eligible)/eligible + 1.96*1.96/(4*eligible*eligible)) )
            / (1 + 1.96*1.96/eligible),1)              AS exact_ci_high,
       exact_or_alternate, ROUND(100*exact_or_alternate/eligible,1) AS exact_or_alt_pct,
       minor_group, ROUND(100*minor_group/eligible,1)  AS minor_group_pct,
       major_group, ROUND(100*major_group/eligible,1)  AS major_group_pct,
       division,    ROUND(100*division/eligible,1)     AS division_pct
FROM f ORDER BY field_no;
SELECT * FROM result_agreement_by_field;

-- ---------------------------------------------------------------------
-- SECTION 4. ADJUDICATED CATEGORIES BY FIELD (all 100 incidents per field)
-- Every field falls in exactly one category, so each row sums to 100.
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS result_categories_by_field;
CREATE TABLE result_categories_by_field AS
SELECT c.field_no, c.field_name,
       SUM(c.category_code = 'X')  AS exact_agreement,
       SUM(c.category_code = 'R')  AS explained_recorded_supported,
       SUM(c.category_code = 'G')  AS explained_rule_interpretation,
       SUM(c.category_code = 'Ps') AS potential_less_specific,
       SUM(c.category_code = 'Pc') AS potential_conflict,
       SUM(c.category_code = 'N')  AS insufficient_information,
       COUNT(*)                    AS total
FROM review_comparison c
GROUP BY c.field_no, c.field_name ORDER BY c.field_no;
SELECT * FROM result_categories_by_field;

-- Same view as a long table (useful for charts) with percentages
DROP TABLE IF EXISTS result_category_long;
CREATE TABLE result_category_long AS
SELECT c.field_no, c.field_name, l.sort_order, l.category_code, l.category_name, l.category_group,
       COUNT(*) AS n, ROUND(100*COUNT(*)/100,1) AS pct_of_100
FROM review_comparison c JOIN category_lookup l ON l.category_code = c.category_code
GROUP BY c.field_no, c.field_name, l.sort_order, l.category_code, l.category_name, l.category_group
ORDER BY c.field_no, l.sort_order;

-- Consistent-after-review rate: exact + explained, among fields that were not inconclusive
DROP TABLE IF EXISTS result_adjudicated_consistency;
CREATE TABLE result_adjudicated_consistency AS
SELECT c.field_no, c.field_name,
       SUM(c.category_code IN ('X','R','G','Ps','Pc')) AS conclusive_fields,
       SUM(c.category_code IN ('X','R','G'))           AS consistent_after_review,
       ROUND(100*SUM(c.category_code IN ('X','R','G'))/SUM(c.category_code IN ('X','R','G','Ps','Pc')),1) AS consistent_pct,
       SUM(c.category_code IN ('Ps','Pc'))             AS potential_discrepancies,
       ROUND(100*SUM(c.category_code IN ('Ps','Pc'))/SUM(c.category_code IN ('X','R','G','Ps','Pc')),1) AS potential_pct,
       SUM(c.category_code = 'N')                      AS inconclusive
FROM review_comparison c GROUP BY c.field_no, c.field_name ORDER BY c.field_no;
SELECT * FROM result_adjudicated_consistency;

-- ---------------------------------------------------------------------
-- SECTION 5. HOW DIFFERENT ARE THE CODES WHEN THEY DIFFER?
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS result_code_relation;
CREATE TABLE result_code_relation AS
SELECT field_name, code_relation, COUNT(*) AS n
FROM review_comparison
WHERE inconclusive = 0
GROUP BY field_name, code_relation
ORDER BY field_name, code_relation;
SELECT * FROM result_code_relation;

-- ---------------------------------------------------------------------
-- SECTION 6. INCIDENT-LEVEL VIEW
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS review_incident_summary;
CREATE TABLE review_incident_summary AS
SELECT review_id, incident_id,
       SUM(category_code = 'X')            AS fields_exact,
       SUM(category_code IN ('R','G'))     AS fields_explained,
       SUM(category_code IN ('Ps','Pc'))   AS fields_potential,
       SUM(category_code = 'N')            AS fields_inconclusive,
       SUM(category_code = 'Pc')           AS fields_conflict
FROM review_comparison GROUP BY review_id, incident_id;

DROP TABLE IF EXISTS result_incident_level;
CREATE TABLE result_incident_level AS
SELECT 'All five fields exact' AS measure, SUM(fields_exact = 5) AS incidents, 100 AS denominator FROM review_incident_summary
UNION ALL SELECT 'No potential discrepancy in any field (exact or explained or inconclusive only)', SUM(fields_potential = 0), 100 FROM review_incident_summary
UNION ALL SELECT 'At least one potential discrepancy', SUM(fields_potential >= 1), 100 FROM review_incident_summary
UNION ALL SELECT 'At least one conflicting-content discrepancy (Pc)', SUM(fields_conflict >= 1), 100 FROM review_incident_summary
UNION ALL SELECT 'At least one inconclusive field', SUM(fields_inconclusive >= 1), 100 FROM review_incident_summary;
SELECT * FROM result_incident_level;

-- ---------------------------------------------------------------------
-- SECTION 7. WHERE DO THE POTENTIAL DISCREPANCIES CLUSTER?
-- ---------------------------------------------------------------------
-- 7a. By recorded Event division (sampling stratum)
DROP TABLE IF EXISTS result_by_event_division;
CREATE TABLE result_by_event_division AS
SELECT sm.event_division, COUNT(DISTINCT sm.review_id) AS incidents,
       SUM(c.category_code IN ('Ps','Pc')) AS potential_discrepancy_fields,
       ROUND(SUM(c.category_code IN ('Ps','Pc'))/COUNT(DISTINCT sm.review_id),2) AS per_incident
FROM review_sample sm JOIN review_comparison c ON c.review_id = sm.review_id
GROUP BY sm.event_division ORDER BY sm.event_division;
SELECT * FROM result_by_event_division;

-- 7b. Most common recorded/proposed pairs among potential discrepancies
DROP TABLE IF EXISTS result_potential_discrepancy_detail;
CREATE TABLE result_potential_discrepancy_detail AS
SELECT c.review_id, c.incident_id, c.field_name, c.rec_code, c.rec_title, c.my_code, c.my_title,
       c.code_relation, l.category_name, c.reviewer_note
FROM review_comparison c JOIN category_lookup l ON l.category_code = c.category_code
WHERE c.category_code IN ('Ps','Pc')
ORDER BY l.sort_order DESC, c.field_no, c.review_id;
SELECT * FROM result_potential_discrepancy_detail;

-- ---------------------------------------------------------------------
-- SECTION 8. CONTEXT: HOW OFTEN DOES THE RECORDED DATA USE A NON-SPECIFIC CODE?
-- (population-level, all 9,034 incidents; from the data-quality audit)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS result_unspecified_share;
CREATE TABLE result_unspecified_share AS
SELECT 'Nature' AS field_name, COUNT(*) AS records,
       SUM(nature_title REGEXP 'unspecified|n\\.e\\.c\\.') AS nonspecific,
       ROUND(100*SUM(nature_title REGEXP 'unspecified|n\\.e\\.c\\.')/COUNT(*),1) AS pct FROM sir_2024
UNION ALL SELECT 'Part of body', COUNT(*), SUM(part_of_body_title REGEXP 'unspecified|n\\.e\\.c\\.'),
       ROUND(100*SUM(part_of_body_title REGEXP 'unspecified|n\\.e\\.c\\.')/COUNT(*),1) FROM sir_2024
UNION ALL SELECT 'Event/Exposure', COUNT(*), SUM(event_title REGEXP 'unspecified|n\\.e\\.c\\.'),
       ROUND(100*SUM(event_title REGEXP 'unspecified|n\\.e\\.c\\.')/COUNT(*),1) FROM sir_2024
UNION ALL SELECT 'Source', COUNT(*), SUM(source_title REGEXP 'unspecified|n\\.e\\.c\\.'),
       ROUND(100*SUM(source_title REGEXP 'unspecified|n\\.e\\.c\\.')/COUNT(*),1) FROM sir_2024
UNION ALL SELECT 'Secondary source', COUNT(*), SUM(secondary_source_title REGEXP 'unspecified|n\\.e\\.c\\.'),
       ROUND(100*SUM(secondary_source_title REGEXP 'unspecified|n\\.e\\.c\\.')/COUNT(*),1) FROM sir_2024;
SELECT * FROM result_unspecified_share;

-- ---------------------------------------------------------------------
-- SECTION 9. REPRODUCIBILITY CHECKS
-- ---------------------------------------------------------------------
SELECT 'sample incidents all in 2024' AS check_name,
       SUM(s.event_date >= '2024-01-01' AND s.event_date < '2025-01-01') AS passed, COUNT(*) AS total
FROM review_sample r JOIN sir_2024 s ON s.incident_id = r.incident_id
UNION ALL
SELECT 'category totals per field = 100 (rows ok)', SUM(total = 100), COUNT(*) FROM result_categories_by_field
UNION ALL
SELECT 'reviewed = eligible + inconclusive (rows ok)', SUM(reviewed = eligible + inconclusive), COUNT(*) FROM result_agreement_by_field;
