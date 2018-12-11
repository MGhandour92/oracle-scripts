/* Formatted on 10/24/2018 10:23:17 AM (QP5 v5.256.13226.35538) */
--
--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--
--*--========----- Created by: Mohamed El Ghandour -----========-----*--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--


------------------ Staging Meter Table ----------------------

--DROP TABLE staging_meter_table;

CREATE TABLE staging_meter_table
(
   ID                 NUMBER GENERATED ALWAYS AS IDENTITY (         START WITH 1 INCREMENT BY 1),
   Name               VARCHAR2 (100),
   description        VARCHAR2 (1000),
   UOM                VARCHAR2 (100),
   Reading_type       NUMBER,
   value_change       NUMBER,
   Scheduling         VARCHAR2 (10),
   Rate               NUMBER,
   Intial_Reading     NUMBER,
--   Last_Reading       NUMBER,
   USE_PAST_READING   NUMBER,
   flag               VARCHAR2 (10),
   note               VARCHAR2 (50)
);

-------------------------------------------------------

SELECT * FROM staging_meter_table;

COMMIT;


-------------********************************************-------------

-- API

DECLARE
   l_return_status   VARCHAR2 (80);
   l_msg_count       NUMBER;
   l_msg_data        VARCHAR2 (2000);
   l_new_meter_id    NUMBER;

   CURSOR xx_data
   IS
      SELECT * FROM staging_meter_table;
BEGIN
   FOR i IN xx_data
   LOOP
      eam_meter_pub.create_meter (p_api_version           => 1.0,
                                  x_return_status         => l_return_status,
                                  x_msg_count             => l_msg_count,
                                  x_msg_data              => l_msg_data,
                                  p_meter_name            => i.name,
                                  p_meter_uom             => i.uom,
                                  p_METER_TYPE            => i.reading_type, -- 1 = value meter , 2 = change meter, Default 1
                                  p_VALUE_CHANGE_DIR      => i.value_change, -- 1 = ascending , 2 = descending Default 1
                                  p_USED_IN_SCHEDULING    => i.scheduling,
                                  p_DESCRIPTION           => i.description,
                                  p_FROM_EFFECTIVE_DATE   => SYSDATE,
                                  p_user_defined_rate     => i.rate,
                                  p_initial_reading       => i.intial_reading,                                  
                                  p_use_past_reading      => i.USE_PAST_READING,
                                  x_new_meter_id          => l_new_meter_id -- P_EAM_REQUIRED_FLAG Default 'N'
                                                                           );

      SWD_AUTON_DML (
            'UPDATE staging_pm_schedule_table SET flag =  '''
         || l_return_status
         || ''' , note = SUBSTR ( '''
         || l_msg_data
         || ''' , 5, LENGTH ( '''
         || l_msg_data
         || '''))  WHERE  ID IN ( '
         || i.ID
         || ')');
   END LOOP;

   IF l_return_status = fnd_api.g_ret_sts_success
   THEN
      COMMIT;
      DBMS_OUTPUT.put_line ('Successful');
   ELSE
      DBMS_OUTPUT.put_line (
         'Failed with error :' || l_msg_count || ' ' || l_return_status);
      ROLLBACK;
   END IF;
END;