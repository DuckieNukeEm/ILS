drop table if exists duckie_ddl.d_ils_orders;
create table duckie_ddl.d_ils_orders(
     item_invoice_nbr       varchar(16)
    ,order_date             date
    ,state_bottle_cost      MONEY
    ,state_bottle_retail    MONEY
    ,bottles_sold           integer
    ,total_sale             MONEY
    ,item_nbr               int
    ,vendor_nbr             int
    ,store_nbr              int
    ,PRIMARY KEY (item_invoice_nbr)
);
--alter table transform_ddl.d_ils_orders owner to rw_role;
