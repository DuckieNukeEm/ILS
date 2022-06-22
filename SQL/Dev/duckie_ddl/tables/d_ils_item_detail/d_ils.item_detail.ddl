drop table if exists duckie_ddl.d_ils_item_detail;
create table duckie_ddl.d_ils_item_detail(

    item_hash varchar(32)
    ,item_nbr int
    ,item_Desc varchar(70)
    ,category_nbr int
    ,items_per_pack int
    ,item_vol int
    ,PRIMARY KEY (item_hash)
);
--alter table transform_ddl.d_ils_item_detail owner to rw_role;
