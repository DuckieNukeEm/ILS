
create or replace view pg_table_def
as
select
     pt.table_catalog   
    ,pt.table_schema as schema_name  
    ,pt.table_name 
    ,pt.column_name    
    ,pt.column_default
    ,pt.is_nullable
    ,pt.data_type
    ,pt.character_maximum_length
    ,pt.character_octet_length
    ,pt.numeric_precision
    ,pt.numeric_precision_radix
    ,pt.numeric_scale
    ,pt.datetime_precision
    ,pt.interval_type
    ,pt.interval_precision
    ,pt.character_set_catalog
    ,pt.character_set_schema
    ,pt.character_set_name
    ,pt.collation_catalog
    ,pt.collation_schema
    ,pt.collation_name
    ,pt.domain_catalog
    ,pt.domain_schema
    ,pt.domain_name
    ,pt.udt_catalog
    ,pt.udt_schema
    ,pt.udt_name
    ,pt.scope_catalog
    ,pt.scope_schema
    ,pt.scope_name    
    ,pt.maximum_cardinality
    ,pt.dtd_identifier
    ,pt.is_self_referencing
    ,pt.is_identity
    ,pt.identity_generation
    ,pt.identity_start
    ,pt.identity_increment
    ,pt.identity_maximum
    ,pt.identity_minimum
    ,pt.identity_cycle
    ,pt.is_generated
    ,pt.generation_expression
    ,pt.is_updatable
    ,pt.table_name as tablename
from
    information_schema.columns as pt;