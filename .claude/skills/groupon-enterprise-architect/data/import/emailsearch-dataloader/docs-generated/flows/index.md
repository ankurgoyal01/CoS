---
service: "emailsearch-dataloader"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Email Search Dataloader.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Campaign Decision Job](campaign-decision-job.md) | scheduled | Quartz scheduler (periodic) | Evaluates A/B treatment statistical significance for APPROVED campaigns and issues rollout commands to Campaign Management Service |
| [Kafka Event Ingestion](kafka-event-ingestion.md) | event-driven | Kafka email delivery/bounce/unsubscribe events | Consumes events from Kafka cluster, updates campaign performance state, processes bounces and unsubscriptions |
| [Metrics Export to Hive](metrics-export-to-hive.md) | scheduled | Quartz scheduler (periodic) | Reads stat-sig metrics from PostgreSQL since last export timestamp and writes them to the Hive analytics warehouse |
| [Engage Upload Job](engage-upload-job.md) | scheduled | Quartz scheduler (periodic) | Uploads Phrasee/Engage campaign performance results to the Phrasee service after a configurable delay |
| [Campaign Performance API Query](campaign-performance-api-query.md) | synchronous | Inbound HTTP request | Handles REST requests for campaign performance data lookup by UTM campaign identifier |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 3 |

## Cross-Service Flows

The Campaign Decision Job spans the widest set of services and is the primary cross-service flow for the email/push campaign optimization platform:

- `continuumEmailSearchDataloaderService` fetches campaigns from `continuumCampaignManagementService`
- `continuumEmailSearchDataloaderService` fetches performance from `externalCampaignPerformanceService_9f3b`
- `continuumEmailSearchDataloaderService` fetches inbox metrics from `externalInboxManagementEmailUiService_6a2d` and `externalInboxManagementPushUiService_63de`
- `continuumEmailSearchDataloaderService` issues rollout commands back to `continuumCampaignManagementService`
- `continuumEmailSearchDataloaderService` persists decisions to `continuumEmailSearchPostgresDb`

The Kafka Event Ingestion flow spans:
- `externalKafkaCluster_3c9a` to `continuumEmailSearchDataloaderService`
- `continuumEmailSearchDataloaderService` to `continuumEmailSearchPostgresDb`
- `continuumEmailSearchDataloaderService` to `externalSubscriptionService_f0a4` (for unsubscribe events)

> No dynamic views are defined in the architecture DSL. The flows above are derived from source code and container-level relationship definitions.
