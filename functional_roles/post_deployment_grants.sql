-- ============================================================================
-- Post-deployment grants: ownership transfers to domain RBAC roles
-- Run manually after DCM deploy (GRANT OWNERSHIP not supported by DCM)
--
-- Dynamic: iterates all registered environments and domains automatically.
-- ============================================================================

execute immediate $$
declare
    env_name varchar;
    domain_name varchar;
    rbac_role varchar;
    func_role varchar;
    grant_sql varchar;
    func_roles array := array_construct('ANALYST', 'MANAGER', 'DATASTEWARD', 'POWERBI', 'DEVELOPER');
    c1 cursor for
        select E.ENVIRONMENT, D.DOMAIN
        from ADMIN_DB.DEPLOY.ENVIRONMENTS E
        cross join ADMIN_DB.DEPLOY.DOMAINS D;
begin
    open c1;
    for rec in c1 do
        env_name := rec.ENVIRONMENT;
        domain_name := rec.DOMAIN;
        rbac_role := env_name || '_' || domain_name || '_RBAC';

        for i in 0 to array_size(:func_roles) - 1 do
            func_role := env_name || '_' || domain_name || '_' || func_roles[i]::varchar;
            grant_sql := 'grant ownership on role IDENTIFIER(''' || func_role || ''') to role IDENTIFIER(''' || rbac_role || ''') copy current grants';
            begin
                execute immediate :grant_sql;
            exception
                when other then null; -- Role may not exist (e.g. DEVELOPER in PROD)
            end;
        end for;

        -- Grant Power BI service user the domain POWERBI role and warehouse
        if (domain_name != 'GENERAL') then
            let svc_user varchar := 'SVC_POWERBI_' || domain_name || '_' || env_name;
            let pbi_role varchar := env_name || '_' || domain_name || '_POWERBI';
            let rpt_wh varchar := domain_name || '_REPORTING_WH';
            begin
                execute immediate 'grant role ' || pbi_role || ' to user ' || svc_user;
                execute immediate 'grant usage on warehouse ' || rpt_wh || ' to user ' || svc_user;
            exception
                when other then null; -- User may not exist
            end;
        end if;
    end for;
    return 'Post-deployment grants complete';
end;
$$;
