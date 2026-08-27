-- =============================================================================
-- GENERAL Domain: Seed Data
-- =============================================================================
-- Jinja variable: {{db}} (passed via -D "db=<DATABASE_NAME>")
-- =============================================================================

use database {{db}};

-- Date dimension (2024-2026)
insert into {{db}}.RAW.DATE_DIMENSION_RAW (
    DATE_KEY, FULL_DATE, DAY_OF_WEEK, DAY_NAME, DAY_OF_MONTH, DAY_OF_YEAR,
    WEEK_OF_YEAR, MONTH_NUMBER, MONTH_NAME, QUARTER_NUMBER, QUARTER_NAME,
    YEAR_NUMBER, FISCAL_YEAR, FISCAL_QUARTER, IS_WEEKEND, IS_HOLIDAY, HOLIDAY_NAME, LOAD_TS
)
select
    to_number(to_char(d.DATE_VAL, 'YYYYMMDD')) as DATE_KEY,
    d.DATE_VAL as FULL_DATE,
    dayofweek(d.DATE_VAL) as DAY_OF_WEEK,
    dayname(d.DATE_VAL) as DAY_NAME,
    day(d.DATE_VAL) as DAY_OF_MONTH,
    dayofyear(d.DATE_VAL) as DAY_OF_YEAR,
    weekofyear(d.DATE_VAL) as WEEK_OF_YEAR,
    month(d.DATE_VAL) as MONTH_NUMBER,
    monthname(d.DATE_VAL) as MONTH_NAME,
    quarter(d.DATE_VAL) as QUARTER_NUMBER,
    'Q' || quarter(d.DATE_VAL) as QUARTER_NAME,
    year(d.DATE_VAL) as YEAR_NUMBER,
    case when month(d.DATE_VAL) >= 4 then year(d.DATE_VAL) + 1 else year(d.DATE_VAL) end as FISCAL_YEAR,
    case
        when month(d.DATE_VAL) in (4,5,6) then 1
        when month(d.DATE_VAL) in (7,8,9) then 2
        when month(d.DATE_VAL) in (10,11,12) then 3
        else 4
    end as FISCAL_QUARTER,
    case when dayofweek(d.DATE_VAL) in (0, 6) then true else false end as IS_WEEKEND,
    false as IS_HOLIDAY,
    null as HOLIDAY_NAME,
    current_timestamp() as LOAD_TS
from (
    select dateadd(day, seq4(), '2024-01-01'::date) as DATE_VAL
    from table(generator(rowcount => 1096))
) d
where d.DATE_VAL <= '2026-12-31';

-- Country codes
insert into {{db}}.RAW.COUNTRY_CODES_RAW (
    COUNTRY_CODE_ISO2, COUNTRY_CODE_ISO3, COUNTRY_NAME, CONTINENT, REGION,
    SUB_REGION, CURRENCY_CODE, CURRENCY_NAME, ACTIVE_FLAG, SRC_UPDATED_AT, LOAD_TS
)
values
    ('US', 'USA', 'United States', 'North America', 'Americas', 'Northern America', 'USD', 'US Dollar', true, current_timestamp(), current_timestamp()),
    ('GB', 'GBR', 'United Kingdom', 'Europe', 'Europe', 'Northern Europe', 'GBP', 'Pound Sterling', true, current_timestamp(), current_timestamp()),
    ('DE', 'DEU', 'Germany', 'Europe', 'Europe', 'Western Europe', 'EUR', 'Euro', true, current_timestamp(), current_timestamp()),
    ('FR', 'FRA', 'France', 'Europe', 'Europe', 'Western Europe', 'EUR', 'Euro', true, current_timestamp(), current_timestamp()),
    ('JP', 'JPN', 'Japan', 'Asia', 'Asia', 'Eastern Asia', 'JPY', 'Japanese Yen', true, current_timestamp(), current_timestamp()),
    ('AU', 'AUS', 'Australia', 'Oceania', 'Oceania', 'Australia and New Zealand', 'AUD', 'Australian Dollar', true, current_timestamp(), current_timestamp()),
    ('CA', 'CAN', 'Canada', 'North America', 'Americas', 'Northern America', 'CAD', 'Canadian Dollar', true, current_timestamp(), current_timestamp()),
    ('CH', 'CHE', 'Switzerland', 'Europe', 'Europe', 'Western Europe', 'CHF', 'Swiss Franc', true, current_timestamp(), current_timestamp()),
    ('SG', 'SGP', 'Singapore', 'Asia', 'Asia', 'South-Eastern Asia', 'SGD', 'Singapore Dollar', true, current_timestamp(), current_timestamp()),
    ('IN', 'IND', 'India', 'Asia', 'Asia', 'Southern Asia', 'INR', 'Indian Rupee', true, current_timestamp(), current_timestamp());

-- Currency exchange rates (sample dates)
insert into {{db}}.RAW.CURRENCY_RATES_RAW (
    RAW_ROW_ID, RATE_DATE, BASE_CURRENCY, TARGET_CURRENCY, EXCHANGE_RATE,
    SOURCE_SYSTEM, SRC_UPDATED_AT, LOAD_TS
)
values
    ('CR-001', '2026-01-02', 'USD', 'GBP', 0.78920000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-002', '2026-01-02', 'USD', 'EUR', 0.92150000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-003', '2026-01-02', 'USD', 'JPY', 148.35000000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-004', '2026-01-02', 'USD', 'AUD', 1.53200000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-005', '2026-01-02', 'USD', 'CAD', 1.35800000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-006', '2026-01-02', 'USD', 'CHF', 0.88400000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-007', '2026-06-15', 'USD', 'GBP', 0.79450000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-008', '2026-06-15', 'USD', 'EUR', 0.91800000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-009', '2026-06-15', 'USD', 'JPY', 151.20000000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-010', '2026-06-15', 'USD', 'AUD', 1.54100000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-011', '2026-08-01', 'USD', 'GBP', 0.78100000, 'ECB', current_timestamp(), current_timestamp()),
    ('CR-012', '2026-08-01', 'USD', 'EUR', 0.93200000, 'ECB', current_timestamp(), current_timestamp());
