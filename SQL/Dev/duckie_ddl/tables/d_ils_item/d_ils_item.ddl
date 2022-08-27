drop table if exists duckie_ddl.d_ils_item;
create table duckie_ddl.d_ils_item(
     item_nbr int
    ,item_hash varchar(32)
    ,start_date date
    ,end_date date
    ,orig_item_hash varchar(32)
    ,current_record char(1)
    ,PRIMARY KEY (item_nbr, start_date)
);
--alter table transform_ddl.d_ils_item owner to rw_role;
