# OIICS 3.03 working reference sheet

Short reference used while reviewing narratives. It summarises the structure of the manual and the rules of selection that mattered in this audit. It is a working summary, not a replacement for the manual.

**Source:** Bureau of Labor Statistics, *Occupational Injury and Illness Classification System (OIICS), Version 3.03*, May 2026 (workbook supplied with the project; code table extracted to `oiics_303_codes.csv`, 2,891 codes: Nature 611, Part of body 207, Event 420, Source/Secondary source 1,653).

## 1. The five coded fields

| Field | Question it answers | Code hierarchy |
|---|---|---|
| Nature of injury or illness | What physical condition resulted? | 1-digit division, 2-digit major group, 3-digit minor group, 4-digit detail |
| Part of body affected | Which body part does that nature affect? | same |
| Event or exposure | What harmful incident or exposure produced it? | same; codes are listed in a **numeric order of precedence** |
| Source of injury or illness | What object, substance, person or condition created the hazard? | same |
| Secondary source | What contributed to the event or is named by the Event's "Coding interactions"? | same code list as Source |

Only the most detailed ("leaf") codes are assignable. Heading codes (shown with a trailing "s" in the manual hierarchy) are not used for coding. Recorded OSHA data never contains heading codes (checked in DQ19).

## 2. Rules of selection used in this audit

| Field | Rule (paraphrased) | Where it mattered |
|---|---|---|
| Nature R1 | If one injury is named, choose the highest level of detail the case information supports | "Head injury" alone does not support an intracranial code |
| Nature R2.a | Known traumatic event but unknown exact nature: most detailed code available; if no 2-digit group fits, use Nature 10* (unspecified traumatic) | Nature 100 / 110 choices |
| Nature R3 | Two or more injury types of about equal severity: use the multiple-nature code if one exists (codes ending in 8); injuries spanning groups go to Nature 18* | Fracture plus compartment syndrome; brain injury plus fractures |
| Nature R4.a | Do not use a multiple Nature when one injury type affects several body parts | Wrist and tibia fractures stay Nature 124 |
| Part R1 | Name the part affected by the chosen Nature; highest level of detail supported | Thigh vs "leg" |
| Part R2.a.1 | Traumatic injuries to the exterior or musculoskeletal structures: code the **external** part | Lumbar sprain gives back, lumbar |
| Part R2.a.2 | Injury to an internal organ or major vessel: code the specific organ if known | Large intestine (3333), lung (3123) |
| Part R2.c | Systemic reactions (Nature 16*, 17*) use Part 6, Body systems | Anaphylaxis, asthma |
| Part R3 / R4 | Multiple-part codes (ending in 8) when parts cannot be captured by one code; not for left and right of the same part | Both thumbs: Part 4422 |
| Event R1, R2.a | Choose the event that best describes the incident; first remove events that neither initiated the chain nor directly produced the injury | Struck by machine then fall: the machine contact only |
| Event R2.b | If more than one event qualifies, choose the one that appears **first in the numeric order of precedence** | Violence before fall; fall with contact before plain fall |
| Source R1 | Assign Event first, then follow that Event's "Coding interactions". A Secondary source must be assigned for every case: 991 if none applies, 990 if one exists but cannot be identified | All secondary-source comparisons |
| Source R2 | Machines, tools, vehicles: code the whole object unless "Coding interactions" say otherwise. Buildings: code the structural element. Containers: the container, not contents, unless the contents inflicted the injury | Whole machine vs part |
| Source R3 | Division 9 codes are usually secondary sources | Heat, rain, waves |

## 3. Manual guidance for specific codes referenced in the findings

| Code(s) | What the manual says | Consequence for the audit |
|---|---|---|
| Nature 133 and 1591 | Friction burns are listed under both Abrasions (133) and Other burns, first degree (1591) | Difference counted as rule interpretation |
| Nature 1110 | Includes unspecified head injury when it mentions dizziness, visual disturbance or headache | Recorded 110/111 supported when such symptoms are in the narrative; not supported by "head injury" alone |
| Nature 159 / 1590 | 1590 includes chemical and heat burns together | Hot chemical splash can be 1590 or 1510 |
| Nature 168 | Combinations of systemic reactions, or systemic and skin reactions | Allergic reaction with welts and breathing difficulty |
| Event 42 | Includes tripping or falling over curbs; excludes falls down steps (41) | Curb trip fall: 42 and 4312 both arguable |
| Event 432 | Slip or trip **without** a fall | Not used where a fall is stated |
| Event 650 / 653 / 659 | 653 covers a person or clothing pulled into moving parts; 659 covers attached parts of running equipment | Table-saw blade contact is not "caught in" (653) |
| Event 119 | Intentional violence by another person, n.e.c. | Requires intent that a narrative must show |
| Source 6352 | Poles supporting power, telephone or **area lighting** equipment; lamppost; street lights | "Light post" is 6352 |

## 4. Conventions used in the audit

* Unspecified (code ending in 0) and n.e.c. (code ending in 9) are treated as "non-specific" codes when measuring how often recorded data are non-specific (see `results/r09_nonspecific_share_all_2024.csv`).
* Agreement levels: exact code; same 3-digit minor group; same 2-digit major group; same 1-digit division. A heading code and its descendant count as agreeing at the heading's level.
* The recorded 2024 data were coded by OSHA with OIICS **Version 3.0**; this audit compares them with the later **3.03** manual. Titles of all recorded codes were checked and match 3.03 (DQ19, DQ20), but rule wording may have differed at the time of coding.
