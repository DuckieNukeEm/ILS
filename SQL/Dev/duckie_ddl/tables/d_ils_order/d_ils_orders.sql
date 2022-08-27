--begin;
--###############################################################################
--# Creating temp table                                                         #
--###############################################################################
drop table if exists tt_orders;
create temporary table tt_orders
as
select
     item_invoice_nbr
    ,order_dt as order_date
    ,state_bottle_cost as state_bottle_cost
    ,state_bottle_retail as state_bottle_retail
    ,sum(bottles_sold) as bottles_sold
    ,sum(sale) as total_sale                    
    ,regexp_replace(item_nbr, '[^0-9]+', '', 'g') as item_nbr           
    ,vendor_nbr             
    ,store_nbr         
from
    raw_ddl.iowa_liquor_sales
group by
    1,2,3,4,7,8,9; 
    
--###############################################################################
--# removing any previous records from the table                                #
--###############################################################################
delete
from 
    duckie_ddl.d_ils_orders o
using
      tt_orders AS n
WHERE 
      n.item_invoice_nbr = o.item_invoice_nbr
;

--###############################################################################
--# inserting into tabel                                                        #
--###############################################################################
insert into
    duckie_ddl.d_ils_orders
select 
     item_invoice_nbr
    ,order_date
    ,state_bottle_cost::numeric::money as state_bottle_cost
    ,state_bottle_retail::numeric::money as state_bottle_retail
    ,bottles_sold
    ,total_sale::numeric::money as total_sale                    
    ,item_nbr::integer as item_nbr           
    ,vendor_nbr             
    ,store_nbr 
from
    tt_orders;
--committ;
--vacuum;