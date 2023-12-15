/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: mktable_merge                                  #
#                        module: ils                                           #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
    This function will create a temporary table of the type used for merging
    
 Arguments:
    Null 
    
 Returns:
    char(22) - name of temporary table created
    
    
 */

CREATE OR REPLACE FUNCTION ils_mktable_merge()
    returns text
    LANGUAGE plpgsql AS
    $$
    DECLARE 
    t_name char(21);
    begin 
        t_name := 'temp_merge_' ||  substr(md5(random()::text), 0, 10);
      EXECUTE format('
        CREATE TEMPORARY TABLE IF NOT EXISTS %I (
             id_nbr varchar(200)
            ,id_hash char(32)
            ,start_dt date
            ,orig_start_dt date
            ,end_dt date
            ,orig_id_hash char(32)
            )',  t_name); 
    return t_name;
END
$$;

/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/

    -- check if a temp_gap_n_island table alaready exists
           SELECT EXISTS (
               SELECT 1
               FROM   information_schema.tables 
               where table_name ilike 'temp_merge_%'
            ) = false
    -- testing if it retuns a string values
        select length(ils_mktable_merge())>0; 
    
    -- testing if it exists
        SELECT EXISTS (
           SELECT 1
           FROM   information_schema.tables 
           where table_name ilike 'temp_merge_%'
        ) is true;
    
    -- testing it returns a string value
        SELECT 
            table_count = temp_Table_Count and table_count>0
        from
            (
           SELECT 
                count(*) as table_count,
                sum(case when is_table_temporary(a.tablename) is true then 1 else 0 end) as temp_Table_Count
            from
                (select
                    table_name::varchar(100) as tablename
                FROM   
                    information_schema.tables  a
                where
                    table_name ilike 'temp_merge_%'
               ) a
            ) x
        
    -- testing it has no collisions
        select 
            ils_mktable_merge()
        from
            generate_series(0, 100) 
    
    
        
    