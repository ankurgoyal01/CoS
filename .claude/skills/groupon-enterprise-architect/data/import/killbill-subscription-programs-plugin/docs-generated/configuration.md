---
service: "killbill-subscription-programs-plugin"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [killbill-properties-file, killbill-tenant-config-upload, env-vars, helm-values]
---

# Configuration

## Overview

The plugin is configured at two levels: global (Kill Bill server properties file, applied to all tenants) and per-tenant (YAML uploaded via the Kill Bill tenant config API at `POST /1.0/kb/tenants/uploadPluginConfig/sp-plugin`). Per-tenant YAML is the primary mechanism for specifying MBus credentials, Orders and GAPI URLs, and plugin behavior flags. Cloud deployments additionally pass environment variables via Kubernetes deployment config (Helm/Conveyor).

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `CONFIG_FILE` | Path to the cloud environment config YAML file | yes (cloud) | None | Kubernetes deployment config |
| `PROPERTIES_TMPL` | Name of the Kill Bill properties template file for the environment | yes (cloud) | None | Kubernetes deployment config |
| `CLOUD_ENV` | Identifies the deployment environment (`production`, `staging`) | yes (cloud) | None | Kubernetes deployment config |
| `MALLOC_ARENA_MAX` | JVM native memory arena tuning for the JVM process | no | `4` | `common.yml` Kubernetes config |
| `KILLBILL_DAO_URL` | JDBC URL for the Kill Bill database (used in Docker/local dev) | yes (local dev) | None | `docker-compose.yml` |
| `KILLBILL_DAO_USER` | Kill Bill DB username | yes (local dev) | None | `docker-compose.yml` |
| `KILLBILL_DAO_PASSWORD` | Kill Bill DB password | yes (local dev) | None | `docker-compose.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `isListenerEnabled` | Enables the Kill Bill event listener for a tenant (controls whether INVOICE_CREATION events trigger order creation) | `true` | per-tenant |
| `supportLegacyBridgeMode` | Enables support for accounts using the legacy Kill Bill bridge payment method | `false` | per-tenant |
| `skipFirstInvoice` | Skips order creation for the first invoice of a subscription (used in migration scenarios) | `false` | per-tenant |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/ddl.sql` | SQL | Plugin database schema (sp_token, sp_notifications, sp_notifications_history tables) |
| `src/main/resources/com/groupon/killbill/killbill.sh` | Shell | Kill Bill server startup script |
| `src/main/resources/com/groupon/killbill/kpm.yml` | YAML | Kill Bill Package Manager plugin installation config |
| `src/main/resources/com/groupon/killbill/shiro.ini` | INI | Kill Bill Shiro security (admin auth) config |
| `src/main/resources/logback.xml` | XML | Logback logging configuration (steno format for Splunk) |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment config (scaling, probes, resources) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP Kubernetes deployment overrides |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP Kubernetes deployment overrides |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Kill Bill admin credentials | Basic auth for Kill Bill admin APIs (`kbCredentials` in tenant config) | k8s-secret / secrets submodule |
| GAPI `clientId` | Client identifier for Lazlo GAPI calls | k8s-secret / secrets submodule |
| GAPI `authToken` | Test-only token for integration test overrides (not used in production) | k8s-secret / secrets submodule |
| MBus `userName` / `password` | Per-tenant MBus broker credentials | k8s-secret / secrets submodule |

> Secret values are NEVER documented. Only names and rotation policies. The secrets repository is `killbill-subscription-programs-plugin-secrets` (git submodule under `.meta/deployment/cloud/secrets/`).

## Per-Environment Overrides

**Global Kill Bill properties** (applied to all tenants via the Kill Bill server properties file):

| Property | Purpose | Example |
|----------|---------|---------|
| `org.killbill.notificationq.sp.tableName` | Plugin notification queue table name | `sp_notifications` |
| `org.killbill.notificationq.sp.historyTableName` | Plugin notification queue history table name | `sp_notifications_history` |
| `org.killbill.server.region` | Server region identifier (e.g., `snc1`, `sac1`) used to select per-region config | `snc1` |
| `com.groupon.volume2.sp.plugin.token.expirationTimeMillisSec` | Auth token expiration in milliseconds | `120000` |
| `com.groupon.volume2.sp.plugin.mbus.nbThreadsPerTenant` | Number of MBus listener threads per tenant | `3` |
| `com.groupon.volume2.sp.plugin.mbus.tenantIds` | CSV of tenant UUIDs that should receive MBus events | `<TENANT UUID>` |

**Per-tenant YAML config** (uploaded via `POST /1.0/kb/tenants/uploadPluginConfig/sp-plugin`):

The YAML has four top-level sections:
- `sp`: Plugin behavior flags (`isListenerEnabled`, `supportLegacyBridgeMode`, `skipFirstInvoice`, `kbCredentials`, `defaultInventoryMapping`)
- `message-bus`: MBus credentials and per-region host/port (`userName`, `password`, `mbusWorkers`, `region.<regionId>.destinationHost`, `region.<regionId>.destinationPort`)
- `orders`: Per-region Orders service URL (`region.<regionId>.url`)
- `gapi`: GAPI client ID and per-region URL (`clientId`, `region.<regionId>.url`)

**Cloud environment difference**:
- Production: namespace `subscription-engine-production-sox`, GCP VPC `prod`, `CONFIG_FILE=/var/groupon/config/cloud/production-us-central1.yml`, replicas 2–8
- Staging: namespace `subscription-engine-staging-sox`, GCP VPC `stable`, `CONFIG_FILE=/var/groupon/config/cloud/staging-us-central1.yml`, replicas 1–4
