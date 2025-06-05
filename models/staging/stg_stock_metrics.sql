{{ config(
    materialized="dynamic_table",
    target_lag="1 minutes",
    snowflake_warehouse="transformer_coalesce",
    refresh_mode="FULL"
) }}
with source as (
    select * from {{ source('stock_data', 'US_STOCK_METRICS') }}
),

renamed as (
    select
        run_date,
        ticker,
        open as open_price,
        high as high_price,
        low as low_price,
        close as close_price,
        volume
    from source
)

select * from renamed 
where run_date >= '2024-01-01'
and ticker is not null 