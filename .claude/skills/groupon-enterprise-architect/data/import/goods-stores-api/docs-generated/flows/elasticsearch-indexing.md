---
service: "goods-stores-api"
title: "Elasticsearch Indexing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "elasticsearch-indexing"
flow_type: asynchronous
trigger: "Resque job enqueue following a domain change (API write, post-processor completion, or market data event)"
participants:
  - "continuumGoodsStoresWorkers"
  - "continuumGoodsStoresWorkers_resqueJobs"
  - "continuumGoodsStoresWorkers_elasticsearchIndexer"
  - "continuumGoodsStoresWorkers_postProcessors"
  - "continuumGoodsStoresRedis"
  - "continuumGoodsStoresDb"
  - "continuumGoodsStoresElasticsearch"
architecture_ref: "dynamic-goods-stores-elasticsearch-indexing"
---

# Elasticsearch Indexing

## Summary

The Elasticsearch Indexing flow ensures that goods records remain current in the `continuumGoodsStoresElasticsearch` search index after any domain change. The `continuumGoodsStoresWorkers_elasticsearchIndexer` component is triggered by the Resque Worker Pool following API writes, post-processor completions, or market data event processing. It reads the authoritative record from MySQL and writes the document to Elasticsearch, with retry and logging support for index failures.

## Trigger

- **Type**: event (Resque job dequeue)
- **Source**: Enqueued by `continuumGoodsStoresApi_v2Api`, `continuumGoodsStoresWorkers_postProcessors`, or `continuumGoodsStoresMessageBusConsumer_marketDataHandler`
- **Frequency**: On-demand following any product or agreement domain change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Resque Worker Pool | Dispatches indexing jobs to the Elasticsearch Indexer | `continuumGoodsStoresWorkers_resqueJobs` |
| Elasticsearch Indexing Worker | Reads record from MySQL; writes document to Elasticsearch | `continuumGoodsStoresWorkers_elasticsearchIndexer` |
| Post-Processors | May trigger re-index as part of post-processing pipeline | `continuumGoodsStoresWorkers_postProcessors` |
| Goods Stores Redis | Provides Resque job queue | `continuumGoodsStoresRedis` |
| Goods Stores MySQL | Authoritative source for the record being indexed | `continuumGoodsStoresDb` |
| Goods Stores Elasticsearch | Receives indexed documents | `continuumGoodsStoresElasticsearch` |

## Steps

1. **Job Enqueued**: An indexing Resque job is placed onto the queue in `continuumGoodsStoresRedis` by a triggering component (API, post-processor, or market data handler).
   - From: triggering component (`continuumGoodsStoresApi_v2Api`, `continuumGoodsStoresWorkers_postProcessors`, or `continuumGoodsStoresMessageBusConsumer_marketDataHandler`)
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

2. **Dequeue Indexing Job**: `continuumGoodsStoresWorkers_resqueJobs` dequeues the indexing job and dispatches it to `continuumGoodsStoresWorkers_elasticsearchIndexer`.
   - From: `continuumGoodsStoresWorkers_resqueJobs`
   - To: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - Protocol: direct (Resque dispatch)

3. **Read Authoritative Record**: Indexer fetches the current state of the product or agreement from MySQL.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

4. **Build Index Document**: Indexer constructs the Elasticsearch document from the fetched record, applying field mappings and analyzers appropriate to the index schema.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: in-process
   - Protocol: direct

5. **Write to Elasticsearch**: Indexer sends the document to `continuumGoodsStoresElasticsearch` via the Elasticsearch client.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: `continuumGoodsStoresElasticsearch`
   - Protocol: Elasticsearch client

6. **Validate Index Result**: Indexer checks the response to confirm the document was accepted; logs success or failure with correlation identifiers.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: logging output
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL read failure | Job fails; Resque retries per retry policy | Indexing delayed until retry succeeds |
| Elasticsearch write failure | Job fails with logged error; Resque retries | Search index temporarily stale |
| Elasticsearch cluster unavailable | All indexing jobs fail and queue up | Search results stale until cluster recovers and jobs retry |
| Document schema mismatch | Indexer logs error; job may fail or skip field | Partial document indexed; fields may be missing in search |
| Repeated job failure | Job moves to failed queue after max retries | Manual re-trigger required; search results remain stale |

## Sequence Diagram

```
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresRedis: Enqueue indexing Resque job
continuumGoodsStoresWorkers_resqueJobs -> continuumGoodsStoresWorkers_elasticsearchIndexer: Dispatch indexing job
continuumGoodsStoresWorkers_elasticsearchIndexer -> continuumGoodsStoresDb: Read authoritative record (ActiveRecord)
continuumGoodsStoresDb --> continuumGoodsStoresWorkers_elasticsearchIndexer: Record data
continuumGoodsStoresWorkers_elasticsearchIndexer -> continuumGoodsStoresElasticsearch: Write index document
continuumGoodsStoresElasticsearch --> continuumGoodsStoresWorkers_elasticsearchIndexer: Index acknowledgement
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-elasticsearch-indexing`
- Related flows: [Product Create/Update & Sync](product-create-update-sync.md), [Market Data Event Processing](market-data-event-processing.md), [Search Query Execution](search-query-execution.md)
