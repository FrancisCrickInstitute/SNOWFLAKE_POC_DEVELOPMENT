DEFINE DYNAMIC TABLE {{db}}.DM.F_EMPLOYEE_COMP_HISTORY
    lag = '5 minutes'
    refresh_mode = 'AUTO'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    row_number() over (order by h.EMPLOYEE_ID, h.VALID_FROM) as EMPLOYEE_COMP_HISTORY_KEY,
    e.EMPLOYEE_KEY,
    e.DEPARTMENT_KEY,
    e.JOB_KEY,
    h.EMPLOYEE_ID,
    h.EMPLOYEE_NAME,
    h.VALID_FROM,
    h.VALID_TO,
    h.SALARY_AMOUNT,
    h.BONUS_TARGET_PCT,
    h.CURRENCY_CODE,
    h.CHANGE_REASON,
    h.IS_CURRENT_COMP
from {{db}}.INT.V_EMPLOYEE_COMP_HISTORY h
left join {{db}}.DM.D_EMPLOYEE_CURRENT e
    on h.EMPLOYEE_ID = e.EMPLOYEE_ID;
