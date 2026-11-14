{{ config(
    materialized='view',
    tags=['staging', 'jaffle_shop']
) }}

select
    id as customer_id,
    first_name,
    last_name,
    _etl_loaded_at
from {{ source('jaffle_shop', 'customers') }}