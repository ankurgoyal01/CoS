---
service: "raas"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for RaaS (Redis-as-a-Service).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Redis Cluster Metadata Sync](redis-cluster-metadata-sync.md) | scheduled | Periodic job schedule | API Caching Service fetches Redislabs telemetry, writes filesystem snapshots; Info Updater parses and upserts into MySQL |
| [Cluster Health Monitoring](cluster-health-monitoring.md) | scheduled | Periodic job schedule | Monitoring Service aggregates cached telemetry into monitoring configs and syncs MySQL/PostgreSQL; Checks Runner executes Nagios health checks |
| [Kubernetes Config Sync](kubernetes-config-sync.md) | scheduled | Continuous polling loop | Config Updater discovers ElastiCache endpoints, parses Terraform namespace metadata, and applies telegraf config maps to Kubernetes |
| [Terraform Deployment Post-Hook](terraform-deployment-post-hook.md) | event-driven | Post-Terraform operator trigger | Terraform Afterhook processes Terraform diff outputs, generates static report pages, and validates alerting prerequisites |
| [Redis Database Provisioning](redis-database-provisioning.md) | synchronous | Operator manual action | Ansible Admin playbooks create or clone Redis databases in the Redislabs Control Plane |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The telemetry collection and metadata synchronization flow (`dynamic-raas-telemetry-flow`) spans `continuumRaasApiCachingService`, `continuumRaasInfoService`, and `continuumRaasMonitoringService` — all writing to `continuumRaasMetadataMysql`. See the central architecture dynamic view `dynamic-raas-telemetry-flow` for the full cross-container sequence.
