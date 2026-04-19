---
service: "taxonomyV2"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Taxonomy V2.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Snapshot Activation & Cache Invalidation](snapshot-activation.md) | synchronous + event-driven | `PUT /snapshots/activate` API call | Activates a versioned taxonomy snapshot, rebuilds Redis cache, invalidates Varnish, and sends notifications |
| [Category Read (Cache-Aside)](category-read.md) | synchronous | `GET /categories/{guid}` API call | Resolves a category by UUID from Redis cache, falling back to Postgres |
| [Flat Taxonomy Hierarchy Query](flat-taxonomy-query.md) | synchronous | `GET /taxonomies/{guid}/flat` API call | Returns the full flat category hierarchy for a taxonomy, with conditional caching via `If-Modified-Since` |
| [Partial Snapshot Deployment](partial-snapshot-deployment.md) | synchronous + event-driven | `PUT /partialsnapshots/liveactivate` or `testactivate` | Activates a partial taxonomy snapshot for test or live environments with notification |
| [Cache Rebuild via Message Bus](cache-rebuild-message-bus.md) | asynchronous / event-driven | JMS message on `jms.topic.taxonomyV2.cache.invalidate` | Processes a cache invalidation message from the message bus to trigger a Redis cache rebuild |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 1 |
| Synchronous + event-driven (hybrid) | 2 |

## Cross-Service Flows

- The **Snapshot Activation** flow spans `continuumTaxonomyV2Service`, `continuumTaxonomyV2Postgres`, `continuumTaxonomyV2Redis`, `continuumTaxonomyV2MessageBus`, `continuumTaxonomyV2VarnishCluster`, `continuumTaxonomyV2SlackApi`, and `continuumTaxonomyV2EmailGateway`. It is documented in the Structurizr dynamic view `dynamic-taxonomy-v2-cache-invalidation-flow`.
- The **Cache Rebuild** flow is driven by the `continuumTaxonomyV2MessageBus` delivering messages back into `continuumTaxonomyV2Service`, making it a self-consuming loop coordinated asynchronously.
- The **Partial Snapshot** flow shares the same notification and Varnish invalidation path as the full snapshot flow but targets test/live environments independently.
