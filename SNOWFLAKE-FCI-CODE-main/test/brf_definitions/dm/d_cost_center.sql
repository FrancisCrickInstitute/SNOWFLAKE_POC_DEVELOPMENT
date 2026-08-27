DEFINE DYNAMIC TABLE {{db}}.DM.D_COST_CENTER
    lag = '5 minutes'
    refresh_mode = 'FULL'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    row_number() over (order by COST_CENTER_ID) as COST_CENTER_KEY,
    COST_CENTER_ID,
    COST_CENTER_NAME,
    DEPARTMENT_CODE,
    DIVISION,
    MANAGER_NAME,
    BUDGET_OWNER,
    IS_ACTIVE
from {{db}}.STG.V_COST_CENTERS;
