---
service: "raas"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 5
internal_count: 2
---

# Integrations

## Overview

RaaS integrates with five external systems: Redislabs Control Plane API (cluster telemetry and database management), AWS ElastiCache API (endpoint discovery and SNS subscription checks), Kubernetes API (config map and deployment management), Terraform definitions URL (resque namespace metadata), and GitHub Secrets (API credential bootstrapping). Internally, most containers communicate with the shared `loggingStack` and `metricsStack`.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Redislabs Control Plane API | REST/HTTPS | Fetch cluster/DB telemetry; create and manage Redis databases | yes | `continuumRaasRedislabsApi` |
| AWS ElastiCache API | AWS SDK | Discover ElastiCache cache cluster endpoints; check SNS subscription state | yes | `continuumRaasElastiCacheApi` |
| Kubernetes API | Kubernetes API (client-go) | Update telegraf deployment config maps and deployment resources | yes | `continuumRaasKubernetesApi` |
| Terraform Redis Definitions URL | HTTPS | Parse Terraform-hosted metadata for resque namespace mappings | no | `continuumRaasTerraformDefsUrl` |
| GitHub Raw Secrets | HTTPS | Bootstrap API credentials for Redislabs API access | yes | `continuumRaasGithubSecrets` |

### Redislabs Control Plane API Detail

- **Protocol**: REST/HTTPS
- **Base URL / SDK**: `continuumRaasRedislabsApi` — Redislabs REST API
- **Auth**: API credentials bootstrapped from `continuumRaasGithubSecrets`
- **Purpose**: `continuumRaasApiCachingService` fetches cluster, database, and node telemetry on a schedule. `continuumRaasAnsibleAdminService` calls the API to create and fetch managed database definitions.
- **Failure mode**: Telemetry snapshots are stale; Info Service and Monitoring Service operate on last-known-good cached data until the next successful collection
- **Circuit breaker**: No evidence found

### AWS ElastiCache API Detail

- **Protocol**: AWS SDK (Go)
- **Base URL / SDK**: AWS SDK — `continuumRaasElastiCacheApi`
- **Auth**: AWS IAM credentials (injected at runtime)
- **Purpose**: `continuumRaasConfigUpdaterService_raasAwsDiscoveryClient` queries ElastiCache cache clusters to discover live Redis/Memcached endpoints. `continuumRaasTerraformAfterhookService` checks SNS subscription state post-Terraform.
- **Failure mode**: Config Updater loop cannot detect server-set changes; Kubernetes config maps remain at last-applied state
- **Circuit breaker**: No evidence found

### Kubernetes API Detail

- **Protocol**: Kubernetes API (client-go)
- **Base URL / SDK**: In-cluster Kubernetes API — `continuumRaasKubernetesApi`
- **Auth**: Kubernetes service account / in-cluster credentials
- **Purpose**: `continuumRaasConfigUpdaterService_raasKubeDeployClient` applies telegraf config maps and updates deployment resources when discovered endpoints change
- **Failure mode**: Telegraf deployment config maps are not updated; monitoring data collection may lag
- **Circuit breaker**: No evidence found

### Terraform Redis Definitions URL Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `continuumRaasTerraformDefsUrl` — remote URL hosting Terraform Redis definitions
- **Auth**: No evidence found
- **Purpose**: `continuumRaasConfigUpdaterService_raasTerraformRepoParser` fetches and parses metadata to map resque namespaces to clusters
- **Failure mode**: Namespace mapping is stale; config updater uses cached mapping
- **Circuit breaker**: No evidence found

### GitHub Raw Secrets Detail

- **Protocol**: HTTPS
- **Base URL / SDK**: `continuumRaasGithubSecrets` — GitHub raw file access
- **Auth**: GitHub token
- **Purpose**: `continuumRaasApiCachingService` bootstraps Redislabs API credentials by reading secrets from GitHub at startup
- **Failure mode**: API Caching Service cannot authenticate to Redislabs; all telemetry collection halts
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Logging Stack | Log shipping | Ships application and daemon logs | `loggingStack` |
| Metrics Stack | Metrics push | Publishes service, monitoring, check, and config-update metrics | `metricsStack` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Direct consumers of the RaaS Info Service REST API are internal Redis platform operators and tooling.

## Dependency Health

> Operational health check and retry procedures to be defined by service owner. No circuit breaker or retry configuration is documented in the architecture model. The primary resilience pattern is the filesystem cache: if the Redislabs API is unavailable, downstream consumers (Info Updater, Monitoring, Checks Runner) operate on the last successfully written snapshot.
