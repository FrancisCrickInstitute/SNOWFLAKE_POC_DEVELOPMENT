DEFINE DYNAMIC TABLE {{db}}.DM.D_JOB_CURRENT
    lag = '5 minutes'
    refresh_mode = 'AUTO'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    row_number() over (order by JOB_ID) as JOB_KEY,
    JOB_ID,
    JOB_TITLE,
    JOB_FAMILY,
    JOB_LEVEL,
    EXEMPT_FLAG,
    GRADE_BAND,
    FTE_STANDARD_HOURS
from {{db}}.STG.V_JOBS_CURRENT;
