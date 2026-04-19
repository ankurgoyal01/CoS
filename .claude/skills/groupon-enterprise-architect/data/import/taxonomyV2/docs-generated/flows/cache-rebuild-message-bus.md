---
service: "taxonomyV2"
title: "Cache Rebuild via Message Bus"
generated: "2026-03-03"
type: flow
flow_name: "cache-rebuild-message-bus"
flow_type: asynchronous
trigger: "JMS message delivered on jms.topic.taxonomyV2.cache.invalidate"
participants:
  - "continuumTaxonomyV2MessageBus"
  - "continuumTaxonomyV2Service_messageBusIntegration"
  - "continuumTaxonomyV2Service_snapshotManagement"
  - "continuumTaxonomyV2Service_cachingCore"
  - "continuumTaxonomyV2Service_postgresRepositories"
  - "continuumTaxonomyV2Service_notificationOrchestration"
  - "continuumTaxonomyV2Postgres"
  - "continuumTaxonomyV2Redis"
  - "continuumTaxonomyV2SlackApi"
  - "continuumTaxonomyV2EmailGateway"
architecture_ref: "dynamic-taxonomy-v2-cache-invalidation-flow"
---

# Cache Rebuild via Message Bus

## Summary

This asynchronous flow describes how Taxonomy V2 processes incoming cache invalidation messages from its own JMS topic (`jms.topic.taxonomyV2.cache.invalidate`) to trigger a Redis cache rebuild. The message bus acts as the decoupling layer between the snapshot activation trigger (which publishes the event) and the actual cache rebuild work (which is consumed asynchronously). This design allows the snapshot activation API to return quickly while cache rebuild proceeds in the background via the worker pool. This flow is documented in the Structurizr dynamic view `dynamic-taxonomy-v2-cache-invalidation-flow`.

## Trigger

- **Type**: event (JMS message)
- **Source**: `jms.topic.taxonomyV2.cache.invalidate` — published by the service's own `continuumTaxonomyV2Service_messageBusIntegration` component during snapshot activation
- **Frequency**: Once per snapshot activation event; on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TaxonomyV2 Message Bus | Delivers the cache invalidation JMS message | `continuumTaxonomyV2MessageBus` |
| Message Bus Integration & Processors | Consumes the JMS message via CacheInvalidationProcessor | `continuumTaxonomyV2Service_messageBusIntegration` |
| Snapshot Management | Receives dispatched invalidation and orchestrates rebuild | `continuumTaxonomyV2Service_snapshotManagement` |
| Caching & Cache Builder | Reads from Postgres and writes denormalized data to Redis | `continuumTaxonomyV2Service_cachingCore` |
| Postgres Repositories | Provides canonical taxonomy content for cache materialization | `continuumTaxonomyV2Service_postgresRepositories` |
| Notification Orchestration | Sends success or failure notifications | `continuumTaxonomyV2Service_notificationOrchestration` |
| TaxonomyV2 Postgres DB | Source of truth for taxonomy data loaded into cache | `continuumTaxonomyV2Postgres` |
| TaxonomyV2 Redis Cache | Target of the rebuilt denormalized taxonomy content | `continuumTaxonomyV2Redis` |
| Slack API | Receives cache build status notification | `continuumTaxonomyV2SlackApi` |
| SMTP Email Gateway | Delivers cache build result email | `continuumTaxonomyV2EmailGateway` |

## Steps

1. **Receive JMS message**: The `CacheInvalidationProcessor` within `continuumTaxonomyV2Service_messageBusIntegration` receives a message from `jms.topic.taxonomyV2.cache.invalidate`. The message payload contains the snapshot UUID and environment context.
   - From: `continuumTaxonomyV2MessageBus`
   - To: `continuumTaxonomyV2Service_messageBusIntegration`
   - Protocol: JMS

2. **Dispatch to Snapshot Management**: The `CacheInvalidationProcessor` dispatches the invalidation event to the appropriate Snapshot Management service (live or test, depending on the message payload environment context).
   - From: `continuumTaxonomyV2Service_messageBusIntegration`
   - To: `continuumTaxonomyV2Service_snapshotManagement`
   - Protocol: In-process call

3. **Initiate cache rebuild**: Snapshot Management instructs the Caching Core to flush stale Redis cache entries for the affected taxonomy and initiate a fresh rebuild.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_cachingCore`
   - Protocol: In-process call

4. **Read canonical data from Postgres**: The Caching Core reads all taxonomy content (categories, attributes, locales, relationships, and hierarchy structure) for the activated snapshot from Postgres via the Postgres Repositories.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC (potentially large multi-table read)

5. **Materialize denormalized cache**: The Caching Core builds denormalized taxonomy structures (flat hierarchy, category lookup maps, search indexes) from the Postgres data and writes them into Redis.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Redis`
   - Protocol: Redisson bulk write (multiple Redis SET / HSET operations)

6. **Update last-modified timestamp**: The Caching Core writes the new content timestamp to Redis so that `If-Modified-Since` checks on `GET /taxonomies/{guid}/flat` reflect the updated content version.
   - From: `continuumTaxonomyV2Service_cachingCore`
   - To: `continuumTaxonomyV2Redis`
   - Protocol: Redisson SET

7. **Notify outcome**: Snapshot Management instructs Notification Orchestration to send the cache build result (success or failure) to Slack and email.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_notificationOrchestration`
   - Protocol: In-process call
   - Channels: Slack #taxonomy (`continuumTaxonomyV2SlackApi`), email to taxonomy-dev@groupon.com (`continuumTaxonomyV2EmailGateway`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres read fails during cache build | Cache build aborts; failure notification sent | Redis cache remains stale; operator must re-trigger snapshot activation |
| Redis write fails during cache materialization | Partial cache written; failure notification sent | Some taxonomy data may be inconsistent in Redis; operator must re-trigger |
| Message processing failure | JMS message may be redelivered (at-least-once); idempotent cache rebuild | Cache rebuild re-attempted; safe due to idempotency of full rebuild |
| Notification delivery fails (Slack/email) | Logged; does not affect cache rebuild | Cache rebuilt successfully; operators lose automated notification |

## Sequence Diagram

```
Message Bus -> Message Bus Integration: deliver jms.topic.taxonomyV2.cache.invalidate {snapshot_uuid, env}
Message Bus Integration -> CacheInvalidationProcessor: process message
CacheInvalidationProcessor -> Snapshot Management: trigger cache invalidation workflow
Snapshot Management -> Caching Core: initiate cache rebuild for {snapshot_uuid}
Caching Core -> Postgres Repositories: read taxonomy content for snapshot
Postgres Repositories -> Postgres DB: SELECT categories, attributes, locales, relationships
Postgres DB --> Postgres Repositories: full taxonomy data
Caching Core -> Redis Cache: flush stale cache entries
Caching Core -> Redis Cache: write denormalized category lookup maps
Caching Core -> Redis Cache: write flat hierarchy structures
Caching Core -> Redis Cache: write search indexes
Caching Core -> Redis Cache: SET taxonomy_last_updated:{guid} = now
Snapshot Management -> Notification Orchestration: notify rebuild outcome
Notification Orchestration -> Slack API: POST cache build status
Notification Orchestration -> Email Gateway: SMTP cache build result
```

## Related

- Architecture dynamic view: `dynamic-taxonomy-v2-cache-invalidation-flow`
- Related flows: [Snapshot Activation & Cache Invalidation](snapshot-activation.md), [Partial Snapshot Deployment](partial-snapshot-deployment.md)
- Message bus metrics: `jms.topic.taxonomyV2.cache.invalidate` in Grafana MessageBus dashboard
