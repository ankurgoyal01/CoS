---
service: "push-infrastructure"
title: "Campaign Stats Aggregation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-stats-aggregation"
flow_type: synchronous
trigger: "HTTP GET to /campaign/stats"
participants:
  - "continuumPushInfrastructureService"
  - "externalTransactionalDatabase_3f1a"
architecture_ref: "dynamic-campaign-stats-aggregation"
---

# Campaign Stats Aggregation

## Summary

The Campaign Stats Aggregation flow provides on-demand delivery statistics for a given campaign. Callers — typically campaign management dashboards or reporting services — request stats by campaignId via the `/campaign/stats` REST endpoint. Push Infrastructure queries the transactional database to aggregate per-channel delivery counts (enqueued, delivered, failed, rate-limited) and returns the results in a single response. This is a read-only synchronous query with no side effects.

## Trigger

- **Type**: api-call
- **Source**: Campaign management dashboard, reporting service, or operator tooling
- **Frequency**: On-demand; can be called repeatedly throughout a campaign's delivery window

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign dashboard / reporting service | Requests campaign statistics | — |
| Push Infrastructure Service | Receives query, aggregates stats from database, returns results | `continuumPushInfrastructureService` |
| Transactional Database | Source of message state and delivery outcome records | `externalTransactionalDatabase_3f1a` |

## Steps

1. **Receive stats request**: Caller submits HTTP GET to `/campaign/stats` with campaignId (and optionally channel, time range) as query parameters
   - From: `campaign dashboard / reporting service`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Query message state records**: Executes aggregation query against the transactional database — counts messages grouped by status (ENQUEUED, DELIVERED, FAILED, RATE_LIMITED) for the specified campaignId
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

3. **Aggregate per-channel stats**: Groups results by channel (push/email/sms) and status to produce per-channel delivery breakdown
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (internal aggregation)
   - Protocol: internal

4. **Return aggregated stats**: Returns HTTP 200 with stats payload — total enqueued, delivered, failed, rate-limited counts per channel and overall
   - From: `continuumPushInfrastructureService`
   - To: `campaign dashboard / reporting service`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| campaignId not found | Return HTTP 200 with zero counts, or HTTP 404 | Caller receives empty stats or not-found response |
| Database query failure | Return HTTP 500 | Caller should retry; no state changes |
| Query timeout (large campaign) | Return HTTP 500 or partial results | Caller should retry or narrow query scope with filters |

## Sequence Diagram

```
CampaignDashboard -> continuumPushInfrastructureService: GET /campaign/stats?campaignId={id}&channel={channel}
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT COUNT(*) GROUP BY status, channel WHERE campaignId={id}
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: [{status, channel, count}...]
continuumPushInfrastructureService -> continuumPushInfrastructureService: Aggregate into per-channel stats object
continuumPushInfrastructureService --> CampaignDashboard: HTTP 200 {campaignId, stats: {push: {enqueued, delivered, failed}, email: {...}, sms: {...}}}
```

## Related

- Architecture dynamic view: `dynamic-campaign-stats-aggregation`
- Related flows: [Campaign Assembly and Scheduling](campaign-assembly-scheduling.md), [Message Processing and Delivery](message-processing-delivery.md)
