

with source as (
    select * from {{ source('forex_data', 'FOREX_METRICS') }}
),
renamed as (
    select
        run_date,
        currency_pair_name,
        open as open_rate,
        high as high_rate,
        low as low_rate,
        close as close_rate
    from source   
)

select * from renamed 
where 1=1 
  AND run_date >= '2024-01-01'

