---
service: "vouchercloud-idl"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [config-files, env-vars, aws-secrets-manager]
---

# Configuration

## Overview

Vouchercloud IDL is configured through a combination of .NET XML config files (`Web.config` with environment-specific transforms), AWS Elastic Beanstalk `.ebextensions` scripts, and AWS Secrets Manager. Sensitive credentials (database connection strings, third-party API keys, GiftCloud credentials) are fetched from Secrets Manager at instance boot time and injected as machine-level Windows environment variables by a PowerShell init script. Non-sensitive settings (feature flags, Algolia index names, SNS topic ARNs, country configuration) are defined in `Web.config` and transformed per environment.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `IDL-Redis-MasterNode` | Redis master node hostname | yes | — | aws-secrets-manager (`Redis-{env}`) |
| `IDL-Redis-ReadableNodes` | Redis replica node hostnames | yes | — | aws-secrets-manager (`Redis-{env}`) |
| `IDL-Redis-ConnectTimeout` | Redis connection timeout | yes | — | aws-secrets-manager (`Redis-{env}`) |
| `IDL-VCAPI-SqlUserName` | Main SQL Server username | yes | — | aws-secrets-manager (`VCAPI-SQL-{env}`) |
| `IDL-VCAPI-SqlPassword` | Main SQL Server password | yes | — | aws-secrets-manager (`VCAPI-SQL-{env}`) |
| `IDL-VCAPI-SqlHost` | Main SQL Server host | yes | — | aws-secrets-manager (`VCAPI-SQL-{env}`) |
| `IDL-VCAPI-SqlPort` | Main SQL Server port | yes | — | aws-secrets-manager (`VCAPI-SQL-{env}`) |
| `IDL-VCAPI-SqlDbName` | Main SQL database name | yes | — | aws-secrets-manager (`VCAPI-SQL-{env}`) |
| `IDL-VCAPI-AffiliateSqlUserName` | Affiliate SQL Server username | yes | — | aws-secrets-manager (`VCAPI-SQLAffiliate-{env}`) |
| `IDL-VCAPI-AffiliateSqlPassword` | Affiliate SQL Server password | yes | — | aws-secrets-manager (`VCAPI-SQLAffiliate-{env}`) |
| `IDL-VCAPI-AffiliateSqlHost` | Affiliate SQL Server host | yes | — | aws-secrets-manager (`VCAPI-SQLAffiliate-{env}`) |
| `IDL-VCAPI-AffiliateSqlPort` | Affiliate SQL Server port | yes | — | aws-secrets-manager (`VCAPI-SQLAffiliate-{env}`) |
| `IDL-VCAPI-AffiliateSqlDbName` | Affiliate SQL database name | yes | — | aws-secrets-manager (`VCAPI-SQLAffiliate-{env}`) |
| `IDL-VCAPI-MongoConnectionString` | MongoDB connection string | yes | — | aws-secrets-manager (`VCAPI-Mongo-{env}`) |
| `IDL-VCAPI-GCAPI{country}User` | Giftcloud API username per country (GB, US, IE, FR, DE, IT, AU, ES, USgroupon) | yes | — | aws-secrets-manager (`GCAPI-{COUNTRY}-{env}`) |
| `IDL-VCAPI-GCAPI{country}Password` | Giftcloud API password per country | yes | — | aws-secrets-manager (`GCAPI-{COUNTRY}-{env}`) |
| `IDL-VCAPI-GCAPI{country}Key` | Giftcloud API key per country | yes | — | aws-secrets-manager (`GCAPI-{COUNTRY}-{env}`) |
| `IDL-Environment` | Environment name identifier | no | — | .ebextensions (staging only) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `FeatureFlags.VC5329` | Enables specific feature governed by ticket VC-5329 | `true` (in `Web.config`) | global |
| `analyticsUseSqsLambda` | Switches analytics delivery to SQS+Lambda mode | `true` | global |
| `analyticsUseFakeApiClient` | Bypasses real analytics API calls (staging only) | `true` (staging) | per-environment |
| `rewards.isTestMode` | Prevents actual Giftcloud reward claims (test environments) | `true` (staging) | per-environment |
| `rewards.validationEnabled` | Enables Giftcloud reward validation | `true` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `IDL.Api.Restful/Web.config` | XML | Base application configuration: NLog, appSettings, restfulApi section, eagleEyeAir section, country config |
| `IDL.Api.Restful/Web.Debug.config` | XML | Debug environment transform |
| `IDL.Api.Restful/Web.Staging.config` | XML | Staging environment transform |
| `IDL.Api.Restful/Web.Release.config` | XML | Production (UK) environment transform |
| `IDL.Api.Restful/Web.USRelease.config` | XML | Production (US) environment transform |
| `IDL.Api.Restful/Web.Feature.config` | XML | Feature branch environment transform |
| `IDL.Api.Restful/.ebextensions/release-set-environment-variables.config` | YAML | Production init script — fetches secrets from AWS Secrets Manager and sets env vars |
| `IDL.Api.Restful/.ebextensions/staging-set-environment-variables.config` | YAML | Staging init script — fetches secrets from AWS Secrets Manager and sets env vars |
| `IDL.Api.Restful/.ebextensions/enable-enhanced-health-reporting.config` | YAML | Enables AWS EB enhanced health reporting |
| `IDL.Api.Restful/.ebextensions/sprint-time-based-autoscaling-schedules.config` | YAML | Scheduled scale-down (weeknights/weekends) for sprint/dev environments |
| `.aws/Release/IDL.Api.Restful.opt` | JSON | AWS EB release environment options (instance type, VPC, ALB, auto-scaling, health check) |
| `.aws/Staging/IDL.Api.Restful.opt` | JSON | AWS EB staging environment options |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `Redis-Live` / `Redis-Staging` | Redis master/replica node hostnames and connect timeout | aws-secrets-manager |
| `VCAPI-SQL-Live` / `VCAPI-SQL-Staging` | Main SQL Server connection credentials | aws-secrets-manager |
| `VCAPI-SQLAffiliate-Live` / `VCAPI-SQLAffiliate-Staging` | Affiliate SQL Server connection credentials | aws-secrets-manager |
| `VCAPI-Mongo-Live` / `VCAPI-Mongo-Staging` | MongoDB connection string | aws-secrets-manager |
| `GCAPI-GB-Live` / `GCAPI-GB-Staging` | Giftcloud GB API credentials | aws-secrets-manager |
| `GCAPI-US-Live` / `GCAPI-US-Staging` | Giftcloud US API credentials | aws-secrets-manager |
| `GCAPI-IE-Live` / `GCAPI-IE-Staging` | Giftcloud IE API credentials | aws-secrets-manager |
| `GCAPI-FR-Live` / `GCAPI-FR-Staging` | Giftcloud FR API credentials | aws-secrets-manager |
| `GCAPI-DE-Live` / `GCAPI-DE-Staging` | Giftcloud DE API credentials | aws-secrets-manager |
| `GCAPI-IT-Live` / `GCAPI-IT-Staging` | Giftcloud IT API credentials | aws-secrets-manager |
| `GCAPI-AU-Live` / `GCAPI-AU-Staging` | Giftcloud AU API credentials | aws-secrets-manager |
| `GCAPI-ES-Live` | Giftcloud ES API credentials | aws-secrets-manager |
| `GCAPI-USgroupon-Live` / `GCAPI-USgroupon-Staging` | Giftcloud USgroupon API credentials | aws-secrets-manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Debug**: Local development — uses `https://api.gb.v3.idldev.net` as Host; fake analytics client; Algolia staging index names; test-mode rewards.
- **Staging**: Uses `https://staging-restfulapi.vouchercloud.com`; Algolia staging indexes (`OfferSearch_Staging`, `Merchants_Staging`); staging SNS topic ARNs; staging Secrets Manager secrets; rewards test mode enabled. Schedule-based autoscaling scales to 0 at 20:00 UTC weekdays.
- **Release (UK Production)**: Uses `https://restfulapi.vouchercloud.com`; production SNS ARNs; production Secrets Manager secrets; rewards test mode disabled; 4 fixed EC2 `t3.large` instances; autoscaling on Latency metric.
- **US Release**: Separate `Web.USRelease.config` and `.aws/US-West-1/Release/IDL.Api.Restful.opt` for US-West-1 region deployment.
- **Feature**: Feature branch environments with reduced capacity and dev-mode settings.
