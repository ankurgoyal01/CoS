---
service: "raas"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumRaasInfoService"
    - "continuumRaasApiCachingService"
    - "continuumRaasMonitoringService"
    - "continuumRaasChecksRunnerService"
    - "continuumRaasConfigUpdaterService"
    - "continuumRaasTerraformAfterhookService"
    - "continuumRaasAnsibleAdminService"
    - "continuumRaasMetadataMysql"
    - "continuumRaasMetadataPostgres"
---

# Architecture Context

## System Context

RaaS sits within the `continuumSystem` as an infrastructure sub-platform. It is operated by Redis platform engineers (administrators) and interfaces with three external systems: the Redislabs Control Plane API, the AWS ElastiCache API, and the Kubernetes API. Internally it does not interact with other Continuum business services — it is purely an infrastructure operations platform. Logs and metrics are shipped to the shared `loggingStack` and `metricsStack`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| RaaS Info Service | `continuumRaasInfoService` | Backend | Ruby on Rails | Rails 5.1.4, Puma 3.7+ | Rails application that exposes Redis cluster/database metadata and operational views |
| RaaS API Caching Service | `continuumRaasApiCachingService` | Backend | Ruby | 2.5.0 | Collector daemon that fetches Redislabs APIs and snapshots data to local cache files |
| RaaS Monitoring Service | `continuumRaasMonitoringService` | Backend | Ruby | 2.5.0 | Monitoring updater jobs that generate monitor configs and aggregate cluster metadata |
| RaaS Checks Runner | `continuumRaasChecksRunnerService` | Backend | Ruby / Nagios | 2.5.0 | Executor that forks Nagios checks and evaluates cluster health from cached telemetry |
| RaaS K8s Config Updater | `continuumRaasConfigUpdaterService` | Backend | Go | 1.12 | Polls AWS and Terraform definitions and updates telegraf deployment config maps in Kubernetes |
| RaaS Terraform Afterhook | `continuumRaasTerraformAfterhookService` | Backend | Ruby | 2.5.0 | Post-Terraform hook that builds reports/pages and checks alerting prerequisites |
| RaaS Ansible Admin | `continuumRaasAnsibleAdminService` | Backend | Ansible / Python | — | Playbooks and utilities for creating and cloning Redis databases in managed clusters |
| RaaS Metadata MySQL | `continuumRaasMetadataMysql` | Database | MySQL | — | Primary MySQL store for RaaS inventory metadata |
| RaaS Metadata PostgreSQL | `continuumRaasMetadataPostgres` | Database | PostgreSQL | — | Secondary PostgreSQL mirror of monitoring metadata |

## Components by Container

### RaaS Info Service (`continuumRaasInfoService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RaaS Info Web UI | Serves operational pages and JSON endpoints for clusters, DBs, nodes, and shards | Rails Controllers/Views |
| RaaS Info Updater Job | Parses cached rladmin and API JSON snapshots and synchronizes ActiveRecord models | Rails Runner |
| RaaS Info Persistence Layer | ActiveRecord model layer for clusters, nodes, DBs, endpoints, and shards | ActiveRecord |

### RaaS API Caching Service (`continuumRaasApiCachingService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Cache Collector | Fetches Redislabs cluster APIs, node endpoints, and status payloads | Ruby Script |
| API Cache Storage | Writes atomic JSON snapshots under the local `api_cache` and `raas_info` directories | Filesystem Cache |

### RaaS Monitoring Service (`continuumRaasMonitoringService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Monitoring Updater Job | Builds monitor definitions from host inventory and DB metadata | Ruby Script |
| RaaS Mons Aggregator Job | Aggregates cluster states across monitoring hosts and prepares raas-info artifacts | Ruby Script |
| Monitoring DB Sync Job | Swaps temporary tables and updates MySQL/PostgreSQL metadata stores | Ruby Script |

### RaaS Checks Runner (`continuumRaasChecksRunnerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Checks Orchestrator | Loads monitoring check definitions and orchestrates child check workers | Ruby Script |
| Check Plugins | Nagios check scripts for Redis/cluster health and policy checks | Ruby/Shell Checks |

### RaaS K8s Config Updater (`continuumRaasConfigUpdaterService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Config Updater Loop | Main reconciliation loop that detects server-set changes and triggers telegraf deployment updates | Go |
| AWS Discovery Client | Queries ElastiCache cache clusters and normalizes discovered Redis/Memcached endpoints | Go AWS SDK |
| Kubernetes Deploy Client | Builds config maps and creates/updates telegraf deployment resources | Go client-go |
| Terraform Repo Parser | Parses Terraform-hosted metadata to map resque namespaces | Go HTTP Parser |

### RaaS Terraform Afterhook (`continuumRaasTerraformAfterhookService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Terraform Diff Processor | Loads Terraform outputs and computes operational deltas for reporting and alert checks | Ruby |
| Pages Generator | Generates static report assets consumed by RaaS dashboards | Ruby |

### RaaS Ansible Admin (`continuumRaasAnsibleAdminService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Create DB Playbook | Applies `create_db` and `fetch_db_specs` playbooks for managed Redis database lifecycle operations | Ansible Playbook |
| DB Spec Pruner | Prunes fetched DB/alerts payloads into normalized playbook inputs | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRaasInfoService` | `continuumRaasMetadataMysql` | Reads/writes metadata entities | SQL |
| `continuumRaasInfoService` | `continuumRaasApiCachingService` | Consumes cached API data for sync jobs | Filesystem |
| `continuumRaasApiCachingService` | `continuumRaasRedislabsApi` | Fetches cluster and DB telemetry | REST/HTTPS |
| `continuumRaasApiCachingService` | `continuumRaasGithubSecrets` | Bootstraps API credentials | HTTPS |
| `continuumRaasMonitoringService` | `continuumRaasApiCachingService` | Consumes cached telemetry and generated artifacts | Filesystem |
| `continuumRaasMonitoringService` | `continuumRaasMetadataMysql` | Publishes refreshed monitoring metadata | SQL |
| `continuumRaasMonitoringService` | `continuumRaasMetadataPostgres` | Publishes mirrored monitoring metadata | SQL |
| `continuumRaasChecksRunnerService` | `continuumRaasApiCachingService` | Reads cached db and rladmin status | Filesystem |
| `continuumRaasConfigUpdaterService` | `continuumRaasElastiCacheApi` | Discovers ElastiCache endpoints | AWS SDK |
| `continuumRaasConfigUpdaterService` | `continuumRaasTerraformDefsUrl` | Parses resque namespace metadata | HTTPS |
| `continuumRaasConfigUpdaterService` | `continuumRaasKubernetesApi` | Updates telegraf deployment and config maps | Kubernetes API |
| `continuumRaasTerraformAfterhookService` | `continuumRaasElastiCacheApi` | Checks SNS subscription state | AWS SDK |
| `continuumRaasAnsibleAdminService` | `continuumRaasRedislabsApi` | Creates and fetches managed DB definitions | REST/HTTPS |

## Architecture Diagram References

- System context: `contexts-raas`
- Container: `containers-raas`
- Component: `components-continuumRaasInfoService`, `components-continuumRaasApiCachingService`, `components-continuumRaasMonitoringService`, `components-continuumRaasChecksRunnerService`, `components-continuumRaasConfigUpdaterService`, `components-continuumRaasTerraformAfterhookService`, `components-continuumRaasAnsibleAdminService`
- Dynamic: `dynamic-raas-telemetry-flow`
