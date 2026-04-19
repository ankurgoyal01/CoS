---
service: "taxonomyV2"
title: "Snapshot Activation & Cache Invalidation"
generated: "2026-03-03"
type: flow
flow_name: "snapshot-activation"
flow_type: event-driven
trigger: "PUT /snapshots/activate API call with a snapshot UUID"
participants:
  - "continuumTaxonomyV2Service_restApi"
  - "continuumTaxonomyV2Service_snapshotManagement"
  - "continuumTaxonomyV2Service_postgresRepositories"
  - "continuumTaxonomyV2Service_messageBusIntegration"
  - "continuumTaxonomyV2Service_cachingCore"
  - "continuumTaxonomyV2Service_notificationOrchestration"
  - "continuumTaxonomyV2Service_varnishEdgeClient"
  - "continuumTaxonomyV2Postgres"
  - "continuumTaxonomyV2Redis"
  - "continuumTaxonomyV2MessageBus"
  - "continuumTaxonomyV2VarnishCluster"
  - "continuumTaxonomyV2SlackApi"
  - "continuumTaxonomyV2EmailGateway"
architecture_ref: "dynamic-taxonomy-v2-cache-invalidation-flow"
---

# Snapshot Activation & Cache Invalidation

## Summary

This is the core content deployment flow for Taxonomy V2. When a caller activates a versioned taxonomy snapshot via `PUT /snapshots/activate`, the service persists the activation metadata to Postgres, publishes a cache invalidation message to the JMS message bus, rebuilds the Redis cache from the newly-active Postgres content, invalidates Varnish edge cache nodes, and sends Slack and email notifications about the deployment outcome. This flow is the mechanism by which new taxonomy content becomes live for all consumers.

## Trigger

- **Type**: api-call
- **Source**: Authorized internal caller (taxonomy authoring workflow or operator) sends `PUT /snapshots/activate` with a body containing `{"uuid": "<snapshot-uuid>"}`
- **Frequency**: On-demand (typically a few times per day during taxonomy content updates)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Resources | Receives and validates the activation request | `continuumTaxonomyV2Service_restApi` |
| Snapshot Management | Orchestrates the activation workflow | `continuumTaxonomyV2Service_snapshotManagement` |
| Postgres Repositories | Persists activation metadata and snapshot state | `continuumTaxonomyV2Service_postgresRepositories` |
| Message Bus Integration | Publishes and re-consumes cache invalidation event | `continuumTaxonomyV2Service_messageBusIntegration` |
| Caching & Cache Builder | Rebuilds denormalized Redis cache from Postgres | `continuumTaxonomyV2Service_cachingCore` |
| Notification Orchestration | Sends Slack, email, and Varnish validation notifications | `continuumTaxonomyV2Service_notificationOrchestration` |
| Varnish Edge Cache Client | Issues HTTP BAN to invalidate edge cache nodes | `continuumTaxonomyV2Service_varnishEdgeClient` |
| TaxonomyV2 Postgres DB | Stores snapshot state and taxonomy content | `continuumTaxonomyV2Postgres` |
| TaxonomyV2 Redis Cache | Receives rebuilt denormalized taxonomy data | `continuumTaxonomyV2Redis` |
| TaxonomyV2 Message Bus | Delivers cache invalidation event | `continuumTaxonomyV2MessageBus` |
| Varnish Edge Cache Cluster | Edge cache nodes that are invalidated | `continuumTaxonomyV2VarnishCluster` |
| Slack API | Receives deployment notification webhook | `continuumTaxonomyV2SlackApi` |
| SMTP Email Gateway | Delivers deployment result email | `continuumTaxonomyV2EmailGateway` |

## Steps

1. **Receive activation request**: The `continuumTaxonomyV2Service_requestFilters` validates the caller is authorized; the `continuumTaxonomyV2Service_restApi` routes the request to `continuumTaxonomyV2Service_snapshotManagement`.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_snapshotManagement`
   - Protocol: In-process call

2. **Persist deployment metadata**: Snapshot Management records the activation event, marks the snapshot as active, and updates snapshot map records in Postgres.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC

3. **Publish cache invalidation message**: Snapshot Management instructs the Message Bus Integration to publish a cache invalidation event to the JMS topic.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_messageBusIntegration` → `continuumTaxonomyV2MessageBus`
   - Protocol: JMS, jtier-messagebus
   - Topic: `jms.topic.taxonomyV2.cache.invalidate`

4. **Deliver invalidation message**: The message bus delivers the cache invalidation event back to the service's consumer (worker pool / `CacheInvalidationProcessor`).
   - From: `continuumTaxonomyV2MessageBus`
   - To: `continuumTaxonomyV2Service_messageBusIntegration`
   - Protocol: JMS

5. **Trigger cache invalidation workflow**: The `CacheInvalidationProcessor` dispatches the message to Snapshot Management, which initiates the cache rebuild sequence.
   - From: `continuumTaxonomyV2Service_messageBusIntegration`
   - To: `continuumTaxonomyV2Service_snapshotManagement`
   - Protocol: In-process call

6. **Rebuild Redis cache**: Snapshot Management instructs the Caching Core to flush stale cache entries and rebuild denormalized taxonomy structures by reading from Postgres.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_cachingCore`
   - Protocol: In-process call
   - The Caching Core reads full taxonomy content from `continuumTaxonomyV2Postgres` and writes denormalized structures into `continuumTaxonomyV2Redis`

7. **Invalidate Varnish edge cache**: After the Redis cache is rebuilt, Snapshot Management instructs the Varnish Edge Cache Client to issue HTTP BAN requests to all Varnish nodes.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_varnishEdgeClient` → `continuumTaxonomyV2VarnishCluster`
   - Protocol: HTTP BAN

8. **Send deployment notifications**: Snapshot Management instructs the Notification Orchestration Service to send success or failure notifications.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_notificationOrchestration`
   - Protocol: In-process call
   - The Notification Service sends to:
     - Slack (#taxonomy) via `continuumTaxonomyV2SlackApi` (HTTPS webhook)
     - Email (taxonomy-dev@groupon.com) via `continuumTaxonomyV2EmailGateway` (SMTP)
     - Downstream consumers via `continuumTaxonomyV2MessageBus` on `jms.topic.taxonomyV2.content.update`
     - Varnish Validation Service via `continuumTaxonomyV2VarnishValidationService` (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres write fails | Snapshot activation aborts; no cache invalidation published | 500 returned to caller; no state change |
| Cache rebuild fails | `NotificationService` sends failure notification to Slack and email | Stale data served from Redis; operator must re-trigger activation |
| Varnish BAN fails | Logged; notification sent; does not block activation | Stale edge cache until Varnish TTL expiry or manual invalidation |
| Slack/email notification fails | Logged only; does not affect data path | Operators lose automated notification visibility |
| JMS publish fails | Activation may abort depending on JTier retry policy; cache rebuild not triggered | Cache remains stale; operator must re-trigger |

## Sequence Diagram

```
Caller -> REST API: PUT /snapshots/activate {uuid}
REST API -> Request Filters: validate authorization
REST API -> Snapshot Management: trigger snapshot deployment
Snapshot Management -> Postgres Repositories: persist activation metadata
Postgres Repositories -> Postgres DB: UPDATE snapshot state
Snapshot Management -> Message Bus Integration: publish cache invalidation
Message Bus Integration -> Message Bus: jms.topic.taxonomyV2.cache.invalidate
Message Bus -> Message Bus Integration: deliver invalidation event
Message Bus Integration -> Snapshot Management: trigger cache invalidation workflow
Snapshot Management -> Caching Core: initiate cache rebuild
Caching Core -> Postgres Repositories: read taxonomy content
Postgres Repositories -> Postgres DB: SELECT taxonomy data
Caching Core -> Redis Cache: write denormalized taxonomy structures
Snapshot Management -> Varnish Client: invalidate edge cache
Varnish Client -> Varnish Cluster: HTTP BAN
Snapshot Management -> Notification Orchestration: notify deployment outcome
Notification Orchestration -> Slack API: POST deployment status
Notification Orchestration -> Email Gateway: SMTP deployment result
Notification Orchestration -> Message Bus: jms.topic.taxonomyV2.content.update
REST API -> Caller: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-taxonomy-v2-cache-invalidation-flow`
- Related flows: [Cache Rebuild via Message Bus](cache-rebuild-message-bus.md), [Partial Snapshot Deployment](partial-snapshot-deployment.md)
