drop table if exists duckie_ddl.d_ils_store_address;
create table duckie_ddl.d_ils_store_address(
     store_nbr           int
    ,store_name          varchar(60)
    ,store_address       varchar(60)
    ,store_city          varchar(20)
    ,zip_code            varchar(12)
    ,county_nbr          int 
    ,lat                 varchar(18)
    ,long                varchar(18)
    ,store_hash          varchar(32)
    ,insert_date         date
    ,PRIMARY KEY (store_hash)
);
--alter table transform_ddl.d_ils_store_address owner to rw_role;
