/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: is_valid_json                                  #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
	Checks if a given string is a valid json
    
 Arguments:
    p_json varchar(100) -- the json to check
    p_element (varchar(100) -- 
    
 Returns:
    True - if valid json
    False - otherwise
    
 Source:  https://stackoverflow.com/questions/30187554/how-to-verify-a-string-is-valid-json-in-postgresql

 */


create or replace function is_valid_json(p_json text)
  returns boolean
as
$$
begin
  return (p_json::json is not null);
exception 
  when others then
     return false;  
end;
$$
language plpgsql
immutable;

COMMIT;

/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/
	SELECT TRUE where is_valid_json('{"products": 1}');
	
	SELECT FALSE where is_Valid_json('aaa')
	
	SELECT
		is_Valid_json('{"products": 1, "tempo":10}'),
		is_valid_json('a');
 
 
 
 
 