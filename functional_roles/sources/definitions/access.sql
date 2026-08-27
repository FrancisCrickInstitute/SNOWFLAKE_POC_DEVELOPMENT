-- ============================================================================
-- Functional Roles DCM Project
-- Manages GRANTS only. Roles are created externally by SCIM.
-- This project assumes all roles already exist.
-- ============================================================================

{% for domain in domains %}
-- --------------------------------------------------------------------------
-- {{ env }}_{{ domain.name }} Functional Roles — Grants
-- --------------------------------------------------------------------------

-- Hierarchy: functional roles under domain SYSADMIN
GRANT ROLE {{ env }}_{{ domain.name }}_ANALYST TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT ROLE {{ env }}_{{ domain.name }}_MANAGER TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT ROLE {{ env }}_{{ domain.name }}_DATASTEWARD TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT ROLE {{ env }}_{{ domain.name }}_POWERBI TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
{% if env in ['DEV'] %}
GRANT ROLE {{ env }}_{{ domain.name }}_DEVELOPER TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
{% endif %}

-- Database USAGE (required for any database role grants to work)
GRANT USAGE ON DATABASE {{ env }}_{{ domain.name }}_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_ANALYST;
GRANT USAGE ON DATABASE {{ env }}_{{ domain.name }}_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT USAGE ON DATABASE {{ env }}_{{ domain.name }}_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_DATASTEWARD;
GRANT USAGE ON DATABASE {{ env }}_{{ domain.name }}_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_POWERBI;
{% if env in ['DEV'] %}
GRANT USAGE ON DATABASE {{ env }}_{{ domain.name }}_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% endif %}

-- POWERBI: DM + RPT schemas
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_POWERBI;
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.RPT_R TO ROLE {{ env }}_{{ domain.name }}_POWERBI;

-- ANALYST: DM + RPT schemas
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_ANALYST;
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.RPT_R TO ROLE {{ env }}_{{ domain.name }}_ANALYST;

-- MANAGER: DM + RPT + STG schemas
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.RPT_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.STG_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;

-- DATASTEWARD: All schemas (full read via DB_R)
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.DB_R TO ROLE {{ env }}_{{ domain.name }}_DATASTEWARD;

-- Clone management: SYSADMIN can create/drop clones (CI/CD uses this in both envs)
GRANT USAGE ON DATABASE ADMIN_DB TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT USAGE ON SCHEMA ADMIN_DB.DEPLOY TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY.DEPLOY_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY._PROVISION_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY.DROP_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY._DROP_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_SYSADMIN;

-- DEVELOPER: All schemas read-only (write access added dynamically to clones)
{% if env in ['DEV'] %}
GRANT DATABASE ROLE {{ env }}_{{ domain.name }}_CORE_DB.DB_R TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;

-- Clone management: developer can create/drop their own WIP and TEST clones
GRANT USAGE ON DATABASE ADMIN_DB TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON SCHEMA ADMIN_DB.DEPLOY TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY.DEPLOY_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY._PROVISION_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY.DROP_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON PROCEDURE ADMIN_DB.DEPLOY._DROP_CLONE(VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR) TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;

-- PII tag-apply: developer can tag columns in WIP clones (owner bypasses masking)
GRANT USAGE ON SCHEMA ADMIN_DB.TAGS TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT APPLY ON TAG ADMIN_DB.TAGS.PII_CATEGORY TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT APPLY ON TAG ADMIN_DB.TAGS.PII_CLASSIFICATION TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% endif %}

-- Warehouse USAGE for querying
GRANT USAGE ON WAREHOUSE {{ domain.reporting_wh }} TO ROLE {{ env }}_{{ domain.name }}_ANALYST;
GRANT USAGE ON WAREHOUSE {{ domain.reporting_wh }} TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT USAGE ON WAREHOUSE {{ domain.reporting_wh }} TO ROLE {{ env }}_{{ domain.name }}_DATASTEWARD;
GRANT USAGE ON WAREHOUSE {{ domain.reporting_wh }} TO ROLE {{ env }}_{{ domain.name }}_POWERBI;
{% if env in ['DEV'] %}
GRANT USAGE ON WAREHOUSE {{ domain.dev_wh }} TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% if domain.name != 'GENERAL' %}
GRANT USAGE ON WAREHOUSE GENERAL_INGEST_WH TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
GRANT USAGE ON WAREHOUSE GENERAL_TRANSFORM_WH TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% endif %}
{% endif %}
{% if domain.name != 'GENERAL' %}
GRANT USAGE ON WAREHOUSE GENERAL_INGEST_WH TO ROLE {{ env }}_{{ domain.name }}_ETL;
GRANT USAGE ON WAREHOUSE GENERAL_TRANSFORM_WH TO ROLE {{ env }}_{{ domain.name }}_ETL;
{% endif %}
GRANT USAGE ON WAREHOUSE {{ domain.reporting_wh }} TO ROLE {{ env }}_{{ domain.name }}_ETL;

{% endfor %}

-- ============================================================================
-- Cross-Domain: Grant GENERAL CORE DB access to all non-GENERAL domain roles
-- ============================================================================

{% for domain in domains %}
{% if domain.name != 'GENERAL' %}
-- {{ domain.name }} roles → GENERAL CORE DB
GRANT USAGE ON DATABASE {{ env }}_GENERAL_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_POWERBI;
GRANT USAGE ON DATABASE {{ env }}_GENERAL_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_ANALYST;
GRANT USAGE ON DATABASE {{ env }}_GENERAL_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT USAGE ON DATABASE {{ env }}_GENERAL_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_DATASTEWARD;
{% if env in ['DEV'] %}
GRANT USAGE ON DATABASE {{ env }}_GENERAL_CORE_DB TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% endif %}

GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_POWERBI;

GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_ANALYST;
GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.RPT_R TO ROLE {{ env }}_{{ domain.name }}_ANALYST;

GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.DM_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.RPT_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;
GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.STG_R TO ROLE {{ env }}_{{ domain.name }}_MANAGER;

GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.DB_R TO ROLE {{ env }}_{{ domain.name }}_DATASTEWARD;

{% if env in ['DEV'] %}
GRANT DATABASE ROLE {{ env }}_GENERAL_CORE_DB.DB_R TO ROLE {{ env }}_{{ domain.name }}_DEVELOPER;
{% endif %}

-- PII access roles: control who can see unmasked personal data
-- These are granted directly to USERS (via Okta/SCIM), never to other roles.
DEFINE ROLE PII_{{ domain.name }}_FULL_ACCESS;
DEFINE ROLE PII_{{ domain.name }}_PARTIAL_ACCESS;

{% endif %}
{% endfor %}

-- ============================================================================
-- Service Users: Power BI
-- NOTE: GRANT ... TO USER is not supported by DCM.
-- Service user grants are applied by post_deployment_grants.sql
-- ============================================================================
