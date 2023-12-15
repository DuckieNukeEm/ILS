/*!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
################################################################################
#                                                                              #
#                     FUNCTION: insert_into_hash_tbl                           #
#                        module: ils                                           #
#                                                                              #
################################################################################
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!*/

/*
 Details:
    This function will insert into a hash table
    
 Arguments:
    insert_Table varchar -- table to insert to
    data_table varchar -- table to pull data from and insert into too
    
 Returns:
    bool - name of temporary table created
    
    
 */

drop function  if exists ils_insert_into_hash_tbl(insert_table character varying, data_table character varying);
CREATE OR REPLACE FUNCTION ils_insert_into_hash_tbl(insert_table character varying, data_table character varying) 
    returns int
    LANGUAGE plpgsql AS
    $$ 
    begin
    execute format('
    INSERT INTO %1$I
        select
             s.id_nbr
            ,s.id_hash
            ,s.order_dt
            ,%3$s as null_incld
            ,s.occurance_count

        from
            %2$I s 
        where
            s.null_indicator = %3$s
        
        union all 
    
        select
             s.id_nbr
            ,s.id_hash
            ,s.order_dt
            ,%4$s as null_incld
            ,s.occurance_count
        from
            %2$I s', insert_table, data_table, 'N', 'Y'
    );
--    GET DIAGNOSTICS integer_var = ROW_COUNT;
--    return integer_var;
end
$$
;

/*______________________________________________________________________________
  ##############################################################################
                                TESTING
*/

    --creating temporary data table (empty):
        drop table if exists tt_data;
        create temporary table tt_data
        (
             id_nbr bigint
            ,id_hash varchar(32)
            ,order_dt date
            ,null_indicator char(1)
            ,occurance_count int
        );

    
    --creating hash_table;
        drop table if exists tt_insert;
        create temporary table tt_insert
        (
             id_nbr varchar(200)
            ,id_hash char(32)
            ,order_dt date
            ,null_incld char(1)
            ,occurance_count int
        );
    -- inserting an empty table, making sure the table is still emtpy;
    select ils_insert_into_hash_tbl('tt_insert', 'tt_data');
    select 0 = (select count(1) from tt_insert);
  
    
    
    
    
            insert into tt_data values (1, md5('a'), '1900-01-01', 'N', 1);
        insert into tt_data values (1, md5('a'), '1900-01-01', 'Y', 1);
        insert into tt_data values (2, md5('b'), '1900-01-02', 'N', 6);
        insert into tt_data values (2, md5('b'), '1900-01-02', 'Y', 6);
        insert into tt_data values (3, md5('c'), '1900-01-04', 'N', 14);
        insert into tt_data values (4, md5('c'), '1900-01-07', 'Y', 19);
    -- testing if it retuns a string values
        select length(ils_mktable_hash())>0; 
    
    -- testing if it exists
        SELECT EXISTS (
           SELECT 1
           FROM   information_schema.tables 
           where table_name ilike 'temp_hash_%'
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
                    table_name ilike 'temp_hash_%'
               ) a
            ) x;
        
    -- testing it has no collisions
        select 
            ils_mktable_hash()
        from
            generate_series(0, 100) ;
        
    
    
    