--begin;
--###############################################################################
--# Creating base store table                                                   #
--###############################################################################
drop table if exists base_store_table;
create temporary table base_store_table
as
select
     s.store_nbr
    ,s.store_name
    ,s.store_address
    ,s.store_city
    ,s.zip_code
    ,s.county_nbr 
    ,split_part(s.store_loc, ' ',1) as lat
    ,split_part(s.store_loc, ' ',2) as long
    ,s.order_dt 
    ,s.orig_occurance_count
    
    ,sum(s.orig_occurance_count) over (
                        partition by
                             s.store_nbr
                            ,s.order_dt) as occurance_count
    ,row_number() over (
                        partition by
                             s.store_nbr
                            ,s.order_dt
                        order by
                            s.orig_occurance_count desc) as rn
from
    (
        select
             s.store_nbr
            ,INITCAP(trim(s.store_name)) as store_name
            ,INITCAP(trim(s.store_address)) as store_address
            ,INITCAP(trim(s.store_city)) as store_city
            ,s.zip_code
            ,s.county_nbr
            ,coalesce(REGEXP_REPLACE(trim(store_location),'(POINT\s\()|\)','','g'), '0.0 0.0') as store_loc
            ,s.order_dt
            ,count(1) as orig_occurance_count
        from
            raw_ddl.iowa_liquor_sales s 
        where
            store_nbr is not null
        group by 1,2,3,4,5,6,7,8
    ) s;
--###############################################################################
--# Creating hash crosswalk                                                     #
--###############################################################################
drop table if exists hash_store_table;
create temporary table hash_store_table
as
select
     s.store_nbr
    ,s.store_name
    ,s.store_address
    ,s.store_city
    ,s.zip_code
    ,s.county_nbr
    ,s.lat
    ,s.long
    ,md5(coalesce(s.store_nbr,0)::varchar(6) ||
        coalesce(s.store_name, 'Null') ||
        coalescE(s.store_Address,'Null') ||
        coalesce(s.store_City, 'Null') ||
        coalesce(s.zip_code, '-99999') ||
        coalesce(s.county_nbr, -99)::varchar(6) ||
        coalesce(s.lat,'-999.0') ||
        coalesce(s.long,'-999.0')) as store_hash
from 
    base_store_table s 
where
    s.rn = 1

group by 1,2,3,4,5,6,7,8,9;
--###############################################################################
--# inserting new records into store_address table                              #
--###############################################################################
INSERT into duckie_ddl.d_ils_store_address
select
     *
from
    hash_store_table
ON CONFLICT DO NOTHING;

--###############################################################################
--# Creating base ranking table                                                 #
--###############################################################################
--# lat long https://stackoverflow.com/questions/8150721/which-data-type-for-latitude-and-longitude
-- TODO: Set up an error processing log as not all stores_nbrs ARE NOT ints, currently just regex correct it
-- TODO force correct the bad lat longs, cause damn, those things will be usefull
drop table if exists t_base;
create temporary table t_base 
as

    select
         s.store_nbr
        ,md5(coalesce(s.store_nbr,0)::varchar(6) ||
            coalesce(s.store_name, 'Null') ||
            coalescE(s.store_Address,'Null') ||
            coalesce(s.store_City, 'Null') ||
            coalesce(s.zip_code, '-99999') ||
            coalesce(s.county_nbr, -99)::varchar(6) ||
            coalesce(s.lat,'-999.0') ||
            coalesce(s.long,'-999.0')) as store_hash
        ,s.order_dt
        ,'N' as null_incld
        ,s.occurance_count

    from
        base_store_table s 
    where
        s.rn = 1
        and s.store_name is not null
        and s.store_address is not null
    
    union all 
    
    select
         s.store_nbr
        ,md5(coalesce(s.store_nbr,0)::varchar(6) ||
            coalesce(s.store_name, 'Null') ||
            coalescE(s.store_Address,'Null') ||
            coalesce(s.store_City, 'Null') ||
            coalesce(s.zip_code, '-99999') ||
            coalesce(s.county_nbr, -99)::varchar(6) ||
            coalesce(s.lat,'-999.0') ||
            coalesce(s.long,'-999.0')) as store_hash
        ,s.order_dt
        ,'Y' as null_incld
        ,s.occurance_count
    from
        base_store_table s
    where
        s.rn = 1
;
select * from t_base where store_nbr = 3420
--###############################################################################
--#  sorting and lagging                                                        #
--###############################################################################
drop table if exists store_temp;
create temporary table store_temp 
as
select    
     s.store_nbr
    ,s.store_hash
    ,s.order_dt
    ,s.null_incld
    ,lag(s.order_dt) over ( partition by 
                                 s.null_incld
                                ,s.store_nbr
                            order by 
                                 s.order_dt
                        ) as lag_order_Dt
    ,lag(s.store_hash) over (
                            partition by 
                                 s.null_incld
                                ,s.store_nbr
                            order by 
                                s.order_dt
                        ) as lag_hash
from
    t_base s;
--###############################################################################
--# creating gap and island flags                                               #
--###############################################################################
drop table if exists gap_n_islands;
create temporary table gap_n_islands
as
select
     b.store_nbr
    ,b.store_hash
    ,b.order_dt
    ,b.null_incld
    ,sum(b.change_Flag) over (
                    partition by 
                         b.null_incld
                        ,b.store_nbr
                    order by 
                        b.order_Dt asc rows between unbounded preceding and current row
                    ) as islands
    from
    (
        select
             a.*
            ,case
                when 
                    a.lag_order_Dt is null
                    then 1
                when
                    a.lag_order_dt is not null
                    and coalesce(a.lag_hash,'') != coalesce(a.store_hash,'')
                    then 1
                else 
                    0
            end as change_flag
        from
            store_Temp a
    ) b;

select * from gap_n_islands where store_nbr = 3420
--###############################################################################
--# aggregating and adjusting dates                                             #
--###############################################################################
drop table if exists temp_interval;
create temporary table temp_interval
as 
select
     c.store_nbr
    ,c.store_hash
    ,c.null_incld
    ,c.islands
    ,c.start_dt as orig_start_dt
    ,c.end_dt as orig_end_dt
    ,c.lead_start
    ,c.lag_End
    ,case
        when 
            c.lag_end is null
            then '0001-01-01'
        else
            c.start_dt
     end::date as start_dt
    ,case
        when 
            c.lead_start is null 
            then '2999-12-31'
        when
            c.lead_start > c.end_dt
            then c.lead_start - interval '1 day'
        when
            c.lead_start = c.end_dt
            and c.start_dt < c.end_dt
            then c.end_dt - interval '1 day'
        else
            '0001-01-01'
    end::date as end_dt
    from
        (
            select
                 b.*
                ,lead(b.start_dt) over (
                                    partition by 
                                         b.null_incld
                                        ,b.store_nbr
                                    order by
                                        b.start_dt
                                        ) as lead_start
                ,lag(b.end_dt) over (
                                    partition by 
                                         b.null_incld
                                        ,b.store_nbr
                                    order by
                                        b.start_dt
                                        ) as lag_end
                
            from
                (
                    select
                         a.store_nbr
                        ,a.islands
                        ,a.store_hash
                        ,a.null_incld
                        ,min(a.order_dt) as start_Dt
                        ,max(a.order_Dt) as end_Dt
                    from
                        gap_n_islands a
                    group by
                        1,2,3,4
                ) b
        ) c;

--###############################################################################
--# merging the null_incld N w null_incld                                       #
--###############################################################################
 drop table if exists t_temp_merge;
 create temporary table t_temp_merge
 as
 select
     Y.store_nbr
    ,N.store_hash
    ,Y.start_dt as start_dt
    ,Y.orig_start_Dt
    ,Y.end_dt as end_dt
    ,Y.store_hash as orig_store_hash
from
    temp_interval Y
    left join 
        temp_interval N
        on Y.store_nbr = N.store_nbr
        and Y.start_dt <= N.end_dt
        and Y.end_dt >= N.start_dt
        and N.null_incld = 'N'
where
    Y.null_incld = 'Y';
--###############################################################################
--# removing any records that span before a record in the orig table            #
--###############################################################################
delete
from 
    duckie_ddl.d_ils_store o
using
      t_temp_merge AS n
WHERE 
      n.store_nbr = o.store_nbr
      and n.orig_start_dt <= o.start_date 
;


--###############################################################################
--# updating the end date from the last record of each store                     #
--###############################################################################

update
    duckie_ddl.d_ils_store o  
set
     end_date = n.orig_start_dt - interval '1 day'
    ,current_record = 'N'
from
    t_temp_merge n
    inner join
        (
            select
                b1.store_nbr
                ,max(b1.start_date) as max_start
            from
                duckie_ddl.d_ils_store b1
            group by 
                1
        ) b
        on n.store_nbr = b.store_nbr
where
    o.start_date = b.max_start
    and n.store_nbr = o.store_nbr;

--###############################################################################
--# inserting the updated data                                                  #
--###############################################################################
insert into duckie_ddl.d_ils_store
select
     n.store_nbr
    ,n.store_hash
    ,case
        when 
            b.store_nbr is not null
            and b.max_end + interval '1 day' = n.orig_start_dt
            then
                n.orig_start_dt
        else
            n.start_dt
     end as start_date
    ,n.end_dt as end_date
    ,n.orig_store_hash
    ,case 
        when 
            n.end_dt = '2999-12-31'
            then 'Y'
        else
            'N'
     end as current_record
    
from
    t_temp_merge n
    left outer join 
        (
            select
                 b1.store_nbr
                ,max(b1.end_date) as max_end
            from
                duckie_ddl.d_ils_store b1
            group by 
                1
        ) b
        on b.store_nbr = n.store_nbr
;

-- TODO 
-- Need to investiagte if vol is being calculated correctly (paxk size x vol x quant sold)

