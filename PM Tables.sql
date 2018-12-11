------------------ Staging Main PM Table ----------------------

DROP TABLE staging_pm_schedule_table;

CREATE TABLE staging_pm_schedule_table
(
   INSTANCE_NUMBER            VARCHAR2 (30),
   Name                       VARCHAR2 (100),
   SET_NAME_ID                NUMBER,
   FROM_EFFECTIVE_DATE        DATE,
   GENERATE_WO_STATUS         NUMBER,
   INTERVAL_PER_CYCLE         NUMBER,
   GENERATE_NEXT_WORK_ORDER   VARCHAR2 (1),
   NON_SCHEDULED_FLAG         VARCHAR2 (1),
   RESCHEDULING_POINT         NUMBER,
   DEFAULT_IMPLEMENT          VARCHAR2 (1),
   WHICHEVER_FIRST            VARCHAR2 (1),
   INCLUDE_MANUAL             VARCHAR2 (1),
   SCHEDULING_METHOD_CODE     NUMBER,
   AUTO_INSTANTIATION_FLAG    VARCHAR2 (1),
   TYPE_CODE                  NUMBER,
   flag                       VARCHAR2 (10),
   note                       VARCHAR2 (500)
);

-------------------------------------------------------

SELECT * FROM staging_pm_schedule_table;

COMMIT;


--For flag reset

UPDATE staging_pm_schedule_table
   SET FLAG = NULL, NOTE = NULL
 WHERE FLAG = 'E';


------------------ Activities Table ----------------------

DROP TABLE staging_activ_pm_table;

CREATE TABLE staging_activ_pm_table
(
   INSTANCE_NUMBER           VARCHAR2 (30),
   ACTIVITY                  VARCHAR2 (40),
   ACTIVITY_ASSOCIATION_ID   NUMBER,
   INTERVAL_MULTIPLE         NUMBER,
   ALLOW_REPEAT_IN_CYCLE     VARCHAR2 (1)
);


-- Import Data first

--*****************--
-- ** EAM queries to prepare ** --
--*****************--

--Get Activity Association ID regarding to the imported data

UPDATE staging_activ_pm_table pm
   SET pm.ACTIVITY_ASSOCIATION_ID =
          (SELECT ACTIVITY_ASSOCIATION_ID
             FROM MTL_EAM_ASSET_ACTIVITIES_V
            WHERE     ACTIVITY = pm.ACTIVITY
                  AND INSTANCE_NUMBER = pm.INSTANCE_NUMBER);


-------------------------------------------------------

SELECT * FROM staging_activ_pm_table;

COMMIT;

------------------ Rules Table ----------------------

DROP TABLE staging_rules_pm_table;

CREATE TABLE staging_rules_pm_table
(
   INSTANCE_NUMBER    VARCHAR2 (30),
   RULE_TYPE          NUMBER,
   METER_ID           NUMBER,
   LIST_DATE          DATE,
   RUNTIME_INTERVAL   NUMBER,
   day_interval       NUMBER
);


-- Import Data first

--*****************--
-- ** EAM queries to prepare ** --
--*****************--

--Get meter ID and interval from meters


--*****************--
-- **For Meters only ** --
--*****************--

UPDATE staging_rules_pm_table rpm
   SET rpm.METER_ID =
          (SELECT met.METER_ID
             FROM eam_asset_meters_v met
            WHERE met.ASSET_NUMBER = rpm.INSTANCE_NUMBER)
--       rpm.RUNTIME_INTERVAL =
--          (SELECT met2.USER_DEFINED_RATE
--             FROM eam_asset_meters_v met2
--            WHERE met2.ASSET_NUMBER = rpm.INSTANCE_NUMBER)
 WHERE RULE_TYPE = 2;                                 --meters


--*****************--
--*****************--

-------------------------------------------------------

SELECT * FROM staging_rules_pm_table;



COMMIT;


--
UPDATE staging_pm_schedule_table
   SET flag = NULL, note = NULL;
--
--
--UPDATE staging_pm_schedule_table
--   SET NAME = REPLACE (NAME, '-2', '-3');
--
--UPDATE staging_pm_schedule_table
--   SET SET_NAME_ID = 1014;
--
COMMIT;