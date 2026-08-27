DEFINE DYNAMIC TABLE {{db}}.DM.F_EMPLOYEE_JOB_HISTORY
    lag = '5 minutes'
    refresh_mode = 'AUTO'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    row_number() over (order by h.EMPLOYEE_ID, h.VALID_FROM) as EMPLOYEE_JOB_HISTORY_KEY,
    e.EMPLOYEE_KEY,
    d.DEPARTMENT_KEY,
    j.JOB_KEY,
    h.EMPLOYEE_ID,
    h.EMPLOYEE_NAME,
    h.VALID_FROM,
    h.VALID_TO,
    h.JOB_ID,
    h.JOB_TITLE,
    h.JOB_FAMILY,
    h.JOB_LEVEL,
    h.GRADE_BAND,
    h.DEPARTMENT_ID,
    h.DEPARTMENT_NAME,
    h.BUSINESS_UNIT,
    h.COST_CENTER,
    h.MANAGER_EMPLOYEE_ID,
    h.MANAGER_NAME,
    h.LOCATION_CODE,
    h.EVENT_TYPE,
    h.IS_CURRENT_JOB
from {{db}}.INT.V_EMPLOYEE_JOB_HISTORY h
left join {{db}}.DM.D_EMPLOYEE_CURRENT e
    on h.EMPLOYEE_ID = e.EMPLOYEE_ID
left join {{db}}.DM.D_DEPARTMENT_CURRENT d
    on h.DEPARTMENT_ID = d.DEPARTMENT_ID
left join {{db}}.DM.D_JOB_CURRENT j
    on h.JOB_ID = j.JOB_ID;
