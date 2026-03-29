# Snowflake DCM Project — Salesforce Data Platform

A production-ready **Snowflake DCM (Database Change Management) Project** that deploys a multi-environment Salesforce data platform with role-based access control and CI/CD via GitHub Actions.

## What This Does

- Deploys **DEV** and **PROD** environments from a single set of SQL definition files
- Creates **3 schemas** (RAW, TRANSFORM, REPORTING) with **6 tables** per environment
- Sets up a complete **RBAC hierarchy**: 6 access roles + 3 functional roles per environment
- Automates **PLAN on PR** and **DEPLOY on merge** via GitHub Actions
- Uses a **service user** with key-pair authentication for CI/CD

## Project Structure

```
.
├── .github/workflows/
│   ├── dcm_plan_on_pr.yml            # Runs PLAN on every PR, posts output as comment
│   └── dcm_deploy_on_merge.yml       # Deploys DEV (auto) → PROD (manual approval)
├── manifest.yml                       # DCM config: targets, variables, environments
├── sources/definitions/
│   ├── sf_infrastructure.sql          # Schemas & tables
│   ├── sf_roles.sql                   # Functional & access roles
│   └── sf_grants.sql                  # Role hierarchy & privilege grants
├── gitignore.txt                      # Files excluded from Git
└── README.md
```

## Architecture

### Environments

| Config | Database | Role Prefix | Deployed By |
|--------|----------|-------------|-------------|
| `dev` | `DEV_SF_DB` | `*_DEV_SF_*` | Automatic on merge |
| `prod` | `PROD_SF_DB` | `*_PROD_SF_*` | Manual approval required |

### Schemas & Tables

| Schema | Tables |
|--------|--------|
| **RAW** | `SF_ACCOUNTS`, `SF_OPPORTUNITIES`, `SF_CONTACTS`, `SF_LEADS` |
| **TRANSFORM** | `SF_ACCOUNTS_CLEAN`, `SF_OPPORTUNITIES_CLEAN` |
| **REPORTING** | `RPT_PIPELINE_SUMMARY`, `RPT_ACCOUNT_OVERVIEW` |

### Role Hierarchy

```
                    DCM_ADMIN
               ┌────────┼────────┐
               ▼        ▼        ▼
          FR_*_SF_  FR_*_SF_  FR_*_SF_
          INGEST    TRANSFORM REPORTING
```

| Functional Role | RAW | TRANSFORM | REPORTING |
|---|---|---|---|
| `FR_*_SF_INGEST` | **WRITE** | READ | — |
| `FR_*_SF_TRANSFORM` | READ | **WRITE** | — |
| `FR_*_SF_REPORTING` | — | READ | **WRITE** |

## Prerequisites

1. Snowflake account with ACCOUNTADMIN access (for initial setup only)
2. GitHub repo with Actions enabled
3. RSA key pair for service user authentication

## Setup

### 1. Create the DCM_ADMIN role

```sql
USE ROLE ACCOUNTADMIN;

CREATE ROLE IF NOT EXISTS DCM_ADMIN
    COMMENT = 'Dedicated role for DCM project management';

GRANT CREATE DATABASE  ON ACCOUNT TO ROLE DCM_ADMIN;
GRANT CREATE WAREHOUSE ON ACCOUNT TO ROLE DCM_ADMIN;
GRANT CREATE ROLE      ON ACCOUNT TO ROLE DCM_ADMIN;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE DCM_ADMIN;
GRANT ROLE DCM_ADMIN TO USER <your_username>;
GRANT ROLE DCM_ADMIN TO ROLE SYSADMIN;
```

### 2. Create databases and DCM project objects

```sql
USE ROLE DCM_ADMIN;

CREATE DATABASE IF NOT EXISTS DEV_SF_DB;
CREATE DATABASE IF NOT EXISTS PROD_SF_DB;

CREATE DCM PROJECT IF NOT EXISTS DEV_SF_DB.PUBLIC.SALESFORCE_DCM_DEV;
CREATE DCM PROJECT IF NOT EXISTS PROD_SF_DB.PUBLIC.SALESFORCE_DCM_PROD;
```

### 3. Create service user for CI/CD

```sql
USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS SVC_DCM_CICD
    TYPE = SERVICE
    DEFAULT_ROLE = DCM_ADMIN
    DEFAULT_WAREHOUSE = COMPUTE_WH;

GRANT ROLE DCM_ADMIN TO USER SVC_DCM_CICD;
ALTER USER SVC_DCM_CICD SET RSA_PUBLIC_KEY = '<your_public_key>';
```

### 4. Set up Git integration

```sql
CREATE OR REPLACE SECRET INTEGRATIONS.GITHUB.GH_PAT
  TYPE = PASSWORD
  USERNAME = '<your_github_username>'
  PASSWORD = '<your_github_pat>';

CREATE OR REPLACE API INTEGRATION GITHUB_API_INTEGRATION
  API_PROVIDER = GIT_HTTPS_API
  API_ALLOWED_PREFIXES = ('https://github.com/<your_org>/')
  ALLOWED_AUTHENTICATION_SECRETS = (INTEGRATIONS.GITHUB.GH_PAT)
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY INTEGRATIONS.GITHUB.SALESFORCE_DCM_REPO
  API_INTEGRATION = GITHUB_API_INTEGRATION
  GIT_CREDENTIALS = INTEGRATIONS.GITHUB.GH_PAT
  ORIGIN = 'https://github.com/<your_org>/<your_repo>.git';
```

### 5. GitHub Secrets

Add these in repo **Settings → Secrets → Actions**:

| Secret | Value |
|--------|-------|
| `SNOWFLAKE_ACCOUNT` | `<your_org>-<your_account>` (org-account format) |
| `SNOWFLAKE_USER` | `SVC_DCM_CICD` |
| `SNOWFLAKE_PRIVATE_KEY` | Contents of your `.p8` private key file |

### 6. GitHub Environment

Create a `production` environment with **required reviewers** under repo **Settings → Environments**.

## Usage

### Manual PLAN & DEPLOY

```sql
-- Plan (dry run)
EXECUTE DCM PROJECT DEV_SF_DB.PUBLIC.SALESFORCE_DCM_DEV
  PLAN USING CONFIGURATION dev
FROM @INTEGRATIONS.GITHUB.SALESFORCE_DCM_REPO/branches/main/;

-- Deploy
EXECUTE DCM PROJECT DEV_SF_DB.PUBLIC.SALESFORCE_DCM_DEV
  DEPLOY AS "my deployment" USING CONFIGURATION dev
FROM @INTEGRATIONS.GITHUB.SALESFORCE_DCM_REPO/branches/main/;
```

### CI/CD (Automated)

1. Create a feature branch
2. Make changes to files in `sources/` or `manifest.yml`
3. Push and open a PR → **PLAN runs automatically**, output posted as PR comment
4. Merge to main → **DEV deploys automatically**, PROD waits for approval

### Useful Commands

```sql
SHOW ENTITIES IN DCM PROJECT DEV_SF_DB.PUBLIC.SALESFORCE_DCM_DEV;
SHOW DEPLOYMENTS IN DCM PROJECT DEV_SF_DB.PUBLIC.SALESFORCE_DCM_DEV;
SHOW DCM PROJECTS IN SCHEMA DEV_SF_DB.PUBLIC;
```

## Key Gotchas

- DCM **cannot manage its own parent database** — create it in setup, not in definitions
- Private key must be **PKCS#8 format** (`BEGIN PRIVATE KEY`, not `BEGIN RSA PRIVATE KEY`)
- GitHub Secrets account format is **org-account** (e.g. `MYORG-MYACCOUNT`), not the locator
- Workflow files must exist on **`main`** branch for triggers to fire
- The `project_owner` role must **own all managed objects**
