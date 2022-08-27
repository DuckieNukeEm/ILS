--TODO figure out how to tie the category name to the right day based on intervals
drop view if exists duckie_ddl.v_ils_orders;
create or replace view duckie_ddl.v_ils_orders
as
select
     o.item_invoice_nbr
    ,o.order_date 
    ,o.store_nbr
    ,sa.store_name as store_name
    ,sa.store_Address as store_Address
    ,sa.store_city as store_city
    ,sa.lat as lat
    ,sa.long as long
    ,sa.county_nbr
    ,sc.county_name 
    ,id.category_nbr
    ,c.category_desc
    ,o.vendor_nbr
    ,v.orig_vendor_name as vendor_name
    ,o.item_nbr
    ,id.item_desc
    ,id.items_per_pack 
    ,id.item_vol as bottle_vol
    ,o.state_bottle_cost::numeric as state_bottle_cost
    ,o.state_bottle_retail::numeric as state_bottle_retail
    ,(o.state_bottle_retail - o.state_bottle_cost)::numeric as state_bottle_profit
    ,o.bottles_sold
    ,o.total_sale::numeric as total_sale
    ,(o.total_sale - (o.state_bottle_cost * o.bottles_sold))::numeric as total_profit
    ,o.bottles_sold * coalesce(id.item_vol,0) as total_volume
    ,o.bottles_sold * coalesce(id.item_vol,0)/3785.41 as total_volume_gallons -- 1L/1000ml X 1G/3.78541L = 1G/3785.41ml
    
     
from
    duckie_ddl.d_ils_orders o
    left outer join
        duckie_ddl.d_ils_Store s
        on s.store_nbr = o.store_nbr
        and s.start_date <= o.order_date
        and s.end_date >= o.order_date
    left outer join
        duckie_ddl.d_ils_store_address sa
        on sa.store_hash = s.orig_store_hash
    left outer join
        duckie_ddl.d_ils_county sc
        on sc.county_nbr = sa.county_nbr
    left outer join
        duckie_ddl.d_ils_item i
        on i.item_nbr = o.item_nbr
        and i.start_date <= o.order_date
        and i.end_date >= o.order_date
    left outer join
        duckie_ddl.d_ils_item_detail id
        on id.item_hash = i.orig_item_hash
    left outer join
        duckie_ddl.d_ils_category c
        on c.category_nbr  = id.category_nbr 
        and c.start_date <= o.order_date
        and c.end_date >= o.order_date
    left outer join
        duckie_ddl.d_ils_vendor v
        on v.vendor_nbr = o.vendor_nbr
        and v.start_date <= o.order_date
        and v.end_date >= o.order_date
    ;
select * from v_ils_orders where order_Date between '2022-01-01' and '2022-01-14'