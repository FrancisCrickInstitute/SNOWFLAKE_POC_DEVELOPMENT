-- =============================================================================
-- FCI Domain Provisioning Script
-- =============================================================================
-- Creates all domain databases, schemas, and warehouses for the FCI organisation.
-- Run once per account after the RBAC framework has been deployed.
--
-- Parameters:
--   env  - Environment prefix: DEV or PROD
--
-- Usage:
--   snow sql -f setup/provision_databases.sql -c DEVACC -D "env=DEV" --enable-templating JINJA
--   snow sql -f setup/provision_databases.sql -c PRODACC -D "env=PROD" --enable-templating JINJA
-- =============================================================================

use role DEPLOYMENT_ADMIN;
use warehouse ADMIN_WH;

set env = '{{env}}';

-- Fail early if env is not DEV or PROD
select case when $env not in ('DEV', 'PROD')
    then 1/0  -- raises: Division by zero
    else 1
end as ENV_CHECK;

-- ─────────────────────────────────────────────────────────────────────────────
-- Register environment and domains (idempotent)
-- ─────────────────────────────────────────────────────────────────────────────
call ADMIN_DB.DEPLOY.DEPLOY_ENVIRONMENT($env, $env || ' environment');
call ADMIN_DB.DEPLOY.DEPLOY_DOMAIN('GENERAL', 'Cross-domain reference data and shared warehouses');
call ADMIN_DB.DEPLOY.DEPLOY_DOMAIN('HR', 'Human Resources');
call ADMIN_DB.DEPLOY.DEPLOY_DOMAIN('BRF', 'Business & Retail Finance');

-- ─────────────────────────────────────────────────────────────────────────────
-- GENERAL domain — cross-domain reference data and shared warehouses
-- ─────────────────────────────────────────────────────────────────────────────
call ADMIN_DB.DEPLOY.DEPLOY_DATABASE($env, 'GENERAL', 'CORE');

set general_db = $env || '_GENERAL_CORE_DB';
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($general_db, 'RAW');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($general_db, 'STG');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($general_db, 'INT');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($general_db, 'DM');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($general_db, 'RPT');

-- Shared warehouses (owned by GENERAL, available to all domains)
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'GENERAL', 'INGEST', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'GENERAL', 'TRANSFORM', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'GENERAL', 'REPORTING', 'GEN1', 'XSMALL');

-- ─────────────────────────────────────────────────────────────────────────────
-- HR domain — Human Resources
-- ─────────────────────────────────────────────────────────────────────────────
call ADMIN_DB.DEPLOY.DEPLOY_DATABASE($env, 'HR', 'CORE');

set hr_db = $env || '_HR_CORE_DB';
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($hr_db, 'RAW');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($hr_db, 'STG');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($hr_db, 'INT');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($hr_db, 'DM');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($hr_db, 'RPT');

-- Dedicated warehouses (may or may not be in use — manifest decides)
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'HR', 'INGEST', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'HR', 'TRANSFORM', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'HR', 'REPORTING', 'GEN1', 'XSMALL');

-- ─────────────────────────────────────────────────────────────────────────────
-- BRF domain — Business & Retail Finance
-- ─────────────────────────────────────────────────────────────────────────────
call ADMIN_DB.DEPLOY.DEPLOY_DATABASE($env, 'BRF', 'CORE');

set brf_db = $env || '_BRF_CORE_DB';
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($brf_db, 'RAW');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($brf_db, 'STG');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($brf_db, 'INT');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($brf_db, 'DM');
call ADMIN_DB.DEPLOY.DEPLOY_SCHEMA($brf_db, 'RPT');

-- Dedicated warehouses (may or may not be in use — manifest decides)
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'BRF', 'INGEST', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'BRF', 'TRANSFORM', 'GEN1', 'XSMALL');
call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE($env, 'BRF', 'REPORTING', 'GEN1', 'XSMALL');

-- ─────────────────────────────────────────────────────────────────────────────
-- Cross-domain grants: give HR and BRF access to GENERAL (shared) warehouses
-- ─────────────────────────────────────────────────────────────────────────────
set hr_reader = $env || '_HR_READER';
set brf_reader = $env || '_BRF_READER';

grant usage on warehouse GENERAL_INGEST_WH to role identifier($hr_reader);
grant usage on warehouse GENERAL_INGEST_WH to role identifier($brf_reader);
grant usage on warehouse GENERAL_TRANSFORM_WH to role identifier($hr_reader);
grant usage on warehouse GENERAL_TRANSFORM_WH to role identifier($brf_reader);
grant usage on warehouse GENERAL_REPORTING_WH to role identifier($hr_reader);
grant usage on warehouse GENERAL_REPORTING_WH to role identifier($brf_reader);

-- ─────────────────────────────────────────────────────────────────────────────
-- DEPLOYMENT_ADMIN needs USAGE on all warehouses for DCM dependency resolution
-- ─────────────────────────────────────────────────────────────────────────────
grant usage on warehouse GENERAL_INGEST_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse GENERAL_TRANSFORM_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse GENERAL_REPORTING_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse HR_INGEST_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse HR_TRANSFORM_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse HR_REPORTING_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse BRF_INGEST_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse BRF_TRANSFORM_WH to role DEPLOYMENT_ADMIN;
grant usage on warehouse BRF_REPORTING_WH to role DEPLOYMENT_ADMIN;

-- ─────────────────────────────────────────────────────────────────────────────
-- DEV-only: developer warehouses and grants (not needed in PROD)
-- ─────────────────────────────────────────────────────────────────────────────
execute immediate $$
begin
    if ((select $env) = 'DEV') then
        call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE('DEV', 'GENERAL', 'DEV', 'GEN1', 'XSMALL');
        call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE('DEV', 'HR', 'DEV', 'GEN1', 'XSMALL');
        call ADMIN_DB.DEPLOY.DEPLOY_WAREHOUSE('DEV', 'BRF', 'DEV', 'GEN1', 'XSMALL');
        grant usage on warehouse GENERAL_DEV_WH to role DEPLOYMENT_ADMIN;
        grant usage on warehouse HR_DEV_WH to role DEPLOYMENT_ADMIN;
        grant usage on warehouse BRF_DEV_WH to role DEPLOYMENT_ADMIN;
        grant usage on warehouse GENERAL_DEV_WH to role DEV_GENERAL_DEVELOPER;
        grant operate on warehouse GENERAL_DEV_WH to role DEV_GENERAL_DEVELOPER;
        grant usage on warehouse HR_DEV_WH to role DEV_HR_DEVELOPER;
        grant operate on warehouse HR_DEV_WH to role DEV_HR_DEVELOPER;
        grant usage on warehouse BRF_DEV_WH to role DEV_BRF_DEVELOPER;
        grant operate on warehouse BRF_DEV_WH to role DEV_BRF_DEVELOPER;
    end if;
end;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- PII tag-apply grants: domain SYSADMIN roles need APPLY on specific tags
-- to run post-deploy scripts that SET TAG on columns.
-- Grantable by DEPLOYMENT_ADMIN (tag owner) — no ACCOUNTADMIN needed.
-- ─────────────────────────────────────────────────────────────────────────────
set general_sysadmin = $env || '_GENERAL_SYSADMIN';
set hr_sysadmin = $env || '_HR_SYSADMIN';
set brf_sysadmin = $env || '_BRF_SYSADMIN';

grant usage on database ADMIN_DB to role identifier($general_sysadmin);
grant usage on schema ADMIN_DB.TAGS to role identifier($general_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CATEGORY to role identifier($general_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CLASSIFICATION to role identifier($general_sysadmin);

grant usage on database ADMIN_DB to role identifier($hr_sysadmin);
grant usage on schema ADMIN_DB.TAGS to role identifier($hr_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CATEGORY to role identifier($hr_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CLASSIFICATION to role identifier($hr_sysadmin);

grant usage on database ADMIN_DB to role identifier($brf_sysadmin);
grant usage on schema ADMIN_DB.TAGS to role identifier($brf_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CATEGORY to role identifier($brf_sysadmin);
grant apply on tag ADMIN_DB.TAGS.PII_CLASSIFICATION to role identifier($brf_sysadmin);

-- ─────────────────────────────────────────────────────────────────────────────
select 'Provisioning complete for environment: ' || $env as STATUS;
