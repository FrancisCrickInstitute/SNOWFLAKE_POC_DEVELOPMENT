DEFINE VIEW {{db}}.INT.V_EMPLOYEE_COMP_HISTORY(
    EMPLOYEE_ID,
    FIRST_NAME,
    LAST_NAME,
    EMPLOYEE_NAME,
    VALID_FROM,
    VALID_TO,
    SALARY_AMOUNT,
    BONUS_TARGET_PCT,
    CURRENCY_CODE,
    CHANGE_REASON,
    IS_CURRENT_COMP
) as
with EMP_EARLIEST as (
    select EMPLOYEE_ID, min(VALID_FROM) as EARLIEST_FROM
    from {{db}}.STG.V_EMPLOYEES_HISTORY
    group by EMPLOYEE_ID
)
select
    c.EMPLOYEE_ID,
    e.FIRST_NAME,
    e.LAST_NAME,
    e.FIRST_NAME || ' ' || e.LAST_NAME as EMPLOYEE_NAME,
    c.EFFECTIVE_DATE as VALID_FROM,
    coalesce(
        dateadd(day, -1,
            lead(c.EFFECTIVE_DATE) over (
                partition by c.EMPLOYEE_ID
                order by c.EFFECTIVE_DATE
            )
        ),
        to_date('9999-12-31')
    ) as VALID_TO,
    c.SALARY_AMOUNT,
    c.BONUS_TARGET_PCT,
    c.CURRENCY_CODE,
    c.CHANGE_REASON,
    iff(
        lead(c.EFFECTIVE_DATE) over (
            partition by c.EMPLOYEE_ID
            order by c.EFFECTIVE_DATE
        ) is null,
        true,
        false
    ) as IS_CURRENT_COMP
from {{db}}.STG.V_COMPENSATION_EVENTS c
left join EMP_EARLIEST ee on c.EMPLOYEE_ID = ee.EMPLOYEE_ID
left join {{db}}.STG.V_EMPLOYEES_HISTORY e
    on c.EMPLOYEE_ID = e.EMPLOYEE_ID
   and greatest(to_timestamp_ntz(c.EFFECTIVE_DATE), ee.EARLIEST_FROM) between e.VALID_FROM and e.VALID_TO;
