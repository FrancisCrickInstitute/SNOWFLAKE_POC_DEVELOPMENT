DEFINE DYNAMIC TABLE {{db}}.DM.D_COUNTRY
    lag = '5 minutes'
    refresh_mode = 'FULL'
    initialize = 'ON_CREATE'
    warehouse = {{transform_wh}}
as
select
    row_number() over (order by COUNTRY_CODE_ISO2) as COUNTRY_KEY,
    COUNTRY_CODE_ISO2,
    COUNTRY_CODE_ISO3,
    COUNTRY_NAME,
    CONTINENT,
    REGION,
    SUB_REGION,
    CURRENCY_CODE,
    CURRENCY_NAME
from {{db}}.STG.V_COUNTRY_CODES
where IS_ACTIVE = true;
