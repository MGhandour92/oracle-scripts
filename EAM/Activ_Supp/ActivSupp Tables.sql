/* Formatted on 7/31/2018 7:01:38 PM (QP5 v5.256.13226.35538) */
------------------ Staging Activity Suppression Table ----------------------

DROP TABLE staging_suppresion_table;

CREATE TABLE staging_suppresion_table
(
   ID                NUMBER,
   PARENT_ACTIV      VARCHAR2 (30),
   CHILD_ACTIV       VARCHAR2 (30),
   PARENT_ACTIV_ID   NUMBER,
   CHILD_ACTIV_ID    NUMBER,
   flag              VARCHAR2 (10),
   note              VARCHAR2 (500)
);


-- Import Data first

--*****************--
-- ** EAM queries to prepare ** --
--*****************--

--Get Activity Association ID regarding to the imported data


UPDATE staging_suppresion_table pm
   SET pm.PARENT_ACTIV_ID =
          (SELECT ACTIVITY_ASSOCIATION_ID
             FROM MTL_EAM_ASSET_ACTIVITIES_V
            WHERE ACTIVITY = pm.PARENT_ACTIV),
       pm.CHILD_ACTIV_ID =
          (SELECT ACTIVITY_ASSOCIATION_ID
             FROM MTL_EAM_ASSET_ACTIVITIES_V
            WHERE ACTIVITY = pm.CHILD_ACTIV);

COMMIT;