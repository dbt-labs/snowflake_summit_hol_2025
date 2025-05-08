with pnl_by_desk as (
    select * from {{ ref('fct_pnl_by_desk') }}
),

weights as (
    select * from {{ ref('stg_weights') }}
),

-- Calculate total portfolio value by desk and region
portfolio_value as (
    select
        trade_date,
        desk,
        region,
        sum(total_pnl_usd) as portfolio_value_usd,
        avg(avg_vs_open_performance_pct) as portfolio_vs_open_performance,
        avg(avg_vs_close_performance_pct) as portfolio_vs_close_performance,
        avg(avg_market_performance_pct) as portfolio_market_performance,
        avg(avg_relative_performance_pct) as portfolio_relative_performance,
        sum(best_price_trades) as total_best_price_trades,
        sum(worst_price_trades) as total_worst_price_trades,
        sum(middle_price_trades) as total_middle_price_trades
    from pnl_by_desk
    group by 1, 2, 3
),

-- Calculate total portfolio value across all desks and regions for each date
total_portfolio_value as (
    select
        trade_date,
        sum(portfolio_value_usd) as total_portfolio_value_usd
    from portfolio_value
    group by 1
),

-- Calculate actual allocations and compare with targets
allocation_variance as (
    select
        pv.trade_date,
        pv.desk,
        pv.region,
        w.target_allocation,
        pv.portfolio_value_usd,
        tp.total_portfolio_value_usd,
        pv.portfolio_vs_open_performance,
        pv.portfolio_vs_close_performance,
        pv.portfolio_market_performance,
        pv.portfolio_relative_performance,
        pv.total_best_price_trades,
        pv.total_worst_price_trades,
        pv.total_middle_price_trades,
        pv.portfolio_value_usd / nullif(tp.total_portfolio_value_usd, 0) as actual_allocation,
        (pv.portfolio_value_usd / nullif(tp.total_portfolio_value_usd, 0) - w.target_allocation) as allocation_variance,
        case
            when pv.portfolio_value_usd / nullif(tp.total_portfolio_value_usd, 0) > w.target_allocation then 'Overweight'
            when pv.portfolio_value_usd / nullif(tp.total_portfolio_value_usd, 0) < w.target_allocation then 'Underweight'
            else 'On Target'
        end as allocation_status
    from portfolio_value pv
    join total_portfolio_value tp
        on pv.trade_date = tp.trade_date
    join weights w
        on pv.desk = w.desk
        and pv.region = w.region
)

select * from allocation_variance 