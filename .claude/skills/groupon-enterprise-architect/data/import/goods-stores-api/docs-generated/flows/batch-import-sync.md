---
service: "goods-stores-api"
title: "Batch Import/Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "batch-import-sync"
flow_type: batch
trigger: "Scheduled Resque job or manual trigger"
participants:
  - "continuumGoodsStoresWorkers"
  - "continuumGoodsStoresWorkers_resqueJobs"
  - "continuumGoodsStoresWorkers_batch"
  - "continuumGoodsStoresWorkers_elasticsearchIndexer"
  - "continuumGoodsStoresRedis"
  - "continuumGoodsStoresDb"
  - "continuumGoodsStoresS3"
  - "continuumDealCatalogService"
  - "continuumGoodsInventoryService"
architecture_ref: "dynamic-goods-stores-batch-import-sync"
---

# Batch Import/Sync

## Summary

The Batch Import/Sync flow covers the scheduled and manual execution of bulk data operations for the goods domain. The `continuumGoodsStoresWorkers_batch` component handles CSV/SFTP imports, DMAPI sync jobs, feature flag backfills, and HTS mapping updates. Batch jobs read from or write to MySQL, export files to S3, and may trigger downstream syncs with the Deal Catalog and Goods Inventory service, followed by Elasticsearch re-indexing of affected records.

## Trigger

- **Type**: schedule or manual
- **Source**: Scheduled Resque job (configured cadence per job type) or manual Resque job submission via rake task or Resque UI
- **Frequency**: Per job type — typically daily for scheduled jobs; on-demand for manual backfills

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Resque Worker Pool | Dequeues and dispatches batch jobs | `continuumGoodsStoresWorkers_resqueJobs` |
| Batch Import/Export Jobs | Executes bulk import, export, and backfill operations | `continuumGoodsStoresWorkers_batch` |
| Elasticsearch Indexing Worker | Re-indexes records affected by batch operations | `continuumGoodsStoresWorkers_elasticsearchIndexer` |
| Goods Stores Redis | Provides Resque job queue and job coordination state | `continuumGoodsStoresRedis` |
| Goods Stores MySQL | Source and destination for batch data reads and writes | `continuumGoodsStoresDb` |
| Goods Stores S3 Bucket | Source for CSV/SFTP import files; destination for export files | `continuumGoodsStoresS3` |
| Deal Catalog Service | Receives synced deal nodes and variants from DMAPI sync jobs | `continuumDealCatalogService` |
| Goods Inventory Service | Receives inventory state updates for batch-modified products | `continuumGoodsInventoryService` |

## Steps

1. **Job Scheduled or Triggered**: Resque job is placed on the batch queue either by the scheduler or manually via rake task / Resque UI.
   - From: scheduler or operator
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

2. **Dequeue and Dispatch**: Resque Worker Pool dequeues the batch job and dispatches to `continuumGoodsStoresWorkers_batch`.
   - From: `continuumGoodsStoresWorkers_resqueJobs`
   - To: `continuumGoodsStoresWorkers_batch`
   - Protocol: direct (Resque dispatch)

3. **Read Source Data**: Batch job reads input from the appropriate source — CSV/SFTP file from `continuumGoodsStoresS3`, MySQL query against `continuumGoodsStoresDb`, or API call for DMAPI sync.
   - From: `continuumGoodsStoresWorkers_batch`
   - To: `continuumGoodsStoresS3` or `continuumGoodsStoresDb`
   - Protocol: S3 API or ActiveRecord/MySQL

4. **Process and Mutate Records**: Batch job applies bulk mutations to goods records in MySQL (imports, backfills, feature flag updates, HTS mapping changes).
   - From: `continuumGoodsStoresWorkers_batch`
   - To: `continuumGoodsStoresDb`
   - Protocol: ActiveRecord/MySQL

5. **Export Results (if applicable)**: For export jobs, batch worker writes output files (CSV/SFTP) to `continuumGoodsStoresS3`.
   - From: `continuumGoodsStoresWorkers_batch`
   - To: `continuumGoodsStoresS3`
   - Protocol: S3 API

6. **Sync to Deal Catalog (DMAPI jobs)**: For DMAPI sync batch jobs, worker calls Deal Catalog service to synchronize deal nodes and variants for the affected products.
   - From: `continuumGoodsStoresWorkers_batch`
   - To: `continuumDealCatalogService`
   - Protocol: SchemaDrivenClient/HTTP

7. **Update Goods Inventory**: Worker publishes inventory state updates for batch-modified products to `continuumGoodsInventoryService`.
   - From: `continuumGoodsStoresWorkers`
   - To: `continuumGoodsInventoryService`
   - Protocol: HTTP/JSON

8. **Trigger Elasticsearch Re-Index**: Batch worker enqueues Elasticsearch indexing jobs for all records mutated during the batch run.
   - From: `continuumGoodsStoresWorkers_batch`
   - To: `continuumGoodsStoresRedis`
   - Protocol: Resque over Redis

9. **Index Updated Records**: `continuumGoodsStoresWorkers_elasticsearchIndexer` processes indexing jobs and updates `continuumGoodsStoresElasticsearch`.
   - From: `continuumGoodsStoresWorkers_elasticsearchIndexer`
   - To: `continuumGoodsStoresElasticsearch`
   - Protocol: Elasticsearch client

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| S3 read failure | Job fails; Resque retries | Batch import delayed |
| MySQL write failure during batch | Job fails mid-run; Resque retries from beginning | Partial mutations may occur; idempotency of batch jobs should be verified by service owner |
| Deal Catalog sync failure | Worker retries | Deal Catalog may have stale data |
| Goods Inventory update failure | Worker retries | Inventory state may be stale |
| Elasticsearch indexing backlog | Indexing jobs queue up; processed as workers are available | Search results stale until queue clears |
| Manual job submitted incorrectly | Job fails with validation error; logged to Resque failed queue | No data mutation; operator must correct and resubmit |

## Sequence Diagram

```
Scheduler / Operator -> continuumGoodsStoresRedis: Enqueue batch Resque job
continuumGoodsStoresWorkers_resqueJobs -> continuumGoodsStoresWorkers_batch: Dispatch batch job
continuumGoodsStoresWorkers_batch -> continuumGoodsStoresS3: Read CSV/SFTP import file (S3 API)
continuumGoodsStoresWorkers_batch -> continuumGoodsStoresDb: Bulk mutate records (ActiveRecord)
continuumGoodsStoresWorkers_batch -> continuumGoodsStoresS3: Write export file (S3 API)
continuumGoodsStoresWorkers_batch -> continuumDealCatalogService: Sync deal nodes/variants (HTTP)
continuumGoodsStoresWorkers -> continuumGoodsInventoryService: Publish inventory updates (HTTP)
continuumGoodsStoresWorkers_batch -> continuumGoodsStoresRedis: Enqueue Elasticsearch indexing jobs
continuumGoodsStoresWorkers_elasticsearchIndexer -> continuumGoodsStoresElasticsearch: Re-index affected records
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-batch-import-sync`
- Related flows: [Elasticsearch Indexing](elasticsearch-indexing.md), [Contract Lifecycle](contract-lifecycle.md), [Product Create/Update & Sync](product-create-update-sync.md)
