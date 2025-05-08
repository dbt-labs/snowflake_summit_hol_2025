with source as (
    select * from {{ source('trading_data', 'trading_books') }}
),

renamed as (
    select
        trade_id,
        trade_date,
        trader_name,
        desk,
        ticker,
        quantity,
        price,
        trade_type,
        notes
    from source
)

select * from renamed 