DEFINE VIEW {{db}}.STG.V_JOBS_HISTORY(
    JOB_ID,
    JOB_TITLE,
    JOB_FAMILY,
    JOB_LEVEL,
    EXEMPT_FLAG,
    GRADE_BAND,
    FTE_STANDARD_HOURS,
    VALID_FROM,
    VALID_TO,
    IS_CURRENT,
    SRC_UPDATED_AT,
    LOAD_TS
) as
with DEDUPED as (
    select *
    from {{db}}.STG.V_JOBS_BASE
    qualify row_number() over (
        partition by JOB_ID, CHANGE_TS, ATTR_HASH
        order by LOAD_TS desc, RAW_ROW_ID desc
    ) = 1
),
CHANGED as (
    select
        *,
        lag(ATTR_HASH) over (
            partition by JOB_ID
            order by CHANGE_TS, LOAD_TS, RAW_ROW_ID
        ) as PREV_ATTR_HASH,
        lead(CHANGE_TS) over (
            partition by JOB_ID
            order by CHANGE_TS, LOAD_TS, RAW_ROW_ID
        ) as NEXT_CHANGE_TS
    from DEDUPED
)
select
    JOB_ID,
    JOB_TITLE,
    JOB_FAMILY,
    JOB_LEVEL,
    EXEMPT_FLAG,
    GRADE_BAND,
    FTE_STANDARD_HOURS,
    CHANGE_TS as VALID_FROM,
    coalesce(dateadd(second, -1, NEXT_CHANGE_TS), to_timestamp_ntz('9999-12-31 23:59:59')) as VALID_TO,
    iff(NEXT_CHANGE_TS is null, true, false) as IS_CURRENT,
    SRC_UPDATED_AT,
    LOAD_TS
from CHANGED
where PREV_ATTR_HASH is null or PREV_ATTR_HASH <> ATTR_HASH;
