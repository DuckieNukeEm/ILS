--TODO figure out how to tie the category name to the right day based on intervals
drop view if exists duckie_ddl.v_ils_store;
create or replace view duckie_ddl.v_ils_store
as
select
     s.store_nbr
    ,a1.store_name     
    ,a1.store_address 
    ,a1.store_city    
    ,a1.zip_code      
    ,c1.county_name as county         
    ,a1.lat              
    ,a1.long                
    ,s.start_date
    ,s.end_Date
    ,s.current_record
    ,a2.store_name     as orig_store_name
    ,a2.store_address  as orig_store_address
    ,a2.store_city     as orig_store_city
    ,a2.zip_code       as orig_zip_code
    ,c2.county_name    as orig_county
    ,a2.lat            as orig_lat  
    ,a2.long           as orig_long
    ,s.store_hash
    ,s.orig_store_hash
     
from
    duckie_ddl.d_ils_store s
    left outer join
        duckie_ddl.d_ils_store_address a1
        on a1.store_hash = s.store_hash
    left outer join
        duckie_ddl.d_ils_county c1
        on c1.county_nbr  = a1.county_nbr   
    left outer join
        duckie_ddl.d_ils_store_Address a2
        on a2.store_hash = s.orig_store_hash
    left outer join
        duckie_ddl.d_ils_county c2
        on c2.county_nbr = a2.county_nbr
         ;
select * from v_ils_Store;
select * from d_ils_vendor;