DEFINE VIEW {{db}}.STG.V_JOBS_BASE(
    RAW_ROW_ID,
    JOB_ID,
    JOB_TITLE,
    JOB_FAMILY,
    JOB_LEVEL,
    EXEMPT_FLAG,
    GRADE_BAND,
    FTE_STANDARD_HOURS,
    SRC_UPDATED_AT,
    LOAD_TS,
    CHANGE_TS,
    ATTR_HASH
) as
select
    RAW_ROW_ID,
    JOB_ID,
    trim(JOB_TITLE) as JOB_TITLE,
    trim(JOB_FAMILY) as JOB_FAMILY,
    upper(JOB_LEVEL) as JOB_LEVEL,
    EXEMPT_FLAG,
    upper(GRADE_BAND) as GRADE_BAND,
    FTE_STANDARD_HOURS,
    SRC_UPDATED_AT,
    LOAD_TS,
    coalesce(SRC_UPDATED_AT, LOAD_TS) as CHANGE_TS,
    md5(concat_ws('|',
        coalesce(trim(JOB_TITLE), ''),
        coalesce(trim(JOB_FAMILY), ''),
        coalesce(upper(JOB_LEVEL), ''),
        iff(EXEMPT_FLAG, 'Y', 'N'),
        coalesce(upper(GRADE_BAND), ''),
        coalesce(to_varchar(FTE_STANDARD_HOURS), '')
    )) as ATTR_HASH
from {{db}}.RAW.JOBS_RAW;
