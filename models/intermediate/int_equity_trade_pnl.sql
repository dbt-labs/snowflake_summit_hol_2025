with trading_books as (
    select * from {{ ref('stg_trading_books') }}
    where desk = 'Equity Desk'
),

stock_metrics as (
    select * from {{ ref('stg_stock_metrics') }}
),

-- Match BUY and SELL trades for the same ticker and trader
matched_trades as (
    select 
        b1.trade_id as buy_trade_id,
        b1.trade_date as buy_date,
        b1.trader_name,
        b1.desk,
        b1.ticker,
        b1.quantity,
        b1.price as buy_price,
        b2.trade_id as sell_trade_id,
        b2.trade_date as sell_date,
        b2.price as sell_price,
        b2.notes as sell_notes
    from trading_books b1
    join trading_books b2
        on b1.ticker = b2.ticker
        and b1.trader_name = b2.trader_name
        and b1.trade_type = 'BUY'
        and b2.trade_type = 'SELL'
        and b1.trade_date <= b2.trade_date
),

-- Calculate P&L for matched trades
matched_trades_pnl as (
    select
        m.*,
        (m.sell_price - m.buy_price) * m.quantity as pnl,
        (m.sell_price - m.buy_price) * m.quantity as pnl_usd  -- Same as pnl since already in USD
    from matched_trades m
),

-- Calculate P&L for individual trades
trade_pnl as (
    select
        t.trade_id,
        t.trade_date,
        t.trader_name,
        t.desk,
        t.ticker,
        t.quantity,
        t.price as trade_price,
        t.trade_type,
        t.notes,
        s.open_price as day_open,
        s.close_price as day_close,
        -- Calculate percentage differences from market prices
        case 
            when t.trade_type = 'BUY' then
                round(((s.open_price - t.price) / s.open_price) * 100, 2)
            when t.trade_type = 'SELL' then
                round(((t.price - s.open_price) / s.open_price) * 100, 2)
        end as vs_open_performance_pct,
        case 
            when t.trade_type = 'BUY' then
                round(((s.close_price - t.price) / s.close_price) * 100, 2)
            when t.trade_type = 'SELL' then
                round(((t.price - s.close_price) / s.close_price) * 100, 2)
        end as vs_close_performance_pct,
        -- Calculate overall market performance for the day
        round(((s.close_price - s.open_price) / s.open_price) * 100, 2) as market_daily_performance_pct,
        case 
            when t.trade_type = 'BUY' then
                case
                    when t.price < s.open_price then 'Better than open'
                    when t.price > s.open_price then 'Worse than open'
                    else 'Equal to open'
                end
            when t.trade_type = 'SELL' then
                case
                    when t.price > s.open_price then 'Better than open'
                    when t.price < s.open_price then 'Worse than open'
                    else 'Equal to open'
                end
        end as vs_open_price,
        case 
            when t.trade_type = 'BUY' then
                case
                    when t.price < s.close_price then 'Better than close'
                    when t.price > s.close_price then 'Worse than close'
                    else 'Equal to close'
                end
            when t.trade_type = 'SELL' then
                case
                    when t.price > s.close_price then 'Better than close'
                    when t.price < s.close_price then 'Worse than close'
                    else 'Equal to close'
                end
        end as vs_close_price,
        case 
            when t.trade_type = 'BUY' then
                case
                    when t.price < s.open_price and t.price < s.close_price then 'Best price of day'
                    when t.price > s.open_price and t.price > s.close_price then 'Worst price of day'
                    else 'Middle price of day'
                end
            when t.trade_type = 'SELL' then
                case
                    when t.price > s.open_price and t.price > s.close_price then 'Best price of day'
                    when t.price < s.open_price and t.price < s.close_price then 'Worst price of day'
                    else 'Middle price of day'
                end
        end as price_performance,
        -- Calculate relative performance vs market
        case 
            when t.trade_type = 'BUY' then
                case
                    when t.price < s.open_price and t.price < s.close_price then
                        round(((s.close_price - t.price) / t.price) * 100, 2)
                    when t.price > s.open_price and t.price > s.close_price then
                        round(((s.close_price - t.price) / t.price) * 100, 2)
                    else
                        round(((s.close_price - t.price) / t.price) * 100, 2)
                end
            when t.trade_type = 'SELL' then
                case
                    when t.price > s.open_price and t.price > s.close_price then
                        round(((t.price - s.open_price) / s.open_price) * 100, 2)
                    when t.price < s.open_price and t.price < s.close_price then
                        round(((t.price - s.open_price) / s.open_price) * 100, 2)
                    else
                        round(((t.price - s.open_price) / s.open_price) * 100, 2)
                end
        end as relative_performance_pct
    from trading_books t
    -- left join stock_metrics s
    join stock_metrics s
        on t.ticker = s.ticker
        and t.trade_date = s.run_date
)

-- Combine matched trades P&L with individual trade performance
select 
    t.*,
    m.pnl,
    m.pnl_usd,
    m.buy_trade_id,
    m.sell_trade_id,
    m.buy_date,
    m.sell_date,
    m.buy_price,
    m.sell_price,
    m.sell_notes
from trade_pnl t
-- left join matched_trades_pnl m
join matched_trades_pnl m
    on t.trade_id = m.buy_trade_id
    or t.trade_id = m.sell_trade_id 