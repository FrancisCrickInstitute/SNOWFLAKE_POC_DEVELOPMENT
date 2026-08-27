DEFINE DYNAMIC TABLE {{db}}.DM.F_BUDGET_VARIANCE
    lag = '5 minutes'
    refresh_mode = 'FULL'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    bv.BUDGET_ID,
    bv.FISCAL_YEAR,
    bv.FISCAL_QUARTER,
    cc.COST_CENTER_KEY,
    bv.COST_CENTER_NAME,
    bv.DIVISION,
    bv.ACCOUNT_ID,
    bv.ACCOUNT_NAME,
    bv.ACCOUNT_TYPE,
    bv.BUDGET_AMOUNT,
    bv.ACTUAL_AMOUNT,
    bv.VARIANCE_AMOUNT,
    bv.VARIANCE_PCT,
    bv.CURRENCY_CODE,
    bv.BUDGET_VERSION
from {{db}}.INT.V_BUDGET_WITH_VARIANCE bv
left join {{db}}.DM.D_COST_CENTER cc on bv.COST_CENTER_ID = cc.COST_CENTER_ID;
