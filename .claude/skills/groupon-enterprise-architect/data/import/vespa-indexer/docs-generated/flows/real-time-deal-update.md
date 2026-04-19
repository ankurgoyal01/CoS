---
service: "vespa-indexer"
title: "Real-Time Deal Update Indexing"
generated: "2026-03-03"
type: flow
flow_name: "real-time-deal-update"
flow_type: event-driven
trigger: "Deal change event published to MessageBus topic jms.topic.mars.mds.genericchange"
participants:
  - "messageBus"
  - "continuumVespaIndexerService"
  - "dealUpdateListener"
  - "consumeDealUpdatesUseCase"
  - "dealUpdateAdapter"
  - "mbusDealUpdateClient"
  - "bigQueryDealOptionEnricher"
  - "bigQueryClient"
  - "searchIndexAdapter"
  - "vespaClient"
  - "vespaCluster"
architecture_ref: "dynamic-vespa-indexer-deal-updates"
---

# Real-Time Deal Update Indexing

## Summary

This flow keeps the Vespa search index current with real-time deal changes originating from Groupon's deal service. When a deal is created or updated, the deal service publishes a change event to the Groupon MessageBus. Vespa Indexer maintains a persistent STOMP subscription, receives these events, transforms the payload into a Vespa document, optionally enriches with ML features from BigQuery (for CREATE events), and writes the result to Vespa. The flow runs continuously in a background asyncio task for as long as the service is running.

## Trigger

- **Type**: event
- **Source**: Groupon MessageBus topic `jms.topic.mars.mds.genericchange` (STOMP broker: `mbus.production.service`)
- **Frequency**: Continuous — events are consumed as they arrive; no polling interval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MessageBus | Source of real-time deal change events | `messageBus` |
| Deal Update Listener | Background asyncio task that bootstraps the consume loop | `dealUpdateListener` |
| Consume Deal Updates Use Case | Orchestrates the update flow; routes to index or update | `consumeDealUpdatesUseCase` |
| Deal Update Adapter | Subscribes to MessageBus via STOMP; yields `DealOptionUpdate` objects | `dealUpdateAdapter` |
| MessageBus Deal Update Client | Low-level STOMP client with ACK/NACK support | `mbusDealUpdateClient` |
| BigQuery Deal Option Enricher | Fetches ML features for CREATE events | `bigQueryDealOptionEnricher` |
| BigQuery Client | Executes feature queries against BigQuery tables | `bigQueryClient` |
| Search Index Adapter | Transforms domain objects to Vespa document format and calls `VespaClient` | `searchIndexAdapter` |
| Vespa Client | Low-level pyvespa HTTP client | `vespaClient` |
| Vespa Cluster | Search engine that stores indexed documents | `vespaCluster` |

## Steps

1. **Start consume loop**: On application startup, `dealUpdateListener` starts `consumeDealUpdatesUseCase` as a background asyncio task.
   - From: `dealUpdateListener`
   - To: `consumeDealUpdatesUseCase`
   - Protocol: direct (Python asyncio)

2. **Subscribe to MessageBus**: `consumeDealUpdatesUseCase` calls `DealUpdateProvider.consume_updates()` on `dealUpdateAdapter`, which instructs `mbusDealUpdateClient` to subscribe to `jms.topic.mars.mds.genericchange` via STOMP.
   - From: `consumeDealUpdatesUseCase`
   - To: `dealUpdateAdapter` → `mbusDealUpdateClient`
   - Protocol: STOMP (stomp.py 8.2.0)

3. **Receive event**: MessageBus delivers a deal change event to `mbusDealUpdateClient`. The event payload includes `dealUuid`, `versionId`, `changes` (options array, distribution_region_codes, merchant name, etc.), and `source`.
   - From: `messageBus`
   - To: `mbusDealUpdateClient`
   - Protocol: STOMP

4. **Filter by region**: `dealUpdateAdapter` inspects `distribution_region_codes` in the event and discards messages whose regions are not in `allowed_distribution_regions` (default: `["US"]`).
   - From: `dealUpdateAdapter`
   - To: internal filter
   - Protocol: direct

5. **Parse message**: `dealUpdateAdapter` deserialises the STOMP message body and yields a `DealOption` (CREATE) or `DealOptionUpdate` (UPDATE) domain object.
   - From: `mbusDealUpdateClient`
   - To: `consumeDealUpdatesUseCase`
   - Protocol: direct (Python generator)

6. **Enrich with BigQuery features (CREATE only)**: For CREATE events, `consumeDealUpdatesUseCase` calls `bigQueryDealOptionEnricher.enrich()`, which queries BigQuery deal feature table, option feature table, and distance bucket table to attach ML signals to the domain object.
   - From: `consumeDealUpdatesUseCase`
   - To: `bigQueryDealOptionEnricher` → `bigQueryClient`
   - Protocol: BigQuery SDK

7. **Transform and write to Vespa**: `consumeDealUpdatesUseCase` calls `searchIndexAdapter.index_option()` (full create) or `update_option()` (partial update). `searchIndexAdapter` applies transformations (unicode cleaning, type coercion, `is_local`, `is_goods`, `option_duration_days` computation, `active` → `status` mapping) and calls `vespaClient.feed_document()` or `update_document()`.
   - From: `searchIndexAdapter`
   - To: `vespaClient` → `vespaCluster`
   - Protocol: HTTP (pyvespa)

8. **ACK message**: On successful indexing, `mbusDealUpdateClient` sends an ACK to the MessageBus broker. On failure, a NACK is sent, triggering broker-side redelivery.
   - From: `mbusDealUpdateClient`
   - To: `messageBus`
   - Protocol: STOMP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Message fails region filter | Silently discarded; message is ACKed | Document not indexed; no side effect |
| BigQuery feature query fails (CREATE) | Exception logged; indexing proceeds without ML features | Document indexed with empty feature fields |
| Vespa write fails | Exception logged; NACK sent to MessageBus | Broker redelivers message; retry occurs |
| MessageBus connection lost | `stomp.py` reconnect logic; background consumer loop restarts | Brief gap in real-time updates |
| Malformed message payload | Exception logged; NACK sent | Broker redelivers; persistent failures generate log noise |

## Sequence Diagram

```
dealUpdateListener -> consumeDealUpdatesUseCase: Starts consume loop
consumeDealUpdatesUseCase -> dealUpdateAdapter: consume_updates()
dealUpdateAdapter -> mbusDealUpdateClient: subscribe(jms.topic.mars.mds.genericchange)
messageBus -> mbusDealUpdateClient: STOMP message (deal change event)
mbusDealUpdateClient -> dealUpdateAdapter: raw message
dealUpdateAdapter -> dealUpdateAdapter: filter by distribution_region_codes
dealUpdateAdapter -> consumeDealUpdatesUseCase: DealOption / DealOptionUpdate
consumeDealUpdatesUseCase -> bigQueryDealOptionEnricher: enrich(option) [CREATE only]
bigQueryDealOptionEnricher -> bigQueryClient: query feature tables
bigQueryClient --> bigQueryDealOptionEnricher: feature rows
bigQueryDealOptionEnricher --> consumeDealUpdatesUseCase: enriched option
consumeDealUpdatesUseCase -> searchIndexAdapter: index_option() or update_option()
searchIndexAdapter -> vespaClient: feed_document() or update_document()
vespaClient -> vespaCluster: HTTP PUT/PATCH document
vespaCluster --> vespaClient: 200 OK
vespaClient --> searchIndexAdapter: success
searchIndexAdapter --> consumeDealUpdatesUseCase: success
mbusDealUpdateClient -> messageBus: ACK
```

## Related

- Architecture dynamic view: `dynamic-vespa-indexer-deal-updates`
- Related flows: [Scheduled Deal Refresh from Feed](scheduled-deal-refresh.md), [On-Demand Deal Indexing by UUID](on-demand-indexing.md)
