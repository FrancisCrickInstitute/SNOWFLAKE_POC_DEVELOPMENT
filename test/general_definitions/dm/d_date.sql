DEFINE DYNAMIC TABLE {{db}}.DM.D_DATE
    lag = '5 minutes'
    refresh_mode = 'FULL'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    DATE_KEY,
    FULL_DATE,
    DAY_OF_WEEK,
    DAY_NAME,
    DAY_OF_MONTH,
    DAY_OF_YEAR,
    WEEK_OF_YEAR,
    MONTH_NUMBER,
    MONTH_NAME,
    QUARTER_NUMBER,
    QUARTER_NAME,
    YEAR_NUMBER,
    FISCAL_YEAR,
    FISCAL_QUARTER,
    IS_WEEKEND,
    IS_HOLIDAY,
    HOLIDAY_NAME,
    case when DAY_OF_MONTH = 1 then true else false end as IS_MONTH_START,
    case when DAY_OF_MONTH = dayofmonth(last_day(FULL_DATE)) then true else false end as IS_MONTH_END
from {{db}}.STG.V_DATE_DIMENSION;
