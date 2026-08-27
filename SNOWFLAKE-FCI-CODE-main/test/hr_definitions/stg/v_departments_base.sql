DEFINE VIEW {{db}}.STG.V_DEPARTMENTS_BASE(
    RAW_ROW_ID,
    DEPARTMENT_ID,
    DEPARTMENT_NAME,
    COST_CENTER,
    BUSINESS_UNIT,
    MANAGER_EMPLOYEE_ID,
    ACTIVE_FLAG,
    SRC_UPDATED_AT,
    LOAD_TS,
    CHANGE_TS,
    ATTR_HASH
) as
select
    RAW_ROW_ID,
    DEPARTMENT_ID,
    trim(DEPARTMENT_NAME) as DEPARTMENT_NAME,
    upper(COST_CENTER) as COST_CENTER,
    trim(BUSINESS_UNIT) as BUSINESS_UNIT,
    MANAGER_EMPLOYEE_ID,
    ACTIVE_FLAG,
    SRC_UPDATED_AT,
    LOAD_TS,
    coalesce(SRC_UPDATED_AT, LOAD_TS) as CHANGE_TS,
    md5(concat_ws('|',
        coalesce(trim(DEPARTMENT_NAME), ''),
        coalesce(upper(COST_CENTER), ''),
        coalesce(trim(BUSINESS_UNIT), ''),
        coalesce(MANAGER_EMPLOYEE_ID, ''),
        iff(ACTIVE_FLAG, 'Y', 'N')
    )) as ATTR_HASH
from {{db}}.RAW.DEPARTMENTS_RAW;
