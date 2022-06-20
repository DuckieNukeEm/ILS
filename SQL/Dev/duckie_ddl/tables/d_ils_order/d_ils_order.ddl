drop table if exists duckie_ddl.d_ils_orders;
create table duckie_ddl.d_ils_orders(
     item_invoice_nbr       varchar(16)
    ,order_date             date
    ,state_bottle_cost      float8
    ,state_bottle_retail    float8
    ,bottles_sold           integer
    ,total_sale             float8
    ,total_volume           float8
    ,item_nbr               int
    ,category_nbr           int
    ,vendor_nbr             int
    ,store_nbr              int
    ,PRIMARY KEY (item_invoice_nbr)
);
--alter table transform_ddl.d_ils_orders owner to rw_role;
