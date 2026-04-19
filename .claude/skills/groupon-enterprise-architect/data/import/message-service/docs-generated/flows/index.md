---
service: "message-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 8
---

# Flows

Process and flow documentation for the CRM Message Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Campaign Creation and Approval](campaign-creation-and-approval.md) | synchronous | API call or UI action | Campaign manager creates, configures, and submits a campaign for approval; metadata published to MBus on approval |
| [Message Delivery — getmessages](message-delivery-getmessages.md) | synchronous | API call | Consumer client requests eligible messages for a user; service evaluates constraints and returns matching campaigns |
| [Audience Assignment Batch](audience-assignment-batch.md) | batch | Kafka event / scheduled | Akka actors download audience export files and write user-campaign assignments to Bigtable or Cassandra |
| [Scheduled Audience Refresh](scheduled-audience-refresh.md) | event-driven | Kafka: ScheduledAudienceRefreshed | Kafka consumer receives refresh event and dispatches audience import jobs to rebuild assignments |
| [Message Event Tracking](message-event-tracking.md) | synchronous | API call | Consumer records a user interaction event (view, click, dismiss) against a delivered message |
| [Email Campaign Execution](email-campaign-execution.md) | synchronous | API call | Email pipeline requests eligible messages for the email channel; service returns email-targeted campaign content |
| [Cache Invalidation](cache-invalidation.md) | synchronous | Campaign state change | Redis cache entries for campaigns and templates are invalidated after a campaign is updated or approved |
| [Bigtable Scaling](bigtable-scaling.md) | synchronous | API call (operational) | Operator triggers Bigtable read/write node capacity change via the control plane endpoint |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Campaign Creation and Approval** spans `continuumMessagingService`, `continuumAudienceManagementService`, `continuumTaxonomyService`, `gims`, and `messageBus`
- **Audience Assignment Batch** spans `continuumMessagingService`, `continuumAudienceManagementService`, GCP Storage/HDFS, `continuumMessagingBigtable`, and `continuumMessagingCassandra`
- **Scheduled Audience Refresh** spans `messageBus` (Kafka), `continuumMessagingService`, and the audience assignment batch pipeline

These flows are candidates for dynamic view documentation in the central Structurizr workspace.
