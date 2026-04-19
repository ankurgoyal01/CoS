---
service: "taxonomyV2"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Taxonomy V2 uses a JMS-based message bus (Groupon's internal `mbus` / `jtier-messagebus`) to coordinate cache invalidation and signal content updates to downstream consumers. The service both publishes and consumes messages — it publishes cache invalidation triggers when snapshot activations occur, and consumes those same invalidation messages via a worker pool to drive the actual cache rebuild. A separate content update topic is used to notify downstream integrations (such as the Bynder integration service) of taxonomy content changes.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `jms.topic.taxonomyV2.cache.invalidate` | Cache Invalidation | Snapshot activation (`PUT /snapshots/activate` or partial snapshot activate) | Snapshot UUID, environment identifier |
| `jms.topic.taxonomyV2.content.update` | Content Update | Taxonomy content is deployed and ready for downstream consumption | Taxonomy content version metadata |

### Cache Invalidation Event Detail

- **Topic**: `jms.topic.taxonomyV2.cache.invalidate`
- **Trigger**: A snapshot activation is requested via `PUT /snapshots/activate`, `/partialsnapshots/liveactivate`, or `/partialsnapshots/testactivate`
- **Payload**: Snapshot UUID and target environment context; exact schema is internal to the `continuumTaxonomyV2Service_messageBusIntegration` component
- **Consumers**: The Taxonomy V2 service itself (cache rebuild worker pool); potentially other internal services monitoring taxonomy cache state
- **Guarantees**: At-least-once (JMS topic delivery)

### Content Update Event Detail

- **Topic**: `jms.topic.taxonomyV2.content.update`
- **Trigger**: Successful taxonomy content deployment during snapshot activation
- **Payload**: Content version metadata signaling that new taxonomy content is available
- **Consumers**: Known consumer: Bynder integration service (evidence from message bus metrics URL in `doc/owners_manual.md`)
- **Guarantees**: At-least-once (JMS topic delivery)

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| `jms.topic.taxonomyV2.cache.invalidate` | Cache Invalidation | `continuumTaxonomyV2Service_messageBusIntegration` / `CacheInvalidationProcessor` | Triggers cache rebuild in Redis via `continuumTaxonomyV2Service_cachingCore` |

### Cache Invalidation Consumption Detail

- **Topic**: `jms.topic.taxonomyV2.cache.invalidate`
- **Handler**: `CacheInvalidationProcessor` within the `continuumTaxonomyV2Service_messageBusIntegration` component — dispatches to `continuumTaxonomyV2Service_snapshotManagement` which initiates the cache rebuild
- **Idempotency**: Cache rebuilds are idempotent by nature — rebuilding an already-current cache results in an up-to-date cache state
- **Error handling**: Notification is sent via `continuumTaxonomyV2Service_notificationOrchestration` (Slack + email) if cache build fails; DLQ strategy is not documented in the codebase
- **Processing order**: Unordered (topic broadcast)

## Dead Letter Queues

> No evidence found in codebase. DLQ configuration for `jms.topic.taxonomyV2.cache.invalidate` is not documented in the source or deployment configuration files. Contact the taxonomy team (taxonomy-dev@groupon.com) for DLQ policy.

## Message Bus Metrics

- Cache invalidate topic: [Grafana MessageBus Dashboard](https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ee504tdtmpbeoa/messagebus-cloud-dashboard?orgId=1&var-region=us-central1&var-address=jms.topic.taxonomyV2.cache.invalidate)
- Content update topic: [Grafana MessageBus Dashboard](https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ee504tdtmpbeoa/messagebus-cloud-dashboard?orgId=1&var-region=us-central1&var-address=jms.topic.taxonomyV2.content.update)
