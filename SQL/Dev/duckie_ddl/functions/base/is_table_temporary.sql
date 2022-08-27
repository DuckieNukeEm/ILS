/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: is_table_temporary                             #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
    This function will check if a table is:
        a) exists and
        b) temporary
    both conditions need to be true in order for true to be return
    else false is returned
    
 Arguments:
    table_name varchar(100) -- the name the table to check
    
 Returns:
    bool
    
 Source:
    https://stackoverflow.com/questions/11224806/how-can-i-detect-if-a-postgres-temporary-table-already-exists
 */


CREATE or REPLACE FUNCTION base_is_table_temporary( table_name varchar(100))
    RETURNS pg_catalog.bool 
    LANGUAGE 'plpgsql'AS
    $BODY$
    DECLARE
        BEGIN
        /* check the table exist in database and is visible*/
        perform 
            c.relname
        FROM 
            pg_catalog.pg_class c 
        where 
            pg_catalog.pg_table_is_visible(c.oid)
            AND Upper(relname) = Upper($1)
            and relpersistence = 't';
        
        /* return if found or not */
         IF FOUND THEN
            RETURN TRUE;
         ELSE
            RETURN FALSE;
         END IF;

     END
    $BODY$;


/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/
    
    --First, test if sees a temporary table
        create temporary table it_is_a_temp_table as select 1 as id;
    
        select 1 / count(*) from it_is_a_temp_table;

        select 1 / case when is_table_temporary('it_is_a_temp_table') then 1 else 0 end;
    
        drop table it_is_a_temp_table;
    
    --Second, test if it returns fales if table doesn't exist;
       
        select 1 / case when is_table_temporary('it_is_a_temp_table') then 0 else 1 end;
        
    --Third, test if it returns false if table isn't temporary
        
        create table isnt_a_temp_table as select 1 as id;
    
        select 1 / count(*) from isnt_a_temp_table;
    
        select 1 / case when is_table_temporary('isnt_a_temp_table') then 0 else 1 end;
    
        drop table isnt_a_temp_table;




