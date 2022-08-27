drop table if exists duckie_ddl.d_ils_store;
create table duckie_ddl.d_ils_store(
     store_nbr          int
    ,store_hash         varchar(32)
    ,start_date          date
    ,end_date            date
    ,orig_store_hash    varchar(32)
    ,current_record     char(1)
    ,PRIMARY KEY (store_nbr, start_date)
);
--alter table transform_ddl.d_ils_item owner to rw_role;
