with source as (
    select *
    from {{ source('portfolio_data', 'weights_table') }}
),
renamed as (
    select region,
        desk,
        target_allocation
    from source
)
select *
from renamed