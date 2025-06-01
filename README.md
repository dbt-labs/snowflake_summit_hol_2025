# Deploying Pipelines with Snowflake and dbt Labs

## Overview

In this hands-on lab, we will build a data pipeline using Snowflake and dbt to analyze trading P&L across multiple currencies, normalize trade data using FX rates, and compare actual performance against portfolio targets. We will integrate datasets from Snowflake Marketplace (FX rates, US equity price history) and manual sources (trading history, target allocation ratios) to generate insights. Additionally, we will leverage LLMs to extract patterns and sentiment from trader execution notes, helping assess decision-making. By the end of this lab, you will have a working pipeline that blends market and portfolio data, enabling performance assessment and deeper insights into trading behavior.

## Step-By-Step Guide

For prerequisites, environment setup, step-by-step guide and instructions, please refer to the [QuickStart Guide](https://quickstarts.snowflake.com/guide/data_engineering_deploying_pipelines_with_snowflake_and_dbt_labs/index.html).


## Notes and Resources for the Lab

To sign-up and create your dbt Cloud account follow this link https://cloud.getdbt.com/coalesce-workshop-signup/?id=20
and enter your information along with the password: dbtSnow2025!

If you want to examine the source data we are using there are four based tables you can query directly through dbt Insights:
    
    Created fake data sets loaded as Seeds include
    1. ANALYTICS.SNOWFLAKE_SUMMIT_HOL_RAW.WEIGHTS_TABLE
    2. ANALYTICS.SNOWFLAKE_SUMMIT_HOL_RAW.TRADING_BOOKS
    
    Public Data Sets Avaliable through Snowflake Marketplace include
    1. STOCK_TRACKING_US_STOCK_PRICES_BY_DAY.STOCK.US_STOCK_METRICS
    2. FOREX_TRACKING_CURRENCY_EXCHANGE_RATES_BY_DAY.STOCK.FOREX_METRICS

Example Configuration Blocks for Dynamic Tables:

    {{ config(
        materialized="dynamic_table",
        target_lag="1 minutes",
        snowflake_warehouse="transformer_coalesce",
        refresh_mode="FULL"
    ) }}
