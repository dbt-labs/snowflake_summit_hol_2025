with equity_trades as (
    select * from {{ ref('int_equity_trade_pnl') }}
),

fx_trades as (
    select * from {{ ref('int_fx_trade_pnl') }}
)

select * from equity_trades
union all
select * from fx_trades 