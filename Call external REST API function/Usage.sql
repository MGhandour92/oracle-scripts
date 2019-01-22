-- Usage
SELECT CALL_REST_API ('http://10.1.xx.xx/restapi/api/contact', 'GET', '') API_REPONSE
  FROM DUAL;

-- IF you need to read as JSON, for more info on check:
-- https://docs.oracle.com/database/121/SQLRF/functions093.htm#SQLRF56668
SELECT JSON_VALUE (
          CALL_REST_API ('http://10.1.xx.xx/restapi/api/contact', 'GET', ''),
          '$[0]') -- array index as a parameter
          value_json
  FROM DUAL;