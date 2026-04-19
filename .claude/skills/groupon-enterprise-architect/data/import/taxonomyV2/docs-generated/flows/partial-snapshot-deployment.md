---
service: "taxonomyV2"
title: "Partial Snapshot Deployment"
generated: "2026-03-03"
type: flow
flow_name: "partial-snapshot-deployment"
flow_type: event-driven
trigger: "PUT /partialsnapshots/liveactivate or PUT /partialsnapshots/testactivate with a snapshot UUID"
participants:
  - "continuumTaxonomyV2Service_restApi"
  - "continuumTaxonomyV2Service_requestFilters"
  - "continuumTaxonomyV2Service_snapshotManagement"
  - "continuumTaxonomyV2Service_postgresRepositories"
  - "continuumTaxonomyV2Service_cachingCore"
  - "continuumTaxonomyV2Service_notificationOrchestration"
  - "continuumTaxonomyV2Postgres"
  - "continuumTaxonomyV2Redis"
  - "continuumTaxonomyV2SlackApi"
  - "continuumTaxonomyV2EmailGateway"
architecture_ref: "components-continuum-taxonomy-v2-service-components-view"
---

# Partial Snapshot Deployment

## Summary

Partial snapshot deployment allows targeted activation of a subset of taxonomy content — covering only a portion of the taxonomy tree — without requiring a full snapshot rebuild. This flow supports two distinct targets: test environment (`PUT /partialsnapshots/testactivate`) and live environment (`PUT /partialsnapshots/liveactivate`). It follows the same orchestration pattern as the full snapshot activation (persist metadata, rebuild cache, notify) but applies only the changed portions of taxonomy content to the Redis cache rather than rebuilding the entire structure.

## Trigger

- **Type**: api-call
- **Source**: Authorized taxonomy operator or automated workflow sending a `PUT` to `/partialsnapshots/testactivate` or `/partialsnapshots/liveactivate` with a body containing `{"uuid": "<partial-snapshot-uuid>"}`
- **Frequency**: On-demand during incremental taxonomy content updates or testing workflows

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| REST API Resources | Receives and routes the partial activation request | `continuumTaxonomyV2Service_restApi` |
| Request Filters & Authorization | Validates authorization for snapshot operations | `continuumTaxonomyV2Service_requestFilters` |
| PT Snapshot Management | Orchestrates partial snapshot activation for test or live targets | `continuumTaxonomyV2Service_snapshotManagement` |
| Postgres Repositories | Reads partial snapshot content and persists activation metadata | `continuumTaxonomyV2Service_postgresRepositories` |
| Caching & Cache Builder (PT) | Applies partial cache updates for the affected taxonomy portion | `continuumTaxonomyV2Service_cachingCore` |
| Notification Orchestration | Sends deployment notifications to Slack and email | `continuumTaxonomyV2Service_notificationOrchestration` |
| TaxonomyV2 Postgres DB | Stores partial snapshot data and activation state | `continuumTaxonomyV2Postgres` |
| TaxonomyV2 Redis Cache | Receives partial cache updates | `continuumTaxonomyV2Redis` |
| Slack API | Receives deployment notification | `continuumTaxonomyV2SlackApi` |
| SMTP Email Gateway | Delivers deployment result email | `continuumTaxonomyV2EmailGateway` |

## Steps

1. **Receive partial activation request**: The REST API receives `PUT /partialsnapshots/testactivate` or `/partialsnapshots/liveactivate` with the partial snapshot UUID.
   - From: Caller
   - To: `continuumTaxonomyV2Service_restApi`
   - Protocol: REST (HTTP PUT)

2. **Authorize request**: Request Filters validate that the caller has permission to activate partial snapshots.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_requestFilters`
   - Protocol: In-process call

3. **Route to PT Snapshot Management**: The REST API routes to the partial taxonomy snapshot management component, determining whether to activate in test or live environment based on the endpoint path.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: `continuumTaxonomyV2Service_snapshotManagement` (PT variant)
   - Protocol: In-process call

4. **Load partial snapshot from Postgres**: PT Snapshot Management reads the partial snapshot content (the changed categories, attributes, and relationships) from the Postgres repository.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC

5. **Apply partial cache update**: The PT Cache Builder applies the partial updates to the Redis cache, overwriting only the affected category entries rather than rebuilding the full taxonomy cache.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_cachingCore` → `continuumTaxonomyV2Redis`
   - Protocol: Redisson / Redis SET (targeted keys)

6. **Persist activation metadata**: Snapshot Management records the partial activation event and updates the snapshot state in Postgres.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_postgresRepositories` → `continuumTaxonomyV2Postgres`
   - Protocol: JDBI / JDBC

7. **Send notifications**: Notification Orchestration sends the deployment status to Slack and email.
   - From: `continuumTaxonomyV2Service_snapshotManagement`
   - To: `continuumTaxonomyV2Service_notificationOrchestration`
   - Protocol: In-process
   - Notification message: "Deployment triggered. Please check #TAXONOMY channel or mail from taxonomy-dev@groupon.com for deployment status"

8. **Return response**: REST API returns HTTP 200 to the caller.
   - From: `continuumTaxonomyV2Service_restApi`
   - To: Caller
   - Protocol: HTTP 200

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Partial snapshot UUID not found | Returns 404 | Caller receives 404; no state change |
| Cache update fails | Notification sent via Slack/email; partial update may be incomplete | Stale data for affected categories; operator must re-trigger |
| Postgres read/write fails | Returns 500 | No activation occurs; no cache change |
| Slack/email notification fails | Logged only | Activation succeeds; operator loses notification |

## Sequence Diagram

```
Caller -> REST API: PUT /partialsnapshots/{testactivate|liveactivate} {uuid}
REST API -> Request Filters: validate authorization
REST API -> PT Snapshot Management: activate partial snapshot {uuid} in {test|live}
PT Snapshot Management -> Postgres Repositories: read partial snapshot content
Postgres Repositories -> Postgres DB: SELECT partial snapshot data
Postgres DB --> Postgres Repositories: category/attribute changes
PT Snapshot Management -> PT Cache Builder: apply partial cache update
PT Cache Builder -> Redis Cache: SET affected category keys
PT Snapshot Management -> Postgres Repositories: persist activation metadata
Postgres Repositories -> Postgres DB: UPDATE snapshot state
PT Snapshot Management -> Notification Orchestration: notify deployment outcome
Notification Orchestration -> Slack API: POST deployment status
Notification Orchestration -> Email Gateway: SMTP deployment result
REST API -> Caller: 200 OK
```

## Related

- Architecture dynamic view: `components-continuum-taxonomy-v2-service-components-view`
- Related flows: [Snapshot Activation & Cache Invalidation](snapshot-activation.md), [Cache Rebuild via Message Bus](cache-rebuild-message-bus.md)
- Reference docs: Partial Taxonomy Runbook (internal Google Doc linked in `doc/owners_manual.md`)
