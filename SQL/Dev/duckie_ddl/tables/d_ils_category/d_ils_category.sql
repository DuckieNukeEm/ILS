--begin;
--###############################################################################
--# Creating base category table                                                #
--###############################################################################
drop table if exists core_base_table;
create temporary table core_base_table
as
select
     s.category_nbr
    ,s.category_desc
    ,s.order_dt
    ,sum(s.orig_occurance_count) over (
                        partition by
                             s.category_nbr
                            ,s.order_dt) as occurance_count
    ,row_number() over (
                        partition by
                             s.category_nbr
                            ,s.order_dt
                        order by
                            s.orig_occurance_count desc) as rn
from
    (
        select
             category_nbr
            ,INITCAP(trim(category_name)) as category_desc
            ,s.order_dt
            ,count(1) as orig_occurance_count
        from
            raw_ddl.iowa_liquor_sales s 
        where
            category_nbr is not null
        group by 1,2,3
    ) s;


--###############################################################################
--# stacking two formats of the table                                           #
--###############################################################################
drop table if exists t_base;
create temporary table t_base 
as
    select
         s.category_nbr as col_nbr
        ,s.category_desc as col_hash
        ,s.order_dt
        ,'N' as null_incld
        ,s.occurance_count
    from
        core_base_table s 
    where
        s.rn = 1
        and s.category_desc is not null
    
    union all 
    
    select
        s.category_nbr as col_nbr
        ,s.category_desc as col_hash
        ,s.order_dt
        ,'Y' as null_incld
        ,s.occurance_count
    from
        core_base_table s  
    where
        s.rn = 1;
--###############################################################################
--#  sorting and lagging                                                        #
--###############################################################################
drop table if exists leadlag_temp;
create temporary table leadlag_temp 
as
select    
     b.col_nbr
    ,b.col_hash
    ,b.order_dt
    ,b.null_incld
    ,lag(b.order_dt) over (
                            partition by 
                                 b.null_incld
                                ,b.col_nbr
                            order by 
                                 b.order_dt
                        ) as lag_order_Dt
    ,lag(b.col_hash) over (
                            partition by 
                                 b.null_incld
                                ,b.col_nbr
                            order by 
                                b.order_dt
                        ) as lag_col_hash
from
    t_base b;

--###############################################################################
--# creating gap and island flags                                               #
--###############################################################################
drop table if exists gap_n_islands;
create temporary table gap_n_islands
as
select
     b.col_nbr
    ,b.col_hash
    ,b.order_dt
    ,b.lag_order_dt
    ,b.lag_col_hash
    ,b.change_flag
    ,b.null_incld
    ,sum(b.change_Flag) over (
                    partition by 
                         b.null_incld
                        ,b.col_nbr
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
                    and coalesce(a.lag_col_hash,'') != coalesce(a.col_hash,'')
                    then 1
                else 
                    0
            end as change_flag
        from
            leadlag_temp a
    ) b;
--###############################################################################
--# aggregating and adjusting dates                                             #
--###############################################################################
drop table if exists temp_interval;
create temporary table temp_interval
as 
select
     c.col_nbr
    ,c.col_hash
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
                                        ,b.col_nbr
                                    order by
                                        b.start_dt
                                        ) as lead_start
                ,lag(b.end_dt) over (
                                    partition by 
                                         b.null_incld
                                        ,b.col_nbr
                                    order by
                                        b.start_dt
                                        ) as lag_end
                
            from
                (
                    select
                         a.col_nbr
                        ,a.islands
                        ,a.col_hash
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
     Y.col_nbr
    ,N.col_hash
    ,Y.start_dt as start_dt
    ,Y.orig_start_Dt
    ,Y.end_dt as end_dt
    ,Y.col_hash as orig_col_hash
from
    temp_interval Y
    left join 
        temp_interval N
        on Y.col_nbr = N.col_nbr
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
      n.col_nbr = o.category_nbr
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
                duckie_ddl.d_ils_category b1
            group by 
                1
        ) b
        on n.col_nbr = b.category_nbr
where
    o.start_date = b.max_start
    and n.col_nbr = o.category_nbr;

--###############################################################################
--# inserting the updated data                                                  #
--###############################################################################
insert into duckie_ddl.d_ils_category
select
     n.col_nbr as category_nbr
    ,n.col_hash as category_desc
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
    ,n.orig_col_hash as orig_category_desc
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
        on b.category_nbr = n.col_nbr
;

--rollback;
--commit;