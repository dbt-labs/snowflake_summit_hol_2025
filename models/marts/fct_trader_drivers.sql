

with extracted_entities as (
    select * from {{ ref('int_extracted_entities') }}
),

-- Calculate trade driver statistics by trader
trader_driver_stats as (
    select
        trader_name,
        trade_driver,
        count(*) as total_trades,
        array_agg(distinct signal[0]:"answer"::string) as signals_used
    from extracted_entities
    where trade_driver is not null
    group by 1, 2
),

-- Calculate total trades per trader for percentage calculation
trader_totals as (
    select
        trader_name,
        sum(total_trades) as total_trades
    from trader_driver_stats
    group by 1
),

-- Combine statistics with percentages
final_stats as (
    select
        tds.trader_name,
        tds.trade_driver,
        tds.total_trades,
        tds.signals_used,
        round(tds.total_trades * 100.0 / nullif(tt.total_trades, 0), 2) as driver_percentage
    from trader_driver_stats tds
    join trader_totals tt
        on tds.trader_name = tt.trader_name
)

select * from final_stats
order by trader_name, total_trades desc 