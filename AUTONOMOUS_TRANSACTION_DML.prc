/* Formatted on 7/19/2018 10:33:37 AM (QP5 v5.256.13226.35538) */
--This procedure is used to call an specific DML statment
-- and you need to commit the DML statment only

CREATE OR REPLACE PROCEDURE AUTON_DML (p_dmlstat VARCHAR2)
AS
   PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN                                       -- Main transaction suspends here.
   EXECUTE IMMEDIATE p_dmlstat;         -- Autonomous transaction begins here.

   COMMIT;                                -- Autonomous transaction ends here.
END;                                         -- Main transaction resumes here.


--------------------- How to USE -------------------------------------
----------------------------------------------------------------------
---EXECUTE AUTON_DML(q'[UPDATE staging_pm_schedule_table SET NOTE = 'TEST_Variable']');
--OR
---EXECUTE AUTON_DML('UPDATE staging_pm_schedule_table SET NOTE = '''TEST_Variable'''');

--*----------========----------========----------========------------*--
--*--========---- Author: Mohamed El Ghandour :D ----========----*--
--*----------========----------========----------========------------*--
