---
service: "ARQWeb"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars"]
---

# Configuration

## Overview

ARQWeb is configured through environment variables injected at deployment time. Both the web application (`continuumArqWebApp`) and the ARQ Worker (`continuumArqWorker`) share configuration through this mechanism. Configuration covers database connectivity, external system credentials (LDAP, GitHub, Jira, Workday, Service Portal, Cyclops, APM), SMTP relay settings, and operational parameters. No config files or external config stores (Consul, Vault) were identified in the architecture model — all configuration evidence is derived from the set of external integrations documented in the architecture DSL.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `DATABASE_URL` | PostgreSQL connection string for `continuumArqPostgres` | yes | none | env |
| `LDAP_HOST` | Hostname of the Active Directory LDAP/LDAPS server | yes | none | env |
| `LDAP_PORT` | Port for LDAP/LDAPS connection (389 or 636) | yes | 636 | env |
| `LDAP_BIND_DN` | Service account distinguished name for LDAP bind | yes | none | env |
| `LDAP_BIND_PASSWORD` | Password for LDAP bind service account | yes | none | env |
| `SERVICE_PORTAL_URL` | Base URL for the internal Service Portal API | yes | none | env |
| `SERVICE_PORTAL_TOKEN` | API token for Service Portal authentication | yes | none | env |
| `WORKDAY_API_URL` | Base URL for the Workday API endpoint | yes | none | env |
| `WORKDAY_CLIENT_ID` | OAuth2 client ID for Workday authentication | yes | none | env |
| `WORKDAY_CLIENT_SECRET` | OAuth2 client secret for Workday authentication | yes | none | env |
| `GITHUB_ENTERPRISE_URL` | Base URL for the GitHub Enterprise API | yes | none | env |
| `GITHUB_TOKEN` | Personal access token or GitHub App credentials for GHE | yes | none | env |
| `JIRA_URL` | Base URL for the Jira REST API | yes | none | env |
| `JIRA_USER` | Service account username for Jira authentication | yes | none | env |
| `JIRA_TOKEN` | API token for Jira service account | yes | none | env |
| `SMTP_HOST` | Hostname of the internal SMTP relay | yes | none | env |
| `SMTP_PORT` | Port for SMTP connection | yes | 25 | env |
| `SMTP_USER` | SMTP AUTH username (if required) | no | none | env |
| `SMTP_PASSWORD` | SMTP AUTH password (if required) | no | none | env |
| `CYCLOPS_URL` | Base URL for the internal Cyclops API | yes | none | env |
| `CYCLOPS_TOKEN` | Auth token for Cyclops service-to-service calls | yes | none | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint for telemetry | no | none | env |
| `ELASTIC_APM_SECRET_TOKEN` | Secret token for Elastic APM agent authentication | no | none | env |
| `ELASTIC_APM_SERVICE_NAME` | Service name tag sent to Elastic APM | no | `arqweb` | env |
| `SECRET_KEY` | Flask application secret key for session signing | yes | none | env |
| `FLASK_ENV` | Flask run environment (`production`, `development`) | yes | `production` | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed above.

> Variable names are inferred from the external integration patterns described in the architecture DSL. Actual variable names should be confirmed from the application source or deployment manifests.

## Feature Flags

> No evidence found in codebase. No feature flag system was identified in the architecture model.

## Config Files

> No evidence found in codebase. No config file paths (YAML, TOML, INI) were identified in the architecture model.

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `LDAP_BIND_PASSWORD` | LDAP service account password for Active Directory bind | env |
| `WORKDAY_CLIENT_SECRET` | OAuth2 client secret for Workday API | env |
| `GITHUB_TOKEN` | GitHub Enterprise access token | env |
| `JIRA_TOKEN` | Jira API token | env |
| `CYCLOPS_TOKEN` | Cyclops service-to-service auth token | env |
| `ELASTIC_APM_SECRET_TOKEN` | Elastic APM ingestion secret | env |
| `SECRET_KEY` | Flask session signing key | env |

> Secret values are NEVER documented. Only names and rotation policies are listed. Rotation policies are not discoverable from the architecture model.

## Per-Environment Overrides

> No evidence found in codebase. Environment-specific configuration differences (dev, staging, production) are not described in the architecture model. Standard practice for Flask/Python services is to use separate environment variable sets per deployment environment.
