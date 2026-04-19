---
service: "goods-inventory-service-routing"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

The service is configured via YAML config files selected by the `JTIER_RUN_CONFIG` environment variable. The active config file is mounted into the container at deploy time by the JTier/Raptor platform. Sensitive credentials (database username and password) are injected via environment variables sourced from DaaS secrets. The `gisRegions` block in the config file is the primary business-logic configuration — it defines which shipping-region country codes map to which regional GIS endpoint.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Absolute path to the active YAML config file to load at startup | Yes | None (set by Raptor deployment manifest) | env (Raptor/Kubernetes) |
| `DAAS_APP_USERNAME` | PostgreSQL application user for the routing DB | Yes | None | DaaS secrets (Vault-backed) |
| `DAAS_APP_PASSWORD` | PostgreSQL application password for the routing DB | Yes | None | DaaS secrets (Vault-backed) |

> Secret values are NEVER documented. Only names and rotation policies.

## Feature Flags

> No evidence found in codebase. No feature-flag system (LaunchDarkly, Flagr, etc.) is used.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (localhost DB, debug logging, port 9000) |
| `src/main/resources/config/cloud/staging-us-central1.yml` | YAML | Staging environment configuration (GCP `stable` VPC, us-central1) |
| `src/main/resources/config/cloud/production-us-central1.yml` | YAML | Production environment configuration (GCP `prod` VPC, us-central1) |
| `src/main/resources/metrics.yml` | YAML | Metrics destination (Telegraf/Codahale, flush frequency 10 s) |
| `src/main/resources/service/run-config` | text | JTier run config pointer used by the service wrapper |

### Key configuration properties

| Property | Description | Dev value | Prod value |
|----------|-------------|-----------|------------|
| `server.maxThreads` | Maximum Dropwizard server thread pool size | 50 | 500 |
| `server.minThreads` | Minimum Dropwizard server thread pool size | 8 | 500 |
| `server.applicationConnectors[0].port` | HTTP application port | 9000 | 8080 (via Raptor) |
| `server.adminConnectors[0].port` | Dropwizard admin port | 9001 | 8081 (via Raptor) |
| `logging.level` | Root log level | DEBUG | INFO |
| `postgres.host` | PostgreSQL host | `localhost` | `goods-inventory-service-routing-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| `postgres.database` | Database name | `test_dev` | `goods_inv_serv_routing_prod` |
| `gisRegions[].name` | Logical name of the GIS region | NA, EMEA | NA, EMEA |
| `gisRegions[].gisUrl` | Hostname of the regional GIS endpoint | `goods-inventory-service.staging.service` | `goods-inventory-service.production.service` |
| `gisRegions[].hybridBoundaryRegion` | GCP region injected as `X-HB-Region` header | `us-central1` / `europe-west1` | `us-central1` / `eu-west-1` |
| `gisRegions[].shippingRegions` | Country codes owned by this region | US, CA / GB, IT, FR, DE, ES, IE, BE, NL | US, CA / GB, IT, FR, DE, ES, IE, BE, NL |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `DAAS_APP_USERNAME` | PostgreSQL application username for `goods_inv_serv_routing_prod` / `gis_routing_stg` | DaaS (Vault-backed, path in `.meta/deployment/cloud/secrets`) |
| `DAAS_APP_PASSWORD` | PostgreSQL application password | DaaS (Vault-backed) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production |
|---------|-------------|---------|------------|
| DB host | `localhost` | `goods-inventory-service-routing-rw-na-staging-db.gds.stable.gcp.groupondev.com` | `goods-inventory-service-routing-rw-na-production-db.gds.prod.gcp.groupondev.com` |
| DB name | `test_dev` | `gis_routing_stg` | `goods_inv_serv_routing_prod` |
| Log level | DEBUG | INFO | INFO |
| Min/Max threads | 8/50 | 500/500 | 500/500 |
| GIS URL | `goods-inventory-service.staging.service` | `goods-inventory-service.staging.service` | `goods-inventory-service.production.service` |
| EMEA hybrid boundary | `europe-west1` | `europe-west1` | `eu-west-1` |
| Kubernetes min replicas | N/A | 1 | 3 |
| Kubernetes max replicas | N/A | 15 | 15 |
