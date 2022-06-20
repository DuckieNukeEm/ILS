--run as rw ability
DROP TABLE IF EXISTS raw_ddl.iowa_liquor_sales;
create table raw_ddl.iowa_liquor_sales 
(
     item_invoice_nbr varchar(100) primary key
    ,order_dt date 
    ,store_nbr int
    ,store_name varchar(100)
    ,store_Address varchar(100)
    ,store_city varchar(50)
    ,zip_Code varchar(10)
    ,store_location varchar(50)
    ,County_nbr int 
    ,County_name varchar(30)
    ,category_nbr int
    ,category_name varchar(256)
    ,Vendor_nbr int
    ,Vendor_Name varchar(256)	
    ,Item_nbr varchar(10)
    ,item_desc varchar(256)
    ,pack int
    ,bottle_vol int
    ,state_bottle_cost float8
    ,state_bottle_retail float8
    ,bottles_Sold int
    ,sale float8
    ,volume float8
    ,volume_gallons float8);
grant select on raw_ddl.iowa_liquor_sales to ro_role;

COPY raw_ddl.iowa_liquor_sales(
	item_invoice_nbr
    ,order_dt 
    ,store_nbr 
    ,store_name
    ,store_Address
    ,store_city 
    ,zip_Code 
    ,store_location
    ,County_nbr  
    ,County_name 
    ,category_nbr 
    ,category_name 
    ,Vendor_nbr 
    ,Vendor_Name 	
    ,Item_nbr 
    ,item_desc 
    ,pack 
    ,bottle_vol 
    ,state_bottle_cost 
    ,state_bottle_retail 
    ,bottles_Sold 
    ,sale 
    ,volume 
    ,volume_gallons)
FROM '/mountpoint/ILS_202205.csv'
DELIMITER ','
csv HEADER;

alter table raw_ddl.iowa_liquor_sales owner to rw_role;
commit;

-- item nbr 904631 has 3 records where it comes in as x904631 hence we need to keep item_nbr as varchar :/
-- select item_nbr, item_desc , count(*) from raw_ddl.iowa_liquor_sales where not item_nbr  ~ '^[0-9\.]+$' or item_nbr = '904631' group by 1,2;