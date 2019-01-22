/* Call function takes (URL, http method: [ GET, POST, ...], request body)

 Request body format:
          '{"key":"value"
          , "key":"'  || variable_value || '"}'
*/

CREATE OR REPLACE FUNCTION CALL_REST_API (req_url      IN VARCHAR2,
                                          req_method   IN VARCHAR2,
                                          req_body     IN VARCHAR2)
   RETURN VARCHAR2
IS
   req        UTL_HTTP.req;                                         -- Request
   resp       UTL_HTTP.resp;                                       -- Response
   url        VARCHAR2 (4000) := req_url;                           -- API URL
   buffer     VARCHAR2 (4000);                                     -- Response
   v_result   VARCHAR2 (4000);                    -- end result to be returned
   content    VARCHAR2 (4000) := req_body;                     -- Request body
BEGIN
   -- build request with headers
   req := UTL_HTTP.begin_request (url, req_method, ' HTTP/1.1');
   UTL_HTTP.set_header (req, 'user-agent', 'mozilla/4.0');
   UTL_HTTP.set_header (req, 'content-type', 'application/json'); -- content type json accept

   IF req_method = 'POST'
   -- if method is post then take add to req header and build body content
   THEN
      UTL_HTTP.set_header (req, 'Content-Length', LENGTH (content));
      UTL_HTTP.write_text (req, content);
   END IF;


   resp := UTL_HTTP.get_response (req);

   -- process the response from the HTTP call
   BEGIN
      LOOP
         UTL_HTTP.read_line (resp, buffer);
         v_result := v_result || ' ' || buffer;       -- append response write
         DBMS_OUTPUT.put_line (buffer);
      END LOOP;

      UTL_HTTP.end_response (resp);
   EXCEPTION
      WHEN UTL_HTTP.end_of_body
      THEN
         UTL_HTTP.end_response (resp);
   END;

   RETURN v_result;                                 -- return result as string
END CALL_REST_API;