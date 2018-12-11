/* Formatted on 7/31/2018 6:59:47 PM (QP5 v5.256.13226.35538) */

--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--
--*--========----- Created by: Mohamed El Ghandour -----========-----*--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--

DECLARE
   CURSOR stage
   IS
      SELECT *
        FROM staging_suppresion_table
       WHERE flag IS NULL;

   l_count   NUMBER;
   l_data    VARCHAR2 (100);
   l_stat    VARCHAR2 (10);
BEGIN
   FOR i IN stage
   LOOP
      EAM_ActivitySupn_PUB.INSERT_ACTIVITYSUPN (
         p_api_version             => 1.0,
         x_return_status           => l_stat,
         x_msg_count               => l_count,
         x_msg_data                => l_data,
         p_parent_association_id   => i.PARENT_ACTIV_ID,
         p_child_association_id    => i.CHILD_ACTIV_ID,
         p_tmpl_flag               => 'N');

      -- Update flags and notes depending to the ID
      SWD_AUTON_DML (
            'UPDATE staging_suppresion_table SET flag =  '''
         || l_stat
         || ''' , note = '''
         || l_count
         || ' '
         || l_data
         || ''' WHERE ID = '''
         || i.ID
         || '''');

      IF l_stat = fnd_api.g_ret_sts_success
      THEN
         COMMIT;
         DBMS_OUTPUT.put_line ('Successful');
      ELSE
         DBMS_OUTPUT.put_line (
               'Failed with error :'
            || l_count
            || ' '
            || l_stat
            || ' '
            || l_data);
         ROLLBACK;
      END IF;
   END LOOP;
END;