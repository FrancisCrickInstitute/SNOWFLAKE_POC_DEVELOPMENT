-- ============================================================================
-- HR Domain: PII Column Tagging
-- ============================================================================
-- Applies PII_CATEGORY and PII_CLASSIFICATION tags to columns containing
-- personal data. Tag-based masking policies (in GOVERNANCE_DB) automatically
-- mask these columns unless the querying role holds PII_HR_FULL_ACCESS or
-- PII_HR_PARTIAL_ACCESS.
-- ============================================================================

-- EMPLOYEES_RAW: person names
alter table {{db}}.RAW.EMPLOYEES_RAW modify
    column FIRST_NAME set tag ADMIN_DB.TAGS.PII_CATEGORY = 'NAME',
    column FIRST_NAME set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'CONFIDENTIAL',
    column LAST_NAME set tag ADMIN_DB.TAGS.PII_CATEGORY = 'NAME',
    column LAST_NAME set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'CONFIDENTIAL';

-- EMPLOYEES_RAW: email
alter table {{db}}.RAW.EMPLOYEES_RAW modify
    column EMAIL set tag ADMIN_DB.TAGS.PII_CATEGORY = 'EMAIL',
    column EMAIL set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'CONFIDENTIAL';

-- EMPLOYEES_RAW: sensitive personal attributes
alter table {{db}}.RAW.EMPLOYEES_RAW modify
    column DATE_OF_BIRTH set tag ADMIN_DB.TAGS.PII_CATEGORY = 'SENSITIVE_DATE',
    column DATE_OF_BIRTH set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'SENSITIVE',
    column GENDER set tag ADMIN_DB.TAGS.PII_CATEGORY = 'NAME',
    column GENDER set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'SENSITIVE',
    column ETHNICITY set tag ADMIN_DB.TAGS.PII_CATEGORY = 'NAME',
    column ETHNICITY set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'SENSITIVE';

-- COMPENSATION_EVENTS_RAW: financial data
alter table {{db}}.RAW.COMPENSATION_EVENTS_RAW modify
    column SALARY_AMOUNT set tag ADMIN_DB.TAGS.PII_CATEGORY = 'FINANCIAL_PROFILE',
    column SALARY_AMOUNT set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'SENSITIVE',
    column BONUS_TARGET_PCT set tag ADMIN_DB.TAGS.PII_CATEGORY = 'FINANCIAL_PROFILE',
    column BONUS_TARGET_PCT set tag ADMIN_DB.TAGS.PII_CLASSIFICATION = 'SENSITIVE';
