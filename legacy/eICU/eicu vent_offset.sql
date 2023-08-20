DROP TABLE IF EXISTS `db_name.my_eICU.dummy` ;
CREATE TABLE `db_name.my_eICU.dummy` AS

-- Data from nursecare and respiratorycharting have no clear stop offset, but clear identifier for start of vent
-- used last occurrence of vent identifier as proxy for stop

-- Tables accessed
-- derived -> ventilation_events
-- original --> note, respiratorycharting, respiratorycare, notes, nursecare


-- why missing values in event?

WITH resp_chart AS (

  SELECT 
  patientunitstayid, 
  1 AS vent_yes,
  MIN(respchartvaluelabel) AS event,
  
  MIN(CASE 
  WHEN LOWER(respchartvaluelabel) LIKE "%endotracheal%"
  OR LOWER(respchartvaluelabel) LIKE "%ett%"
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"
  THEN respchartoffset
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN LOWER(respchartvaluelabel) LIKE "%endotracheal%" 
  OR LOWER(respchartvaluelabel) LIKE "%ett%" 
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"
  THEN respchartoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.respiratorycharting` AS rc

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = rc.patientunitstayid

  WHERE LOWER(respchartvaluelabel) LIKE "%endotracheal%" 
  OR LOWER(respchartvaluelabel) LIKE "%ett%" 
  OR LOWER(respchartvaluelabel) LIKE "%ET Tube%"

  GROUP BY patientunitstayid
)

, vent_nc AS (

  SELECT nc.patientunitstayid AS nc_pid, 
  1 AS vent_yes,
  MIN(cellattribute) AS event,
  
  MIN(CASE 
  WHEN (cellattribute = "Airway Size" OR cellattribute = "Airway Type") THEN nursecareentryoffset
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN (cellattribute = "Airway Size" OR cellattribute = "Airway Type") THEN nursecareentryoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.nursecare` AS nc

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = nc.patientunitstayid

  WHERE cellattribute = "Airway Size" 
  OR cellattribute = "Airway Type"

  GROUP BY patientunitstayid
)

, vent_note AS (

  SELECT patientunitstayid AS note_pid,
  1 AS vent_yes,
  MIN(notetype) AS event,

  MIN(CASE 
  WHEN notetype = "Intubation" THEN noteoffset
 ELSE 0
  END) AS vent_start_delta,

  MIN(CASE 
  WHEN notetype = "Extubation" THEN noteoffset
 ELSE 0
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.note` AS note

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = note.patientunitstayid

  WHERE notetype = "Intubation" OR notetype = "Extubation"

  GROUP BY patientunitstayid

) 

, vent_vente AS (

  SELECT patientunitstayid AS vent_pid, 
  1 AS vent_yes,
  MIN(event), 

  MIN(CASE 
  WHEN (event = "mechvent start" ) THEN (hrs*60)
 ELSE 0
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN (event = "mechvent end" ) THEN (hrs*60)
 ELSE 0
  END) AS vent_stop_delta,

  MAX(CASE 
  WHEN (event = "ICU Discharge" ) THEN (hrs*60)
 ELSE 0
  END) AS offset_discharge

  FROM `physionet-data.eicu_crd_derived.ventilation_events`

  WHERE event = "ICU Discharge" 
  OR event = "mechvent start"
  OR event = "mechvent end"

  GROUP BY patientunitstayid
) 

/*
airwaytype -> Oral ETT, Nasal ETT, Tracheostomy, Double-Lumen Tube (do not use -> Cricothyrotomy)
airwaysize -> all unless ""
airwayposition -> all unless: Other (Comment), deflated, mlt, Documentation undone

Heuristic for times 
use ventstartoffset for start of ventilation
use priorventendoffset for end of ventilation
*/

, resp_care AS (

  SELECT 
  patientunitstayid, 
  1 AS vent_yes,
  MIN(airwaytype) AS event,
  
  MIN(CASE 
  WHEN LOWER(airwaytype) LIKE "%ETT%"
  OR LOWER(airwaytype) LIKE "%Tracheostomy%"
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE "Documentation undone"
  THEN ventstartoffset
  ELSE NULL
  END) AS vent_start_delta,

  MAX(CASE 
  WHEN LOWER(airwaytype) LIKE "%ETT%" 
  OR LOWER(airwaytype) LIKE "%Tracheostomy%" 
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE "Documentation undone"
  THEN priorventendoffset
  ELSE NULL
  END) AS vent_stop_delta,

  MAX(offset_discharge) AS offset_discharge

  FROM `physionet-data.eicu_crd.respiratorycare` AS rcare

  LEFT JOIN(
  SELECT patientunitstayid AS pat_pid, unitdischargeoffset AS offset_discharge
  FROM `physionet-data.eicu_crd.patient`
  )
  AS pat
  ON pat.pat_pid = rcare.patientunitstayid

  WHERE LOWER(airwaytype) LIKE "%ETT%" 
  OR LOWER(airwaytype) LIKE "%Tracheostomy%" 
  OR LOWER(airwaytype) LIKE "%Tube%"
  OR LOWER(airwaysize) NOT LIKE ""
  OR LOWER(airwayposition) NOT LIKE "Other (Comment)"
  OR LOWER(airwayposition) NOT LIKE "deflated"
  OR LOWER(airwayposition) NOT LIKE "mlt"
  OR LOWER(airwayposition) NOT LIKE " Documentation undone"

  GROUP BY patientunitstayid
)

, union_table AS (

  SELECT * FROM resp_chart

  UNION DISTINCT

  SELECT * FROM vent_nc

  UNION DISTINCT

  SELECT * FROM vent_note

  UNION DISTINCT

  SELECT * FROM vent_vente
  
  UNION DISTINCT

  SELECT * FROM resp_care
)

SELECT 
patientunitstayid,
MAX(vent_yes) AS vent_yes,
STRING_AGG(event) AS event,
MIN(vent_start_delta) AS event_start_delta,
MAX(vent_stop_delta) AS vent_stop_delta,
MAX(offset_discharge) AS offset_discharge,

CASE 
WHEN (MAX(vent_stop_delta != 0) OR MAX(vent_stop_delta IS NOT NULL))
THEN (MAX(vent_stop_delta) - MIN(vent_start_delta))
ELSE (MAX(offset_discharge) - MIN(vent_start_delta))
END AS vent_duration

FROM union_table 

GROUP BY patientunitstayid
ORDER BY patientunitstayid, event
;

