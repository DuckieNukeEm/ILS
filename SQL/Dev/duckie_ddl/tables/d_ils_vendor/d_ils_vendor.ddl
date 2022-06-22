drop table if exists duckie_ddl.d_ils_vendor;
create table duckie_ddl.d_ils_vendor(
     vendor_nbr int 
    ,vendor_name varchar(70)
    ,start_date date
    ,end_date date
    ,orig_vendor_name varchar(70)
    ,current_record char(1)
    ,PRIMARY KEY (vendor_nbr, start_date)
);
--alter table transform_ddl.iowa_liquor_sales owner to rw_role;