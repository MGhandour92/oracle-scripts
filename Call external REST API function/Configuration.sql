/* Formatted on 1/22/2019 10:01:22 AM (QP5 v5.256.13226.35538) */
-- These grants must be granted by [SYS] User
-- DB USER for calling the api
GRANT EXECUTE ON UTL_HTTP TO APPS;
GRANT EXECUTE ON DBMS_LOCK TO APPS;


-- This will create access control list for the user specified

BEGIN
   DBMS_NETWORK_ACL_ADMIN.create_acl (
      acl           => 'local_sx_acl_file.xml', -- access control list file name
      description   => 'A test of the ACL functionality',
      principal     => 'APPS',                                      -- DB USER
      is_grant      => TRUE,
      privilege     => 'connect',                         -- CONNECT privilege
      start_date    => SYSTIMESTAMP,
      end_date      => NULL);                            -- Effective end date
END;



-- Assign the ACL created to a specfic host and port

BEGIN
   DBMS_NETWORK_ACL_ADMIN.assign_acl (acl          => 'local_sx_acl_file.xml', --
                                      HOST         => '10.1.xx.xx',
                                      -- use IP for external/internal domains
                                      -- you may use hostname,
                                      -- if you added it in hosts file [../etc/hosts]
                                      lower_port   => 80,   -- PORT of the API
                                      upper_port   => NULL); -- you may make a range of ports
END;