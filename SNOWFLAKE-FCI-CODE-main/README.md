# SNOWFLAKE-FCI-CODE

All Snowflake domain code for the FCI organisation. Each business domain has its own DCM project under `domains/`. Functional roles and provisioning are managed here.

---

## Repo Structure

```
SNOWFLAKE-FCI-CODE/
├── setup/
│   └── provision_databases.sql       # Environments, domains, databases, warehouses, roles
├── functional_roles/                 # DCM project: grants for DEVELOPER, ANALYST, etc.
├── domains/
│   ├── general/dcm/                  # Cross-domain reference data
│   ├── hr/dcm/                       # Human Resources
│   └── brf/dcm/                      # Business & Retail Finance
├── scripts/
│   ├── start_dev.sh / .ps1           # Begin a task: create issue, branch, WIP clone
│   ├── complete_dev.sh / .ps1        # Submit to TEST: push, PR, merge, wait
│   ├── promote.sh / .ps1             # Promote: issue + target (uat/preprod/prod)
│   └── dcm-sqlfluff-lint.sh          # Custom pre-commit hook for DCM SQL
├── .github/workflows/
│   ├── create-wip-clone.yml          # Auto-creates WIP clone on feature branch push
│   ├── test.yml                      # PR merged to test/main → TEST clone in DEV
│   ├── uat.yml                       # PR merged to uat/main → UAT clone in PROD
│   ├── preprod.yml                   # PR merged to preprod/main → PREPROD clone in PROD
│   └── prod.yml                      # PR merged to prod/main → deploy PROD, sync DEV, cleanup
└── test/
    ├── seed_general.sql              # Test data for GENERAL domain
    ├── seed_hr.sql                   # Test data for HR domain
    ├── seed_brf.sql                  # Test data for BRF domain
    ├── general_definitions/          # Source definitions copied into domains/ by developers
    ├── hr_definitions/
    ├── brf_definitions/
    └── hr_update_01/pii_tags.sql     # PII column tagging script
```

---

## First-Time Setup

Prerequisites: the [snowflake-rbac-framework](https://github.com/sfc-gh-pfaulkner/snowflake-rbac-framework) must be deployed in both accounts first.

### 1. Provision environments, domains, databases, warehouses, and roles

```bash
snow sql -f setup/provision_databases.sql -c DEVACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH -D "env=DEV" --enable-templating JINJA
snow sql -f setup/provision_databases.sql -c PRODACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH -D "env=PROD" --enable-templating JINJA
```

### 2. Deploy functional roles (grants)

The DCM project is created automatically by the RBAC framework. Just deploy:
```bash
snow dcm deploy --from functional_roles --target DEV -c DEVACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH
snow dcm deploy --from functional_roles --target PROD -c PRODACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH
```

### 3. Grant DEVELOPER role to your user (skip if managed by Okta/SCIM)

In production, Okta/SCIM assigns users to roles automatically. For environments without SCIM, grant manually:

```bash
snow sql -c DEVACC --role ACCOUNTADMIN --warehouse COMPUTE_WH -q "grant role DEV_HR_DEVELOPER to user <YOUR_USER>;"
```

Setup is complete. Domain code is deployed through the development workflow below — never directly to base databases.

---

## Development Workflow

### Quick Start (scripted)

Helper scripts are provided for both bash (macOS/Linux) and PowerShell (Windows):

```bash
# 1. Start a new task (creates issue, branch, WIP clone)
./scripts/start_dev.sh

# 2. Do your work — edit DCM definitions, deploy to WIP, test
snow dcm deploy WIP_5_HR_CORE_DB.DCM.HR_CORE_PROJECT \
  --from domains/hr/dcm --target DEV \
  --variable "db='WIP_5_HR_CORE_DB'" \
  -c DEVACC --role DEV_HR_DEVELOPER --warehouse HR_DEV_WH

# 3. Submit for TEST (commits, pushes, creates/merges PR, waits for CI)
./scripts/complete_dev.sh 5

# 4. Promote through environments
./scripts/promote.sh 5 uat
./scripts/promote.sh 5 preprod
./scripts/promote.sh 5 prod
```

PowerShell equivalents:
```powershell
.\scripts\start_dev.ps1
.\scripts\complete_dev.ps1 5
.\scripts\promote.ps1 5 uat
.\scripts\promote.ps1 5 preprod
.\scripts\promote.ps1 5 prod
```

Note: `--variable` uses inner quotes (`db='VALUE'`), but `-D` does not (`db=VALUE`).

### What happens at each stage

| Step | Action | What CI does |
|------|--------|--------------|
| WIP | Push feature branch | Auto-creates WIP clone of DEV base database |
| TEST | Merge PR to `test/main` | Creates TEST clone, deploys DCM, seeds data (if empty) |
| UAT | PR from `test/main` to `uat/main`, merge | Creates UAT clone of PROD base database |
| PREPROD | PR from `uat/main` to `preprod/main`, merge | Creates PREPROD clone on PROD account |
| PROD | PR from `preprod/main` to `prod/main`, merge | Deploys to PROD, syncs to DEV, drops all clones, closes issue |

Each workflow uses change detection to determine which domain was modified in the PR, and only deploys that domain.

### Clean up

After production deployment, clones are dropped automatically and the GitHub issue is closed. Delete the feature branch:
```bash
git checkout main && git branch -D feature/5-deploy-hr
git push origin --delete feature/5-deploy-hr
```

---

## Post-Deploy Scripts

Any `.sql` files placed in `domains/<domain>/post_deploy/` are automatically executed by CI/CD after each DCM deployment (TEST, UAT, PREPROD, and PROD). This is useful for operations that DCM cannot handle declaratively, such as:

- **Column-level PII tagging** (`ALTER TABLE ... MODIFY COLUMN ... SET TAG`)
- Future grants or other DDL not supported by DCM `DEFINE`

Scripts run with Jinja templating enabled and receive `{{db}}` as the target database name. Scripts must be **idempotent** — they run on every deployment across all environments. During local WIP development, run them manually:

```bash
snow sql -f domains/hr/post_deploy/pii_tags.sql -c DEVACC --role DEV_HR_DEVELOPER --warehouse HR_DEV_WH -D "db=WIP_5_HR_CORE_DB" --enable-templating JINJA
```

---

## Adding a New Domain

1. Add domain registration and database/schema/warehouse calls to `setup/provision_databases.sql`
2. Re-run provisioning in both accounts
3. Create `domains/<name>/dcm/manifest.yml` following the existing pattern (must include `defaults` section with `db` for `--variable` override)
4. Add the domain to `functional_roles/manifest.yml` under `templating.defaults.domains` (include `reporting_wh` and `dev_wh`)
5. Redeploy functional_roles to both accounts:
   ```
   snow dcm deploy --from functional_roles --target DEV -c DEVACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH
   snow dcm deploy --from functional_roles --target PROD -c PRODACC --role DEPLOYMENT_ADMIN --warehouse ADMIN_WH
   ```
6. ~~Add the domain to the CI/CD workflow jobs~~ — not needed; all workflows use dynamic domain detection
7. Grant roles to users — DCM cannot do `GRANT ROLE ... TO USER`. Either:
   - Manually: `grant role <ENV>_<DOMAIN>_DEVELOPER to user <USERNAME>;`
   - Via SCIM/IdP: map identity provider groups to Snowflake roles

---

## Warehouses

Each domain has access to both **shared** warehouses (owned by GENERAL) and **dedicated** warehouses. The DCM manifest is the single switch point — developers never hardcode warehouse names.

### Template variables

| Variable | Purpose |
|----------|---------|
| `{{ingest_wh}}` | Ingestion tasks (COPY INTO, Snowpipe refresh) |
| `{{transform_wh}}` | Dynamic tables, transformation tasks |
| `{{reporting_wh}}` | Reporting views, BI-facing workloads |
| `{{dev_wh}}` | Developer ad-hoc use (DEV only) |

Example:
```sql
DEFINE DYNAMIC TABLE {{db}}.DM.D_EMPLOYEE_CURRENT
    WAREHOUSE = {{transform_wh}}
    TARGET_LAG = '1 hour'
AS
    select ...
```

### Switching between shared and dedicated

In the domain manifest (`domains/<name>/dcm/manifest.yml`):

```yaml
# Shared (all domains use GENERAL warehouses):
      ingest_wh: GENERAL_INGEST_WH

# Dedicated (domain has its own):
      ingest_wh: HR_INGEST_WH
```

Redeploy to apply: `snow dcm deploy --target DEV --project-dir domains/hr/dcm`

Both shared and dedicated warehouses are pre-provisioned. Unused ones auto-suspend and cost nothing.

---

## CI/CD

This repo contains **trigger workflows** that define *when* to deploy and *which domains*. The deployment logic lives in reusable templates in [snowflake-rbac-framework](https://github.com/sfc-gh-pfaulkner/snowflake-rbac-framework).

| This repo (trigger) | Calls (template) | When |
|---------------------|------------------|------|
| `test.yml` | `deploy-to-clone.yml` | PR merged to `test/main` — creates TEST clone in DEV |
| `uat.yml` | `deploy-to-clone.yml` | PR merged to `uat/main` — creates UAT clone in PROD |
| `preprod.yml` | `deploy-to-clone.yml` | PR merged to `preprod/main` — creates PREPROD clone in PROD |
| `prod.yml` | `deploy-to-prod.yml` | PR merged to `prod/main` — deploys to PROD, syncs to DEV, drops clones, closes issue |
| `create-wip-clone.yml` | *(inline)* | Feature branch pushed — auto-creates WIP clone in DEV |

Each workflow runs change detection first — only domains with modified files are deployed. Seed data (`test/seed_<domain>.sql`) is loaded into DEV clones only, and only if tables are empty.

A self-hosted GitHub Actions runner is required (org network policy blocks hosted runners). Start with: `~/actions-runner/run.sh`

To add a new domain to CI/CD, simply create a `domains/<name>/` folder. All workflows use dynamic domain detection — no workflow edits required.

---

## Branch Protection

Configure these rules in GitHub (Settings → Branches → Branch protection rules) to enforce the promotion workflow:

| Branch pattern | Required reviewers | Additional checks |
|---------------|-------------------|-------------------|
| `main` | 2 | Lint must pass |
| `preprod/*` | 1 | Lint must pass |
| `uat/*` | 1 | Lint must pass |
| `test/*` | 1 | Lint must pass |

This ensures:
- No one can push directly to protected branches — all changes go through PRs
- Production deployments require two sign-offs
- Linting and DCM plan checks must pass before merge is allowed

To configure via CLI:
```bash
gh api repos/sfc-gh-pfaulkner/SNOWFLAKE-FCI-CODE/branches/main/protection -X PUT -f 'required_pull_request_reviews[required_approving_review_count]=2' -f 'required_status_checks[strict]=true' -f 'required_status_checks[contexts][]=lint'
```

---

## Linting

Pre-commit hooks run SQLFluff (SQL keyword capitalisation) and yamllint on every commit. A custom wrapper (`scripts/dcm-sqlfluff-lint.sh`) handles DCM `DEFINE` syntax that SQLFluff cannot parse natively.

### Prerequisites

```bash
pip install pre-commit sqlfluff
pre-commit install
```

On **Windows**, `pre-commit` and `sqlfluff` install via pip the same way. However, the custom DCM lint wrapper is a bash script — it requires Git Bash or WSL. If neither is available, disable the hook (see below) and rely on CI to catch lint issues.

### Manual run

```bash
pre-commit run --all-files
```

### Disable / re-enable

```bash
# Disable (skip hooks on commit)
pre-commit uninstall

# Re-enable
pre-commit install
```

To skip hooks for a single commit without uninstalling:
```bash
git commit --no-verify -m "message"
```
