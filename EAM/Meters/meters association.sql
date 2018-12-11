/* Formatted on 7/19/2018 12:06:51 PM (QP5 v5.256.13226.35538) */
--
--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--
--*--========----- Created by: Mohamed El Ghandour -----========-----*--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--


------------------ Staging Meter Association Table ----------------------

--DROP TABLE staging_meter_assoc_table;


CREATE TABLE staging_meter_assoc_table
(
   ID                NUMBER GENERATED ALWAYS AS IDENTITY (        START WITH 1 INCREMENT BY 1),
   meter_id          NUMBER,
   organization_id   NUMBER,
   asset_group_id    NUMBER,
   asset_number      VARCHAR2 (30),
   flag              VARCHAR2 (10),
   note              VARCHAR2 (50)
);


-- associate assets with meters
-- as in that scenario, the Assets and the meters had the same name

INSERT INTO staging_meter_assoc_table (meter_id,
                                       organization_id,
                                       asset_group_id,
                                       asset_number)
   (SELECT METER_ID AS METER_ID,
           ASS.INV_ORGANIZATION_ID AS organization_id,
           ASS.INVENTORY_ITEM_ID asset_group_id,
           ASS.SERIAL_NUMBER AS asset_number
      FROM EAM_COUNTERS_V MET, MTL_EAM_ASSET_NUMBERS_ALL_V ASS
     WHERE MET.METER_NAME = ASS.INSTANCE_NUMBER);


-------------------------------------------------------

SELECT * FROM staging_meter_assoc_table;

COMMIT;


-------------********************************************-------------


-- API

DECLARE
   CURSOR stage
   IS
      SELECT *
        FROM staging_meter_assoc_table
       WHERE flag IS NULL;

   l_stat    VARCHAR2 (10);
   l_count   NUMBER;
   l_data    VARCHAR2 (100);
BEGIN
   FOR i IN stage
   LOOP
      eam_meterassoc_pub.insert_assetmeterassoc (
         p_api_version       => 1.0,
         x_return_status     => l_stat,
         x_msg_count         => l_count,
         x_msg_data          => l_data,
         p_meter_id          => i.meter_id,
         p_organization_id   => i.organization_id,
         p_asset_group_id    => i.asset_group_id,
         p_asset_number      => i.asset_number);            --asset serial no.


      SWD_AUTON_DML (
            'UPDATE staging_meter_assoc_table SET flag =  '''
         || l_stat
         || ''' , note = SUBSTR ( '''
         || l_data
         || ''' , 5, LENGTH ( '''
         || l_data
         || '''))  WHERE  meter_id IN ( '
         || i.meter_id
         || ')');
   --DBMS_OUTPUT.put_line (l_stat || ' - ' || i.meter_id);
   END LOOP;

   IF l_return_status = fnd_api.g_ret_sts_success
   THEN
      COMMIT;
      DBMS_OUTPUT.put_line ('Successful');
   ELSE
      DBMS_OUTPUT.put_line (
         'Failed with the error :' || l_msg_count || ' ' || l_return_status);
      ROLLBACK;
   END IF;
END;