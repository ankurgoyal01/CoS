---
service: "deal-catalog-service"
title: "Node Payload Refresh"
generated: "2026-03-03"
type: flow
flow_name: "node-payload-refresh"
flow_type: scheduled
trigger: "Quartz cron schedule"
participants:
  - "dealCatalog_nodePayloadFetcher"
  - "dealCatalog_repository"
  - "dealCatalog_messagePublisher"
  - "continuumDealCatalogDb"
  - "messageBus"
architecture_ref: ""
---

# Node Payload Refresh

## Summary

The Node Payload Fetcher is a scheduled Quartz job within the Deal Catalog Service that periodically fetches remote node payloads from external sources and updates node state in the database. After successfully refreshing payloads, the fetcher emits update events through the Message Publisher to notify downstream consumers of the updated node state.

## Trigger

- **Type**: Schedule (Quartz cron job)
- **Source**: Internal Quartz scheduler within the Deal Catalog Service
- **Frequency**: Periodic (cron schedule configured via `QUARTZ_CRON_NODE_PAYLOAD` or Quartz properties)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Node Payload Fetcher | Scheduled job that orchestrates the refresh process | `dealCatalog_nodePayloadFetcher` |
| Catalog Repository | Data access layer for reading/writing node payload metadata | `dealCatalog_repository` |
| Deal Catalog DB | Stores node payload metadata | `continuumDealCatalogDb` |
| Message Publisher | Publishes update events after payload refresh | `dealCatalog_messagePublisher` |
| Message Bus (MBus) | Distributes node payload update events | `messageBus` |

## Steps

1. **Quartz triggers Node Payload Fetcher**: The Quartz scheduler fires the Node Payload Fetcher job based on the configured cron expression.
   - From: Quartz Scheduler
   - To: `dealCatalog_nodePayloadFetcher`
   - Protocol: Internal (Quartz)

2. **Fetcher reads current node state**: The Node Payload Fetcher queries the Catalog Repository for current node payload metadata to determine which nodes need refresh.
   - From: `dealCatalog_nodePayloadFetcher`
   - To: `dealCatalog_repository`
   - Protocol: Direct (in-process)

3. **Repository queries database**: The Catalog Repository fetches node payload records from MySQL.
   - From: `dealCatalog_repository`
   - To: `continuumDealCatalogDb`
   - Protocol: JDBC

4. **Fetcher retrieves remote payloads**: The Node Payload Fetcher makes HTTP calls to remote node endpoints to fetch updated payload data.
   - From: `dealCatalog_nodePayloadFetcher`
   - To: Remote node endpoints
   - Protocol: HTTP (Java HTTP Client)

5. **Fetcher updates node state**: The fetcher writes the refreshed payload data back through the Catalog Repository.
   - From: `dealCatalog_nodePayloadFetcher`
   - To: `dealCatalog_repository`
   - Protocol: Direct (in-process)

6. **Repository persists updates**: The repository writes the updated node payload metadata to MySQL.
   - From: `dealCatalog_repository`
   - To: `continuumDealCatalogDb`
   - Protocol: JDBC

7. **Fetcher emits update events**: After successful refresh, the Node Payload Fetcher publishes update events via the Message Publisher.
   - From: `dealCatalog_nodePayloadFetcher`
   - To: `dealCatalog_messagePublisher`
   - Protocol: Direct (in-process)

8. **Message Publisher writes to MBus**: The update events are published to the configured MBus topic.
   - From: `dealCatalog_messagePublisher`
   - To: `messageBus`
   - Protocol: Async (MBus)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Remote node endpoint unreachable | Log error; skip node; retry on next scheduled run | Node payload remains stale until next successful fetch |
| Database write failure | Transaction rollback; log error | Node state not updated; retried on next scheduled run |
| MBus publish failure | Log error; payload updated but event not delivered | Database updated but downstream consumers not notified |
| Quartz scheduler failure | Quartz retry/recovery mechanisms | Scheduled execution missed; runs on next trigger |

## Sequence Diagram

```
Quartz Scheduler -> Node Payload Fetcher: Trigger scheduled job
Node Payload Fetcher -> Catalog Repository: Read current node state
Catalog Repository -> Deal Catalog DB: Query node payload records (JDBC)
Deal Catalog DB --> Catalog Repository: Node records
Node Payload Fetcher -> Remote Endpoints: Fetch remote payloads (HTTP)
Remote Endpoints --> Node Payload Fetcher: Payload data
Node Payload Fetcher -> Catalog Repository: Write updated node state
Catalog Repository -> Deal Catalog DB: Update node records (JDBC)
Node Payload Fetcher -> Message Publisher: Emit update events
Message Publisher -> Message Bus: Publish node payload updated (Async/MBus)
```

## Related

- Architecture dynamic view: N/A (no dynamic view defined for this flow)
- Related flows: [Deal Lifecycle Event Publishing](deal-lifecycle-event-publishing.md)
