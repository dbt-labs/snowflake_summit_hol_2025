
with trading_books as (
    select * from {{ ref('stg_trading_books') }}
),

-- Extract sentiment using SNOWFLAKE.CORTEX.SENTIMENT
cst as (
    select
        trade_id,
        trade_date,
        trader_name,
        desk,
        ticker,
        quantity,
        price,
        trade_type,
        notes,
        SNOWFLAKE.CORTEX.SENTIMENT(notes) as sentiment,
        SNOWFLAKE.CORTEX.EXTRACT_ANSWER(notes, 'What is the signal driving the following trade?') as signal,
        SNOWFLAKE.CORTEX.CLASSIFY_TEXT(notes||': '|| signal[0]:"answer"::string,['Market Signal','Execution Strategy']):"label"::string as trade_driver
    from trading_books
    where notes is not null
)
select * from cst 