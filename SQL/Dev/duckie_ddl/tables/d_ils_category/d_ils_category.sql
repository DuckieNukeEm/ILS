--begin;
--###############################################################################
--# Creating temp table                                                         #
--###############################################################################
drop table if exists t_base;
create temporary table t_base 
as
select
     b.*
    ,sum(orig_occurance_count) over (
                        partition by
                             b.category_nbr
                            ,b.order_dt
                            ,b.null_incld) as occurance_count
    ,row_number() over (
                        partition by
                             b.category_nbr
                            ,b.order_dt
                            ,b.null_incld 
                        order by
                            b.orig_occurance_count desc) as rn
from
    (
    select
         category_nbr
        ,INITCAP(trim(category_name)) as category_name
        ,order_dt
        ,'N' as null_incld
        ,count(1) as orig_occurance_count
    from
        raw_ddl.iowa_liquor_sales s 
    where
        category_nbr is not null
        and category_name is not null
    group by 1,2,3
    
    union all 

    select
         category_nbr
        ,INITCAP(trim(category_name)) as category_name
        ,order_dt
        ,'Y' as null_incld
        ,count(1) as orig_occurance_count
    from
        raw_ddl.iowa_liquor_sales  
    where
        category_nbr is not null
    group by 1,2,3
    ) b;
--###############################################################################
--#  sorting and lagging                                                        #
--###############################################################################
drop table if exists cat_temp;
create temporary table cat_temp 
as
select    
     b.category_nbr
    ,b.category_name
    ,b.order_dt
    ,b.null_incld
    ,lag(b.order_dt) over (
                            partition by 
                                 b.null_incld
                                ,b.category_nbr
                            order by 
                                 b.order_dt
                        ) as lag_order_Dt
    ,lag(b.category_name) over (
                            partition by 
                                 b.null_incld
                                ,b.category_nbr
                                
                            order by 
                                b.order_dt
                        ) as lag_category_name
from
    (
    select
         a.*
        ,row_number() over (partition by 
                                 a.null_incld
                                ,a.category_nbr
                                ,a.order_dt
                            order by 
                                a.occurance_count desc
                            ) as rn
        from
            t_base a
        where
            a.rn = 1
        order by 1,2,3,4
    ) b;

--###############################################################################
--# creating gap and island flags                                               #
--###############################################################################
drop table if exists gap_n_islands;
create temporary table gap_n_islands
as
select
     b.category_nbr
    ,b.category_name
    ,b.order_dt
    ,b.lag_order_dt
    ,b.lag_category_name
    ,b.change_flag
    ,b.null_incld
    ,sum(b.change_Flag) over (
                    partition by 
                         b.null_incld
                        ,b.category_nbr
                    order by b.order_Dt asc rows between unbounded preceding and current row
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
                    and coalesce(a.lag_category_name,'') != coalesce(a.category_name,'')
                    then 1
                else 
                    0
            end as change_flag
        from
            cat_Temp a
    ) b;
--###############################################################################
--# aggregating and adjusting dates                                             #
--###############################################################################
drop table if exists temp_interval;
create temporary table temp_interval
as 
select
     c.category_nbr
    ,c.category_name
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
                                        ,b.category_nbr
                                    order by
                                        b.start_dt
                                        ) as lead_start
                ,lag(b.end_dt) over (
                                    partition by 
                                         b.null_incld
                                        ,b.category_nbr
                                    order by
                                        b.start_dt
                                        ) as lag_end
                
            from
                (
                    select
                         a.category_nbr
                        ,a.islands
                        ,a.category_name
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
     Y.category_nbr
    ,N.category_Name
    ,Y.start_dt as start_dt
    ,Y.orig_start_Dt
    ,Y.end_dt as end_dt
    ,Y.category_Name as orig_category_name
from
    temp_interval Y
    left join 
        temp_interval N
        on Y.category_nbr = N.category_nbr
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
    duckie_ddl.d_ils_category o
using
      t_temp_merge AS n
WHERE 
      n.category_nbr = o.category_nbr
      and n.orig_start_dt <= o.start_date 
;


--###############################################################################
--# updating the end date from the last record of each category                 #
--###############################################################################

update
    duckie_ddl.d_ils_category o  
set
     end_date = n.orig_start_dt - interval '1 day'
    ,current_record = 'N'
from
    t_temp_merge n
    inner join
        (
            select
                b1.category_nbr
                ,max(b1.start_date) as max_start
            from
                duckie_ddl.d_ils_Category b1
            group by 
                1
        ) b
        on n.category_nbr = b.category_nbr
where
    o.start_date = b.max_start
    and n.category_nbr = o.category_nbr;

--###############################################################################
--# inserting the updated data                                                  #
--###############################################################################
insert into duckie_ddl.d_ils_category
select
     n.category_nbr
    ,n.category_name
    ,case
        when 
            b.category_nbr is not null
            and b.max_end + interval '1 day' = n.orig_start_dt
            then
                n.orig_start_dt
        else
            n.start_dt
     end as start_date
    ,n.end_dt as end_date
    ,n.orig_category_name
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
                 b1.category_nbr
                ,max(b1.end_date) as max_end
            from
                duckie_ddl.d_ils_category b1
            group by 
                1
        ) b
        on b.category_nbr = n.category_nbr
;

--rollback;
--commit;