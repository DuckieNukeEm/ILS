drop table if exists duckie_ddl.d_ils_category;
create table duckie_ddl.d_ils_category(
     category_nbr int 
    ,category_name varchar(40)
    ,start_date date
    ,end_date date
    ,orig_category_name varchar(40)
    ,current_record char(1)
    ,PRIMARY KEY (category_nbr, start_date)
);
--alter table transform_ddl.iowa_liquor_sales owner to rw_role;