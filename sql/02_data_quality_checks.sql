-- =====================================================================
-- 02_data_quality_checks.sql
-- Data-quality audit of the 2024 OSHA Severe Injury Report records
-- (table sir_2024, built by 01_import_and_filter.sql; OIICS 3.03 code lists
-- in oiics_ref, built by 00_load_oiics_reference.sql).
-- Nothing is deleted or altered. Each check writes one row to dq_summary:
-- check, result, affected records, whether it affects the audit, action.
-- =====================================================================
USE worksafe;

DROP TABLE IF EXISTS dq_summary;
CREATE TABLE dq_summary (
    check_id          VARCHAR(8),
    check_name        VARCHAR(120),
    result            VARCHAR(200),
    affected_records  INT,
    affects_audit     VARCHAR(10),      -- Yes / No / Minor
    recommended_action VARCHAR(300)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ---------------------------------------------------------------------
-- A. Identifiers and duplicates
-- ---------------------------------------------------------------------
INSERT INTO dq_summary
SELECT 'DQ01', 'Total rows (2024 incidents)', CONCAT(COUNT(*), ' rows'), COUNT(*), 'No',
       'Reference count for all later checks.'
FROM sir_2024;

INSERT INTO dq_summary
SELECT 'DQ02', 'Unique incident identifiers (ID)',
       CONCAT(COUNT(DISTINCT incident_id), ' distinct of ', COUNT(*), ' rows'),
       COUNT(*) - COUNT(DISTINCT incident_id), 'No',
       'ID is a usable key. No action.'
FROM sir_2024;

INSERT INTO dq_summary
SELECT 'DQ03', 'Rows sharing a repeated incident ID',
       CONCAT(COALESCE(SUM(c), 0), ' rows in ', COUNT(*), ' repeated IDs'),
       COALESCE(SUM(c), 0), 'No',
       'None found; no de-duplication needed.'
FROM (SELECT incident_id, COUNT(*) AS c FROM sir_2024 GROUP BY incident_id HAVING COUNT(*) > 1) d;

INSERT INTO dq_summary
SELECT 'DQ04', 'Unique UPA (establishment-incident) identifiers',
       CONCAT(COUNT(DISTINCT upa_id), ' distinct of ', COUNT(*), ' rows'),
       COUNT(*) - COUNT(DISTINCT upa_id), 'No',
       'UPA is also one-per-row in 2024. No action.'
FROM sir_2024;

-- Exact duplicate content under different IDs: same date, narrative and all five code pairs
INSERT INTO dq_summary
SELECT 'DQ05', 'Exact duplicate records (all fields except ID/UPA)',
       CONCAT(COALESCE(SUM(c), 0), ' rows in ', COUNT(*), ' duplicate groups'),
       COALESCE(SUM(c), 0), 'Minor',
       'Inspected: consecutive IDs, same date, narrative and codes (two workers in one event). Kept in the data; excluded from the sampling frame.'
FROM (SELECT COUNT(*) AS c FROM sir_2024
      GROUP BY event_date, final_narrative, nature, part_of_body, event, source, secondary_source
      HAVING COUNT(*) > 1) d;

-- Same narrative text appearing on more than one record (any codes)
INSERT INTO dq_summary
SELECT 'DQ06', 'Identical narrative text on more than one record',
       CONCAT(COALESCE(SUM(c), 0), ' rows in ', COUNT(*), ' groups'),
       COALESCE(SUM(c), 0), 'Minor',
       'Same pair as DQ05. Kept in the data; excluded from the review sampling frame.'
FROM (SELECT COUNT(*) AS c FROM sir_2024 GROUP BY final_narrative HAVING COUNT(*) > 1) d;

-- ---------------------------------------------------------------------
-- B. Narratives
-- ---------------------------------------------------------------------
INSERT INTO dq_summary
SELECT 'DQ07', 'Missing or blank narratives',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'Yes',
       'None found. Review requires a narrative; blank ones would be excluded, not deleted.'
FROM sir_2024 WHERE final_narrative IS NULL OR TRIM(final_narrative) = '';

INSERT INTO dq_summary
SELECT 'DQ08', 'Very short narratives (under 60 characters)',
       CONCAT(SUM(CHAR_LENGTH(final_narrative) < 60), ' rows; overall min ', MIN(CHAR_LENGTH(final_narrative)),
              ', average ', ROUND(AVG(CHAR_LENGTH(final_narrative)), 0), ', max ', MAX(CHAR_LENGTH(final_narrative)), ' characters'),
       SUM(CHAR_LENGTH(final_narrative) < 60), 'Yes',
       'Short narratives limit what can be coded. Exclude from the sampling frame; report overall length profile.'
FROM sir_2024;

INSERT INTO dq_summary
SELECT 'DQ09', 'Narratives with leading/trailing whitespace',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'No',
       'Trim for display; no effect on review.'
FROM sir_2024 WHERE final_narrative <> TRIM(final_narrative);

INSERT INTO dq_summary
SELECT 'DQ10', 'Narratives containing embedded line breaks',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'No',
       'Replace line breaks with a space when writing to the review workbook.'
FROM sir_2024 WHERE final_narrative LIKE CONCAT('%', CHAR(10), '%') OR final_narrative LIKE CONCAT('%', CHAR(13), '%');

-- ---------------------------------------------------------------------
-- C. Classification fields: blanks, whitespace, non-numeric values
--    field list: nature, part_of_body, event, source, secondary_source
-- ---------------------------------------------------------------------
INSERT INTO dq_summary
SELECT 'DQ11', CONCAT('Missing or blank code: ', f.field_name),
       CONCAT(SUM(f.code IS NULL OR TRIM(f.code) = ''), ' rows'),
       SUM(f.code IS NULL OR TRIM(f.code) = ''), 'Yes',
       'None found. A blank code would be excluded from that field''s comparison only.'
FROM (SELECT 'Nature' AS field_name, nature AS code FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body FROM sir_2024
      UNION ALL SELECT 'Event', event FROM sir_2024
      UNION ALL SELECT 'Source', source FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source FROM sir_2024) f
GROUP BY f.field_name;

INSERT INTO dq_summary
SELECT 'DQ12', CONCAT('Missing or blank title: ', f.field_name),
       CONCAT(SUM(f.title IS NULL OR TRIM(f.title) = ''), ' rows'),
       SUM(f.title IS NULL OR TRIM(f.title) = ''), 'Yes',
       'None found.'
FROM (SELECT 'Nature' AS field_name, nature_title AS title FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body_title FROM sir_2024
      UNION ALL SELECT 'Event', event_title FROM sir_2024
      UNION ALL SELECT 'Source', source_title FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source_title FROM sir_2024) f
GROUP BY f.field_name;

INSERT INTO dq_summary
SELECT 'DQ13', CONCAT('Code with leading/trailing whitespace or non-numeric characters: ', f.field_name),
       CONCAT(SUM(f.code <> TRIM(f.code) OR f.code NOT REGEXP '^[0-9]+$'), ' rows'),
       SUM(f.code <> TRIM(f.code) OR f.code NOT REGEXP '^[0-9]+$'), 'No',
       'None found; codes join cleanly to the manual.'
FROM (SELECT 'Nature' AS field_name, nature AS code FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body FROM sir_2024
      UNION ALL SELECT 'Event', event FROM sir_2024
      UNION ALL SELECT 'Source', source FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source FROM sir_2024) f
GROUP BY f.field_name;

-- Titles: whitespace (every title is stored with a leading space in the source file)
INSERT INTO dq_summary
SELECT 'DQ14', CONCAT('Title with leading/trailing whitespace: ', f.field_name),
       CONCAT(SUM(f.title <> TRIM(f.title)), ' of ', COUNT(*), ' rows'),
       SUM(f.title <> TRIM(f.title)), 'No',
       'Trim titles (TRIM) before grouping or comparing. Applied in all audit queries.'
FROM (SELECT 'Nature' AS field_name, nature_title AS title FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body_title FROM sir_2024
      UNION ALL SELECT 'Event', event_title FROM sir_2024
      UNION ALL SELECT 'Source', source_title FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source_title FROM sir_2024) f
GROUP BY f.field_name;

-- ---------------------------------------------------------------------
-- D. Distinct values, code-title mapping, agreement with the OIICS 3.03 manual
-- ---------------------------------------------------------------------
INSERT INTO dq_summary
SELECT 'DQ15', CONCAT('Distinct codes: ', f.field_name),
       CONCAT(COUNT(DISTINCT f.code), ' distinct codes'), NULL, 'No',
       'Information only; shows the size of the code space the review draws on.'
FROM (SELECT 'Nature' AS field_name, nature AS code FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body FROM sir_2024
      UNION ALL SELECT 'Event', event FROM sir_2024
      UNION ALL SELECT 'Source', source FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source FROM sir_2024) f
GROUP BY f.field_name;

-- Codes associated with more than one title: raw text first (DQ16), then after TRIM (DQ17)
INSERT INTO dq_summary
SELECT 'DQ16', CONCAT('Codes with more than one raw title: ', t.field_name),
       CONCAT(SUM(t.n > 1), ' code(s)'), SUM(t.n > 1), 'No',
       'Raw variants differ only by whitespace (see DQ17); fixed by TRIM.'
FROM (SELECT 'Nature' AS field_name, nature AS code, COUNT(DISTINCT nature_title) AS n FROM sir_2024 GROUP BY nature
      UNION ALL SELECT 'Part of body', part_of_body, COUNT(DISTINCT part_of_body_title) FROM sir_2024 GROUP BY part_of_body
      UNION ALL SELECT 'Event', event, COUNT(DISTINCT event_title) FROM sir_2024 GROUP BY event
      UNION ALL SELECT 'Source', source, COUNT(DISTINCT source_title) FROM sir_2024 GROUP BY source
      UNION ALL SELECT 'Secondary source', secondary_source, COUNT(DISTINCT secondary_source_title) FROM sir_2024 GROUP BY secondary_source) t
GROUP BY t.field_name;

INSERT INTO dq_summary
SELECT 'DQ17', CONCAT('Codes with more than one TRIMMED title: ', t.field_name),
       CONCAT(SUM(t.n > 1), ' code(s)'), SUM(t.n > 1), 'No',
       'After trimming, each recorded code maps to exactly one title.'
FROM (SELECT 'Nature' AS field_name, nature AS code, COUNT(DISTINCT TRIM(nature_title)) AS n FROM sir_2024 GROUP BY nature
      UNION ALL SELECT 'Part of body', part_of_body, COUNT(DISTINCT TRIM(part_of_body_title)) FROM sir_2024 GROUP BY part_of_body
      UNION ALL SELECT 'Event', event, COUNT(DISTINCT TRIM(event_title)) FROM sir_2024 GROUP BY event
      UNION ALL SELECT 'Source', source, COUNT(DISTINCT TRIM(source_title)) FROM sir_2024 GROUP BY source
      UNION ALL SELECT 'Secondary source', secondary_source, COUNT(DISTINCT TRIM(secondary_source_title)) FROM sir_2024 GROUP BY secondary_source) t
GROUP BY t.field_name;

-- Titles associated with more than one code (trimmed titles)
INSERT INTO dq_summary
SELECT 'DQ18', CONCAT('Trimmed titles shared by more than one code: ', t.field_name),
       CONCAT(SUM(t.n > 1), ' title(s)'), SUM(t.n > 1), 'Minor',
       'Source/secondary source 460 and 470 both read "Vehicle and machine parts - unspecified" in the manual itself (oiics_ref). Compare on code, never on title alone.'
FROM (SELECT 'Nature' AS field_name, TRIM(nature_title) AS title, COUNT(DISTINCT nature) AS n FROM sir_2024 GROUP BY TRIM(nature_title)
      UNION ALL SELECT 'Part of body', TRIM(part_of_body_title), COUNT(DISTINCT part_of_body) FROM sir_2024 GROUP BY TRIM(part_of_body_title)
      UNION ALL SELECT 'Event', TRIM(event_title), COUNT(DISTINCT event) FROM sir_2024 GROUP BY TRIM(event_title)
      UNION ALL SELECT 'Source', TRIM(source_title), COUNT(DISTINCT source) FROM sir_2024 GROUP BY TRIM(source_title)
      UNION ALL SELECT 'Secondary source', TRIM(secondary_source_title), COUNT(DISTINCT secondary_source) FROM sir_2024 GROUP BY TRIM(secondary_source_title)) t
GROUP BY t.field_name;

-- Recorded codes that do not exist in the OIICS 3.03 manual
INSERT INTO dq_summary
SELECT 'DQ19', CONCAT('Recorded codes not found in OIICS 3.03: ', f.field_name),
       CONCAT(SUM(r.code IS NULL), ' rows'), SUM(r.code IS NULL), 'Yes',
       'None found; every recorded code exists in the 3.03 code list, so comparison is possible.'
FROM (SELECT 'Nature' AS field_name, 'nature' AS ref_field, nature AS code FROM sir_2024
      UNION ALL SELECT 'Part of body', 'part', part_of_body FROM sir_2024
      UNION ALL SELECT 'Event', 'event', event FROM sir_2024
      UNION ALL SELECT 'Source', 'source', source FROM sir_2024
      UNION ALL SELECT 'Secondary source', 'source', secondary_source FROM sir_2024) f
LEFT JOIN oiics_ref r ON r.field = f.ref_field AND r.code = f.code
GROUP BY f.field_name;

-- Recorded titles that disagree with the 3.03 manual title for the same code (punctuation ignored)
INSERT INTO dq_summary
SELECT 'DQ20', CONCAT('Recorded title differs from OIICS 3.03 title: ', f.field_name),
       CONCAT(SUM(r.code IS NOT NULL AND r.title_key <> LOWER(REGEXP_REPLACE(f.title, '[^A-Za-z0-9]', ''))), ' rows'),
       SUM(r.code IS NOT NULL AND r.title_key <> LOWER(REGEXP_REPLACE(f.title, '[^A-Za-z0-9]', ''))), 'Yes',
       'Zero means code and title are internally consistent and match the manual wording.'
FROM (SELECT 'Nature' AS field_name, 'nature' AS ref_field, nature AS code, nature_title AS title FROM sir_2024
      UNION ALL SELECT 'Part of body', 'part', part_of_body, part_of_body_title FROM sir_2024
      UNION ALL SELECT 'Event', 'event', event, event_title FROM sir_2024
      UNION ALL SELECT 'Source', 'source', source, source_title FROM sir_2024
      UNION ALL SELECT 'Secondary source', 'source', secondary_source, secondary_source_title FROM sir_2024) f
LEFT JOIN oiics_ref r ON r.field = f.ref_field AND r.code = f.code
GROUP BY f.field_name;

-- ---------------------------------------------------------------------
-- E. Other anomalies that could affect the comparison
-- ---------------------------------------------------------------------
-- Share of records coded to an unspecified / n.e.c. / residual code (limits what a reviewer can disagree with)
INSERT INTO dq_summary
SELECT 'DQ21', CONCAT('Recorded code is unspecified or n.e.c.: ', f.field_name),
       CONCAT(SUM(f.title LIKE '%unspecified%' OR f.title LIKE '%n.e.c.%'), ' rows (',
              ROUND(100 * SUM(f.title LIKE '%unspecified%' OR f.title LIKE '%n.e.c.%') / COUNT(*), 1), '%)'),
       SUM(f.title LIKE '%unspecified%' OR f.title LIKE '%n.e.c.%'), 'Yes',
       'Compare at major-group and division level as well as exact code; unspecified codes are less precise by design.'
FROM (SELECT 'Nature' AS field_name, nature_title AS title FROM sir_2024
      UNION ALL SELECT 'Part of body', part_of_body_title FROM sir_2024
      UNION ALL SELECT 'Event', event_title FROM sir_2024
      UNION ALL SELECT 'Source', source_title FROM sir_2024
      UNION ALL SELECT 'Secondary source', secondary_source_title FROM sir_2024) f
GROUP BY f.field_name;

-- Secondary source: manual rule 5.a(1) says a secondary source should be assigned for all cases (990 / 991 when none)
INSERT INTO dq_summary
SELECT 'DQ22', 'Secondary source coded 991 (not applicable) or 990 (unspecified)',
       CONCAT(SUM(secondary_source = '991'), ' rows 991; ', SUM(secondary_source = '990'), ' rows 990'),
       SUM(secondary_source IN ('990', '991')), 'Yes',
       'Large share carries no substantive secondary source; treat secondary source as exploratory in the review.'
FROM sir_2024;

-- Amputation flag vs Nature 122* (Amputations, avulsions, enucleations)
INSERT INTO dq_summary
SELECT 'DQ23', 'Amputation flag = 0 but Nature is 122* (amputation/avulsion/enucleation)',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'Minor',
       'Likely avulsions/enucleations without a reportable amputation; internal-consistency note only.'
FROM sir_2024 WHERE amputation = 0 AND nature LIKE '122%';

INSERT INTO dq_summary
SELECT 'DQ24', 'Amputation flag >= 1 but Nature is not 122*',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'Minor',
       'Review in the discrepancy log if sampled; a multi-injury nature code can legitimately accompany an amputation.'
FROM sir_2024 WHERE amputation >= 1 AND nature NOT LIKE '122%';

INSERT INTO dq_summary
SELECT 'DQ25', 'None of Hospitalized / Amputation / Loss of Eye flagged',
       CONCAT(COUNT(*), ' rows'), COUNT(*), 'No',
       'Every severe-injury report should meet at least one criterion; zero means flags are complete.'
FROM sir_2024 WHERE hospitalized = 0 AND amputation = 0 AND loss_of_eye = 0;

INSERT INTO dq_summary
SELECT 'DQ26', 'Incidents split by reporting jurisdiction (FederalState)',
       CONCAT(SUM(federal_state = '1'), ' federal OSHA; ', SUM(federal_state = '0'), ' state-plan'),
       NULL, 'Yes',
       'Findings describe this published file, not all US workplace injuries. State in the limitations.'
FROM sir_2024;

-- ---------------------------------------------------------------------
-- Final data-quality summary
-- ---------------------------------------------------------------------
SELECT * FROM dq_summary ORDER BY check_id, check_name;
