/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: drop_temporary_table                           #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
    This function will drop a temporary table safely. It will first check A
    that the table exists and is, in fact, temporary.
    
 Arguments:
    table_name varchar(100) -- the name of the table to drop. 
    
 Returns:
    None
    
    
 */


create or replace function base_drop_temporary_table(table_name varchar(100))
    RETURNS void
    LANGUAGE 'plpgsql'AS
    $BODY$
     DECLARE
        BEGIN
            IF base_is_table_temporary(table_name) THEN
                EXECUTE format('drop table if exists %I',  table_name); 
            END IF;
        END
        $BODY$;

   
/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/


    -- first test, it does drop a temp table 
        create temporary table test_temp_table as select 1 as id;
        
        select 1 / count(*) from test_temp_table;
        
        select drop_temporary_table('test_temp_table');
        
        select 1 / case when counter = 0 then 1 else 0 end 
            from 
                (select count(*) as counter 
                 from pg_class where relname = 'test_temp_table' and relpersistence = 'T') x;
       
    -- second test, it does not drop a permament table
    
        create table test_temp_table_lalelulelo as select 1 as id;
    
        select 1 / count(*) from test_temp_table_lalelulelo;
        
        select drop_temporary_table('test_temp_table_lalelulelo');
        
        select 1 / count(*) from test_temp_table_lalelulelo;
    
        drop table test_temp_table_lalelulelo;
        