with trade_performance as (
    select * from {{ ref('int_trade_pnl') }}
),

-- Calculate daily P&L metrics by desk and ticker
daily_desk_metrics as (
    select
        p.desk,
        p.ticker,
        p.sell_date as trade_date,
        case 
            when p.ticker like '%/%' then 'Europe'
            else 'North America'
        end as region,
        count(distinct p.buy_trade_id) as total_trades,
        sum(p.quantity) as total_quantity,
        sum(p.pnl_usd) as total_pnl_usd,
        avg(p.quantity) as avg_trade_size,
        avg(p.pnl_usd) as avg_pnl_usd,
        -- Add trading performance metrics
        avg(p.vs_open_performance_pct) as avg_vs_open_performance_pct,
        avg(p.vs_close_performance_pct) as avg_vs_close_performance_pct,
        avg(p.market_daily_performance_pct) as avg_market_performance_pct,
        avg(p.relative_performance_pct) as avg_relative_performance_pct,
        count(case when p.price_performance = 'Best price of day' then 1 end) as best_price_trades,
        count(case when p.price_performance = 'Worst price of day' then 1 end) as worst_price_trades,
        count(case when p.price_performance = 'Middle price of day' then 1 end) as middle_price_trades
    from trade_performance p
    where p.buy_trade_id is not null  -- Only include matched trades
    group by 1, 2, 3, 4
),

-- Calculate cumulative metrics
cumulative_metrics as (
    select
        desk,
        ticker,
        trade_date,
        region,
        total_trades,
        total_quantity,
        total_pnl_usd,
        avg_trade_size,
        avg_pnl_usd,
        avg_vs_open_performance_pct,
        avg_vs_close_performance_pct,
        avg_market_performance_pct,
        avg_relative_performance_pct,
        best_price_trades,
        worst_price_trades,
        middle_price_trades,
        sum(total_pnl_usd) over (partition by desk, ticker order by trade_date) as cumulative_pnl_usd
    from daily_desk_metrics
)

select * from cumulative_metrics 