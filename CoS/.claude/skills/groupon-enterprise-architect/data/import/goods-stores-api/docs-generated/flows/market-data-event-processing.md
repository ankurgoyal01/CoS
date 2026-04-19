---
service: "goods-stores-api"
title: "Market Data Event Processing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "market-data-event-processing"
flow_type: event-driven
trigger: "JMS marketData topic message from Message Bus"
participants:
  - "messageBus"
  - "continuumGoodsStoresMessageBusConsumer"
  - "continuumGoodsStoresMessageBusConsumer_marketDataHandler"
  - "continuumGoodsStoresMessageBusConsumer_baseHandler"
  - "continuumGoodsStoresRedis"
  - "continuumGoodsStoresWorkers"
  - "continuumGoodsStoresWorkers_postProcessors"
  - "continuumGoodsStoresWorkers_elasticsearchIndexer"
  - "continuumGoodsStoresDb"
  - "continuumGoodsStoresElasticsearch"
architecture_ref: "dynamic-goods-stores-market-data-event-processing"
---

# Market Data Event Processing

## Summary

This flow describes how the Goods Stores service reacts to market data change events published on the `marketData` JMS topic. The `continuumGoodsStoresMessageBusConsumer` swarm process receives the event, applies telemetry and latency checks via the base handler, then the Market Data Handler flags the affected products for review and enqueues post-processing Resque jobs. Workers then run the post-processing pipeline, update MySQL, and re-index the affected records in Elasticsearch.

## Trigger

- **Type**: event
- **Source**: `marketData` JMS topic on `messageBus`
- **Frequency**: Continuous; driven by upstream market data change frequency

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Source of marketData topic events | `messageBus` |
| Event Handler Base | Provides telemetry, latency detection, and logging for all handlers | `continuumGoodsStoresMessageBusConsumer_baseHandler` |
| Market Data Updated Handler | Consumes event; flags products; enqueues post-processing | `continuumGoodsStoresMessageBusConsumer_marketDataHandler` |
| Goods Stores Redis | Tracks batching state; receives Resque job enqueue | `continuumGoodsStoresRedis` |
| Goods Stores Workers — Post-Processors | Runs product post-processing pipeline | `continuumGoodsStoresWorkers_postProcessors` |
| Goods Stores Workers — Elasticsearch Indexer | Re-indexes affected product documents | `continuumGoodsStoresWorkers_elasticsearchIndexer` |
| Goods Stores MySQL | Updated with flagged product state | `continuumGoodsStoresDb` |
| Goods Stores Elasticsearch | Receives re-indexed product documents | `continuumGoodsStoresElasticsearch` |

## Steps

1. **Receive Market Data Event**: `continuumGoodsStoresMessageBusConsumer` swarm receives a message from the `marketData` JMS topic via the MessageBus broker.
   - From: `messageBus`
   - To: `continuumGoodsStoresMessageBusConsumer`
   - Protocol: JMS/STOMP

2. **Apply Base Handler Telemetry**: `continuumGoodsStoresMessageBusConsumer_baseHandler` records receipt timestamp, measures latency against message creation time, and emits telemetry metrics.
   - From: `continuumGoodsStoresMessageBusConsumer_baseHandler`
   - To: `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
   - Protocol: direct (in-process)

3. **Identify Affected Products**: Market Data Handler parses the event payload to extract affected product/merchant identifiers.
   - From: `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
   - To: in-process
   - Protocol: direct

4. **Check Batching State**: Handler checks Redis for existing batch state to avoid redundant processing of rapid successive events for the same product.
   - From: `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Redis

5. **Flag Products for Review**: Handler marks affected products as needing review in the batching state.
   - From: `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Redis

6. **Enqueue Post-Processing Jobs**: Handler enqueues `continuumGoodsStoresWorkers_postProcessors` Resque jobs for each affected product.
   - From: `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

7. **Run Post-Processing Pipeline**: Workers dequeue jobs and run PostProcessors (inventory, fulfillment, images, merchant attributes, options); update MySQL with derived state.
   - From: `continuumGoodsStoresWorkers_postProcessors`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

8. **Trigger Re-Index**: Post-Processors trigger `continuumGoodsStoresWorkers_elasticsearchIndexer` to re-index affected records.
   - From: `continuumGoodsStoresWorkers_postProcessors`
   - To: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - Protocol: direct (Resque dispatch)

9. **Update Elasticsearch**: Elasticsearch Indexer writes updated product documents to `continuumGoodsStoresElasticsearch`.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: `continuumGoodsStoresElasticsearch`
   - Protocol: Elasticsearch client

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MessageBus connectivity lost | Consumer swarm reconnects; no messages processed while disconnected | Events may be delayed; broker retains unacknowledged messages |
| Latency threshold exceeded | `continuumGoodsStoresMessageBusConsumer_baseHandler` emits latency alert metric | Event still processed; alert triggers monitoring |
| Redis batching state unavailable | Batching check fails; event processing may be skipped or duplicated | Post-processing may not run; manual re-trigger may be required |
| Resque enqueue failure | Handler logs error; event may not result in post-processing | Products may remain stale; no automatic recovery identified |
| Post-processor job failure | Resque retries job per retry policy | Product state and search index remain stale until retry succeeds |
| Elasticsearch indexing failure | Indexing worker retries with logging | Search results may be stale |

## Sequence Diagram

```
messageBus -> continuumGoodsStoresMessageBusConsumer: marketData topic message (JMS/STOMP)
continuumGoodsStoresMessageBusConsumer_baseHandler -> continuumGoodsStoresMessageBusConsumer_marketDataHandler: Provide telemetry and latency check
continuumGoodsStoresMessageBusConsumer_marketDataHandler -> continuumGoodsStoresRedis: Check and update batching state
continuumGoodsStoresMessageBusConsumer_marketDataHandler -> continuumGoodsStoresRedis: Enqueue post-processing Resque job
continuumGoodsStoresWorkers_postProcessors -> continuumGoodsStoresDb: Run post-processing pipeline
continuumGoodsStoresWorkers_postProcessors -> continuumGoodsStoresWorkers_elasticsearchIndexer: Trigger re-index
continuumGoodsStoresWorkers_elasticsearchIndexer -> continuumGoodsStoresElasticsearch: Index updated product documents
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-market-data-event-processing`
- Related flows: [Elasticsearch Indexing](elasticsearch-indexing.md), [Product Create/Update & Sync](product-create-update-sync.md)
