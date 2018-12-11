--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--
--*--========----- Created by: Mohamed El Ghandour -----========-----*--
--*----------========----------========----------========------------*--
--*----------========----------========----------========------------*--

-------------  Consider you have the structure below ------------------
------------- PM ------------ As a parent Record has two types of children
---------------- Activities ---------- As Child Table for the parent PM record
---------------- Rules ---------- As Child Table for the parent PM record

--*****************--
-- ** EAM Views ** --
--*****************--

-- eam_pm_schedulings_v
-- EAM_PM_ACTIVITYGROUP_V
-- eam_suppression_relations_v
-- eam_pm_scheduling_rules
-- MTL_EAM_ASSET_NUMBERS_ALL_V
-- MTL_EAM_ASSET_ACTIVITIES_V
-- eam_pm_last_service_v
-- eam_asset_meters_v


--*****************--
-- ** EAM custom Tables ** --
--*****************--

-- staging_pm_schedule_table
-- staging_activ_pm_table
-- staging_rules_pm_table


---------------------------------------------------------------------


UPDATE staging_activ_pm_table pm
   SET pm.ACTIVITY_ASSOCIATION_ID =
          (SELECT ACTIVITY_ASSOCIATION_ID
             FROM apps.MTL_EAM_ASSET_ACTIVITIES_V
            WHERE     ACTIVITY = pm.ACTIVITY
                  AND INSTANCE_NUMBER = pm.INSTANCE_NUMBER);

---------------******************************-----------------


UPDATE staging_rules_pm_table rpm
   SET rpm.METER_ID =
          (SELECT met.METER_ID
             FROM eam_asset_meters_v met
            WHERE met.ASSET_NUMBER = rpm.INSTANCE_NUMBER)
 WHERE RULE_TYPE = 2;      
 
 
 --------**********************************-------------------


Commit;

-------------********************************************-------------

-- API

DECLARE
   CURSOR stage
   IS
      SELECT *
        FROM staging_pm_schedule_table
       WHERE flag IS NULL; --= 'U';                                           -- IS NULL;

   l_stat           VARCHAR2 (10);
   l_count          NUMBER;
   l_data           VARCHAR2 (500);
   l_schedule       eam_pmdef_pub.pm_scheduling_rec_type;
   l_activity       eam_pmdef_pub.pm_activities_grp_tbl_type;
   l_day            eam_pmdef_pub.pm_rule_tbl_type;
   l_runtime        eam_pmdef_pub.pm_rule_tbl_type;
   l_list           eam_pmdef_pub.pm_rule_tbl_type;
   l_sch_id         NUMBER;
   l_id             NUMBER;
   v_obj_id         NUMBER;
   v_obj_type       NUMBER;

   -- Counters for the tables
   activ_counter    NUMBER;
   ldrule_counter   NUMBER;
   lmeter_counter   NUMBER;
   ldate_counter    NUMBER;
BEGIN
   FOR i IN stage
   LOOP
      activ_counter := 0;
      ldrule_counter := 0;
      lmeter_counter := 0;
      ldate_counter := 0;

      SELECT eam_pm_schedulings_s.NEXTVAL INTO l_sch_id FROM DUAL;

      l_schedule.pm_schedule_id := l_sch_id;
      l_schedule.NAME := i.NAME;

      SELECT maintenance_object_id, maintenance_object_type
        INTO v_obj_id, v_obj_type
        FROM MTL_EAM_ASSET_NUMBERS_ALL_V
       WHERE INSTANCE_NUMBER = i.INSTANCE_NUMBER;

      l_schedule.maintenance_object_id := v_obj_id;
      l_schedule.maintenance_object_type := v_obj_type;
      l_schedule.set_name_id := i.set_name_id;
      l_schedule.from_effective_date := i.from_effective_date;
      l_schedule.generate_wo_status := i.generate_wo_status;
      l_schedule.current_cycle := 1;
      l_schedule.current_seq := 0;
      l_schedule.interval_per_cycle := i.interval_per_cycle;
      l_schedule.generate_next_work_order := i.generate_next_work_order;
      l_schedule.non_scheduled_flag := i.non_scheduled_flag;
      l_schedule.rescheduling_point := i.rescheduling_point;
      l_schedule.default_implement := i.default_implement;
      l_schedule.whichever_first := i.whichever_first;
      l_schedule.include_manual := i.include_manual;
      l_schedule.scheduling_method_code := i.scheduling_method_code;
      l_schedule.type_code := i.type_code;
      l_schedule.auto_instantiation_flag := i.auto_instantiation_flag;

      --      l_schedule.attribute1 := i.description;

      --*******************--********************--*********************--
      ------------------------- Activities Table ------------------------
      --*******************--********************--*********************--

      FOR j
         IN (SELECT activity_association_id,
                    interval_multiple,
                    allow_repeat_in_cycle
               FROM staging_activ_pm_table
              WHERE INSTANCE_NUMBER = i.INSTANCE_NUMBER)
      LOOP
         activ_counter := activ_counter + 1;

         l_activity (activ_counter).activity_association_id :=
            j.activity_association_id;
         l_activity (activ_counter).interval_multiple := j.interval_multiple;
         l_activity (activ_counter).allow_repeat_in_cycle :=
            j.allow_repeat_in_cycle;
      END LOOP;

      --*******************--********************--*********************--
      ------------------------- Rules Tables ------------------------
      ------------------------------- 1.Date Rule
      ------------------------------- 2.Meter Rule
      ------------------------------- 3.List of Dates
      --- PM can have only one type of Rules
      --*******************--********************--*********************--

      FOR x IN (SELECT RULE_TYPE,
                       METER_ID,
                       LIST_DATE,
                       RUNTIME_INTERVAL,
                       day_interval
                  FROM staging_rules_pm_table
                 WHERE INSTANCE_NUMBER = i.INSTANCE_NUMBER)
      LOOP
         CASE
            WHEN x.RULE_TYPE = 1                               --Date interval
            THEN
               ldrule_counter := ldrule_counter + 1;
               l_day (ldrule_counter).rule_type := x.rule_type;
               l_day (ldrule_counter).day_interval := x.day_interval;
            WHEN x.RULE_TYPE = 2                              --Meter interval
            THEN
               lmeter_counter := lmeter_counter + 1;
               l_runtime (lmeter_counter).rule_type := x.rule_type;
               l_runtime (lmeter_counter).meter_id := x.meter_id;
               l_runtime (lmeter_counter).runtime_interval :=
                  x.runtime_interval;
            WHEN x.RULE_TYPE = 3                               --List of Dates
            THEN
               ldate_counter := ldate_counter + 1;
               l_list (ldate_counter).rule_type := x.rule_type;
               l_list (ldate_counter).list_date := x.list_date;
         END CASE;
      END LOOP;


      IF i.TYPE_CODE = 20
      THEN
         l_day.DELETE ();
         l_runtime.DELETE ();
      ELSE
         l_list.DELETE ();
      END IF;


      -- Run the API with the specified parameters

      eam_pmdef_pub.create_pm_def (p_api_version                 => 1.0,
                                   p_init_msg_list               => NULL,
                                   p_commit                      => 'T',
                                   p_validation_level            => NULL,
                                   x_return_status               => l_stat,
                                   x_msg_count                   => l_count,
                                   x_msg_data                    => l_data,
                                   p_pm_schedule_rec             => l_schedule,
                                   p_pm_activities_tbl           => l_activity,
                                   p_pm_day_interval_rules_tbl   => l_day,
                                   p_pm_runtime_rules_tbl        => l_runtime,
                                   p_pm_list_date_rules_tbl      => l_list,
                                   x_new_pm_schedule_id          => l_id);

      -- Update flags and notes depending to the ID
      SWD_AUTON_DML (
            'UPDATE staging_pm_schedule_table SET flag =  '''
         || l_stat
         || ''' , note = '''
         || l_count
         || ' '
         || l_data
         || ''' WHERE INSTANCE_NUMBER = '''
         || i.INSTANCE_NUMBER
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