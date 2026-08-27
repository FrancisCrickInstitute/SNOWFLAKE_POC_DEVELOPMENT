DEFINE VIEW {{db}}.INT.V_EMPLOYEE_JOB_HISTORY(
    EMPLOYEE_ID,
    FIRST_NAME,
    LAST_NAME,
    EMPLOYEE_NAME,
    VALID_FROM,
    VALID_TO,
    JOB_ID,
    JOB_TITLE,
    JOB_FAMILY,
    JOB_LEVEL,
    GRADE_BAND,
    DEPARTMENT_ID,
    DEPARTMENT_NAME,
    BUSINESS_UNIT,
    COST_CENTER,
    MANAGER_EMPLOYEE_ID,
    MANAGER_NAME,
    LOCATION_CODE,
    EVENT_TYPE,
    IS_CURRENT_JOB
) as
with DEPT_EARLIEST as (
    select DEPARTMENT_ID, min(VALID_FROM) as EARLIEST_FROM
    from {{db}}.STG.V_DEPARTMENTS_HISTORY
    group by DEPARTMENT_ID
),
JOB_EARLIEST as (
    select JOB_ID, min(VALID_FROM) as EARLIEST_FROM
    from {{db}}.STG.V_JOBS_HISTORY
    group by JOB_ID
),
EMP_EARLIEST as (
    select EMPLOYEE_ID, min(VALID_FROM) as EARLIEST_FROM
    from {{db}}.STG.V_EMPLOYEES_HISTORY
    group by EMPLOYEE_ID
)
select
    j.EMPLOYEE_ID,
    e.FIRST_NAME,
    e.LAST_NAME,
    e.FIRST_NAME || ' ' || e.LAST_NAME as EMPLOYEE_NAME,
    j.EFFECTIVE_DATE as VALID_FROM,
    coalesce(
        dateadd(day, -1,
            lead(j.EFFECTIVE_DATE) over (
                partition by j.EMPLOYEE_ID
                order by j.EFFECTIVE_DATE
            )
        ),
        to_date('9999-12-31')
    ) as VALID_TO,
    j.JOB_ID,
    jb.JOB_TITLE,
    jb.JOB_FAMILY,
    jb.JOB_LEVEL,
    jb.GRADE_BAND,
    j.DEPARTMENT_ID,
    d.DEPARTMENT_NAME,
    d.BUSINESS_UNIT,
    d.COST_CENTER,
    j.MANAGER_EMPLOYEE_ID,
    m.FIRST_NAME || ' ' || m.LAST_NAME as MANAGER_NAME,
    j.LOCATION_CODE,
    j.EVENT_TYPE,
    iff(
        lead(j.EFFECTIVE_DATE) over (
            partition by j.EMPLOYEE_ID
            order by j.EFFECTIVE_DATE
        ) is null,
        true,
        false
    ) as IS_CURRENT_JOB
from {{db}}.STG.V_EMPLOYEE_JOB_EVENTS j
left join EMP_EARLIEST ee on j.EMPLOYEE_ID = ee.EMPLOYEE_ID
left join {{db}}.STG.V_EMPLOYEES_HISTORY e
    on j.EMPLOYEE_ID = e.EMPLOYEE_ID
   and greatest(to_timestamp_ntz(j.EFFECTIVE_DATE), ee.EARLIEST_FROM) between e.VALID_FROM and e.VALID_TO
left join DEPT_EARLIEST de on j.DEPARTMENT_ID = de.DEPARTMENT_ID
left join {{db}}.STG.V_DEPARTMENTS_HISTORY d
    on j.DEPARTMENT_ID = d.DEPARTMENT_ID
   and greatest(to_timestamp_ntz(j.EFFECTIVE_DATE), de.EARLIEST_FROM) between d.VALID_FROM and d.VALID_TO
left join JOB_EARLIEST je on j.JOB_ID = je.JOB_ID
left join {{db}}.STG.V_JOBS_HISTORY jb
    on j.JOB_ID = jb.JOB_ID
   and greatest(to_timestamp_ntz(j.EFFECTIVE_DATE), je.EARLIEST_FROM) between jb.VALID_FROM and jb.VALID_TO
left join EMP_EARLIEST me on j.MANAGER_EMPLOYEE_ID = me.EMPLOYEE_ID
left join {{db}}.STG.V_EMPLOYEES_HISTORY m
    on j.MANAGER_EMPLOYEE_ID = m.EMPLOYEE_ID
   and greatest(to_timestamp_ntz(j.EFFECTIVE_DATE), coalesce(me.EARLIEST_FROM, to_timestamp_ntz('9999-12-31'))) between m.VALID_FROM and m.VALID_TO;
