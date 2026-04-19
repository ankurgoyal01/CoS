---
service: "deals-cluster-api-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Deals Cluster API.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Cluster Query](cluster-query.md) | synchronous | API call from consumer | Consumer queries deal clusters with filter parameters; API returns paginated cluster list from PostgreSQL |
| [Rule Management](rule-management.md) | synchronous | API call from operator or Spark Job | Operator creates, updates, or deletes cluster rules; Spark Job reads rules for computation |
| [Top Clusters Query](top-clusters-query.md) | synchronous | API call from navigation surface | Navigation surface requests top-performing clusters by type and country; served from in-memory cache |
| [Spark Job Rule Fetch and Cluster Write](spark-job-cluster-write.md) | synchronous | Deals Cluster Spark Job (batch/scheduled) | Spark Job fetches rules, computes clusters on GDOOP, and writes results back to this API |
| [Marketing Tagging Use Case Execution](tagging-use-case-execution.md) | asynchronous | Scheduled or manual trigger | Tagging Scheduler triggers use case; Use Case Execute Service publishes JMS messages; workers call Marketing Deal Service to tag/untag deals; audit records persisted |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

- The **Spark Job Rule Fetch and Cluster Write** flow spans `continuumDealsClusterSparkJob` and `continuumDealsClusterApi`. The Spark Job is a separate service that initiates the cluster computation pipeline.
- The **Marketing Tagging Use Case Execution** flow spans `continuumDealsClusterApi`, the JMS message bus (`messageBusTaggingQueue`, `messageBusUntaggingQueue`), and `continuumMarketingDealService`.
- Architecture dynamic views are referenced in the Structurizr workspace under `continuumSystem`.
