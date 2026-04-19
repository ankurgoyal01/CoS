---
service: "darwin-indexer"
title: "Index Alias Switchover"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "index-alias-switchover"
flow_type: batch
trigger: "Completion of a full index rebuild (deal or hotel offer)"
participants:
  - "continuumDealIndexerService"
  - "continuumHotelOfferIndexerService"
  - "elasticsearchCluster"
architecture_ref: "dynamic-index-alias-switchover"
---

# Index Alias Switchover

## Summary

The Index Alias Switchover flow enables zero-downtime index rebuilds by implementing a blue/green pattern against Elasticsearch aliases. When a full index rebuild completes successfully, the indexer atomically removes the read alias from the old (blue) index and assigns it to the new (green) index in a single Elasticsearch alias update request. Search consumers query the alias — not the physical index — so they transparently begin reading from the new index without any service restart or downtime.

## Trigger

- **Type**: event (internal — triggered programmatically at the end of a successful full rebuild job)
- **Source**: `continuumDealIndexerService` or `continuumHotelOfferIndexerService` after confirming all documents have been bulk-written to the new index
- **Frequency**: Once per full index rebuild cycle (deal or hotel offer)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Indexer Service | Initiates alias switchover after a full deal index rebuild | `continuumDealIndexerService` |
| Hotel Offer Indexer Service | Initiates alias switchover after a full hotel offer index rebuild | `continuumHotelOfferIndexerService` |
| Elasticsearch Cluster | Executes the atomic alias update; hosts both old and new indexes during switchover | `elasticsearchCluster` |

## Steps

1. **Verifies new index is complete**: Confirms all bulk-write batches for the current full rebuild have been submitted and acknowledged by Elasticsearch with no critical errors.
   - From: `continuumDealIndexerService` or `continuumHotelOfferIndexerService`
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP (index stats / document count check)

2. **Identifies current alias target**: Queries Elasticsearch to determine which physical index the read alias currently points to (the "blue" index).
   - From: Indexer service
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP (`GET /_alias/{alias-name}`)

3. **Executes atomic alias update**: Issues a single Elasticsearch `POST /_aliases` request that simultaneously removes the alias from the old index and adds it to the new index. This operation is atomic from the search consumer's perspective.
   - From: Indexer service
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP (`POST /_aliases` with `add` and `remove` actions)

4. **Confirms alias points to new index**: Verifies the alias now resolves to the new index by querying Elasticsearch alias state.
   - From: Indexer service
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP (`GET /_alias/{alias-name}`)

5. **Deletes old index (optional / deferred)**: Removes the old physical index from Elasticsearch to free cluster storage. This may be deferred or skipped based on configuration.
   - From: Indexer service
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP (`DELETE /{old-index-name}`)

6. **Records switchover in run state**: Updates PostgreSQL run metadata to record the successful alias switchover including old index name, new index name, and timestamp.
   - From: Indexer service
   - To: PostgreSQL
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| New index document count below threshold | Switchover aborted; old index remains live | Stale but complete index continues serving; operator alerted; new index left in place for inspection |
| Elasticsearch alias update request fails | Exception logged; switchover marked as failed in PostgreSQL | Old index continues serving; new index orphaned; operator must manually execute switchover or trigger another rebuild |
| Alias already pointing to new index (idempotent re-run) | Alias update is a no-op; no error | Correct state maintained |
| Old index deletion fails | Logged as warning; switchover considered successful | Old index remains in Elasticsearch; cluster storage not freed; operator should clean up manually |

## Sequence Diagram

```
IndexerService -> ElasticsearchCluster: GET /_cat/count/{new-index} (verify completeness)
ElasticsearchCluster --> IndexerService: Document count
IndexerService -> ElasticsearchCluster: GET /_alias/{alias-name} (identify current target)
ElasticsearchCluster --> IndexerService: Current alias -> old-index mapping
IndexerService -> ElasticsearchCluster: POST /_aliases { remove: old-index, add: new-index }
ElasticsearchCluster --> IndexerService: 200 OK (atomic switchover complete)
IndexerService -> ElasticsearchCluster: GET /_alias/{alias-name} (confirm)
ElasticsearchCluster --> IndexerService: alias -> new-index confirmed
IndexerService -> ElasticsearchCluster: DELETE /{old-index-name} (optional)
IndexerService -> PostgreSQL: Update run state with switchover details
```

## Related

- Architecture dynamic view: `dynamic-index-alias-switchover`
- Related flows: [Deal Indexing Pipeline](deal-indexing-pipeline.md), [Hotel Offer Indexing](hotel-offer-indexing.md)
