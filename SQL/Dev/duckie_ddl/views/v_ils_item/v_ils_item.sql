--TODO figure out how to tie the category name to the right day based on intervals
drop view duckie_ddl.v_ils_item;
create or replace view duckie_ddl.v_ils_item
as
select
      i.item_nbr
     ,d1.item_desc
     ,d1.items_per_pack
     ,d1.item_vol
     ,d1.category_nbr
     ,c1.category_desc
     ,i.start_date
     ,i.end_Date
     ,i.current_record
     ,d2.item_desc as orig_item_Desc
     ,d2.items_per_pack as orig_items_per_pack
     ,d2.item_vol as orig_item_vol     
     ,d2.category_nbr as orig_category_nbr
     ,c2.category_desc as orig_category_desc
     ,i.item_hash
     ,i.orig_item_hash
     
from
    duckie_ddl.d_ils_item i
    left outer join
        duckie_ddl.d_ils_item_detail d1
        on d1.item_hash = i.item_hash
    left outer join
        duckie_ddl.d_ils_category c1
        on c1.category_nbr = d1.category_nbr             
        and c1.current_record = 'Y'
    left outer join
        duckie_ddl.d_ils_item_detail d2
        on d2.item_hash = i.orig_item_hash
    left outer join
        duckie_ddl.d_ils_category c2
        on c2.category_nbr = d2.category_nbr
        and c2.current_record = 'Y'
         ;

