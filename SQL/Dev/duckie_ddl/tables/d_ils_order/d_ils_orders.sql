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
    ,state_bottle_cost
    ,state_bottle_retail
    ,sum(bottles_sold) as bottles_sold
    ,sum(sale) as total_sale                   
    ,sum(volume) as total_volume                 
    ,regexp_replace(item_nbr, '[^0-9]+', '', 'g')::integer as item_nbr      
    ,category_nbr           
    ,vendor_nbr             
    ,store_nbr         
from
    raw_ddl.iowa_liquor_sales
group by
    1,2,3,4,8,9,10,11; 
    
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
    *
from
    tt_orders;
--committ;
--vacuum;

select * from d_ils_orders as dio  where order_date between '2020-12-25' and '2021-01-02'