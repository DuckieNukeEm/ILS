drop table if exists duckie_ddl.d_ils_category;
create table duckie_ddl.d_ils_category(
     category_nbr int 
    ,category_desc varchar(40)
    ,start_date date
    ,end_date date
    ,orig_category_desc varchar(40)
    ,current_record char(1)
    ,PRIMARY KEY (category_nbr, start_date)
);
--alter table transform_ddl.iowa_liquor_sales owner to rw_role;
select * from d_ils_category
alter table duckie_ddl.d_ils_category rename orig_category_name to orig_category_desc;