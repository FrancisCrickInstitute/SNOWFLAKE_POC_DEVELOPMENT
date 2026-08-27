DEFINE VIEW {{db}}.STG.V_EMPLOYEES_HISTORY(
    EMPLOYEE_ID,
    FIRST_NAME,
    LAST_NAME,
    GENDER,
    ETHNICITY,
    DATE_OF_BIRTH,
    HIRE_DATE,
    TERMINATION_DATE,
    EMPLOYMENT_STATUS,
    EMPLOYMENT_TYPE,
    EMAIL,
    IS_ACTIVE,
    VALID_FROM,
    VALID_TO,
    IS_CURRENT,
    SRC_UPDATED_AT,
    LOAD_TS
) as
with DEDUPED as (
    select *
    from {{db}}.STG.V_EMPLOYEES_BASE
    qualify row_number() over (
        partition by EMPLOYEE_ID, CHANGE_TS, ATTR_HASH
        order by LOAD_TS desc, RAW_ROW_ID desc
    ) = 1
),
CHANGED as (
    select
        *,
        lag(ATTR_HASH) over (
            partition by EMPLOYEE_ID
            order by CHANGE_TS, LOAD_TS, RAW_ROW_ID
        ) as PREV_ATTR_HASH,
        lead(CHANGE_TS) over (
            partition by EMPLOYEE_ID
            order by CHANGE_TS, LOAD_TS, RAW_ROW_ID
        ) as NEXT_CHANGE_TS
    from DEDUPED
)
select
    EMPLOYEE_ID,
    FIRST_NAME,
    LAST_NAME,
    GENDER,
    ETHNICITY,
    DATE_OF_BIRTH,
    HIRE_DATE,
    TERMINATION_DATE,
    EMPLOYMENT_STATUS,
    EMPLOYMENT_TYPE,
    EMAIL,
    IS_ACTIVE,
    CHANGE_TS as VALID_FROM,
    coalesce(dateadd(second, -1, NEXT_CHANGE_TS), to_timestamp_ntz('9999-12-31 23:59:59')) as VALID_TO,
    iff(NEXT_CHANGE_TS is null, true, false) as IS_CURRENT,
    SRC_UPDATED_AT,
    LOAD_TS
from CHANGED
where PREV_ATTR_HASH is null or PREV_ATTR_HASH <> ATTR_HASH;
