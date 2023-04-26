/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: mktable_ils_leadlag                            #
#                        module: ils                                           #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
    This function will create a temporary table of the type used for leadlad
    
 Arguments:
    Null 
    
 Returns:
    char(22) - name of temporary table created
    
    
 */


CREATE OR REPLACE FUNCTION mktable_ils_leadlag()
    returns text
    LANGUAGE plpgsql AS
    $$
    DECLARE 
    t_name char(22);
    begin 
        t_name := 'temp_leadlag_' ||  substr(md5(random()::text), 0, 10);
      EXECUTE format('
        CREATE TEMPORARY TABLE IF NOT EXISTS %I (
            id_nbr varchar(200),
            id_hash char(32),
            order_dt date,
            null_incld char(1),
            lag_order_dt date,
            lag_id_hash date
					)',  t_name); 
    return t_name;
END
$$;

/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/

    -- check if a temp_leading table alaready exists
           SELECT EXISTS (
           SELECT 1
           FROM   information_schema.tables 
           where table_name ilike 'temp_leadlag_%'
        )
    -- testing if it retuns a string values
        select mktable_ils_leadlag();
    
    -- testing if it exists
        SELECT EXISTS (
           SELECT 1
           FROM   information_schema.tables 
           where table_name ilike 'temp_leadlag_%'
        );
    -- testing it returns a string value
        select base_is_table_temporary('temp_leadlag_d77be5d0c')
        
    -- testing it has collisions
        select mktable_ils_leadlag();
        
    
    
    