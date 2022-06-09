--###############################################################################
--# DEfining table                                                              #
--###############################################################################

drop table if exists duckie_ddl.d_ils_item;
create table duckie_ddl.d_county(
     item_nbr int 
    ,item_desc varchar(15)
);

--###############################################################################
--# POPULATING                                                                  #
--###############################################################################
/*
insert into duckie_ddl.d_county
select
     county_nbr
    ,max(INITCAP(county)) as county
from 
    raw_ddl.iowa_liquor_sales 
where
    county_nbr is not null 
    and county_nbr is not null
group by 1;

--###############################################################################
--# AUTOINCREMETING COUNTIES WITH NULL COUNTY OR NULL COUNTY NUMBER             #
--###############################################################################

insert into duckie_ddl.d_county
select
     row_number() over (order by b.county) + c.max_count as country_nbr
    ,b.county
from
    (select
        row_number() 
                over (partition by county 
                  order by county desc ) as rn 
        ,county
    from
        (
        select
            INITCAP(county) as county
        from 
            raw_ddl.iowa_liquor_sales 
        where
            county_nbr is null 
        group by 1 ) a
    ) b
    inner join
    (select
        max(county_nbr) as max_count
    from
        duckie_ddl.d_county
    ) c on 1=1
;

--###############################################################################
--# GRANTING PERMISSIONS                                                        #
--###############################################################################
grant select on duckie_ddl.d_county to ro_role, rw_role;
*/

