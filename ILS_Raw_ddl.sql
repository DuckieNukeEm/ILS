DROP TABLE IF EXISTS iowa_liquor_sales;
create table iowa_liquore_sales as
(
     item_invoice_nbr varchar(15)
    ,order_dt date 
    ,store_nbr int
    ,store_name varchar(256)
    ,store_Address varchar(999)
    ,store_city varchar(256)
    ,zip_Code varchar(30
    ,store_location varchar(100),
    ,County_nbr int
    ,County varchar(999)
    ,category varchar(999)
    ,cateogory_name varchar(999)
    ,Vendor_nbr int
    ,Vendor_Name varchar(999)	
    ,Item_nbr varchar(999)
    ,item_desc varchar(999)
    ,pack int
    ,bottle_vlm double
    ,state_bottle_cost float8
    ,state_bottle_retail float8
    ,bottles_Sold int
    ,sale float8
    ,volume float8
    ,volumnt_gallons float8)
PRIMARY KEY  item_invoice_nbr;