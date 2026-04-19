---
service: "darwin-indexer"
title: "Hotel Offer Indexing"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "hotel-offer-indexing"
flow_type: scheduled
trigger: "Quartz cron schedule (full rebuild or incremental delta)"
participants:
  - "continuumHotelOfferIndexerService"
  - "hotelOfferCatalogService"
  - "continuumTaxonomyService"
  - "elasticsearchCluster"
architecture_ref: "dynamic-hotel-offer-indexing"
---

# Hotel Offer Indexing

## Summary

The Hotel Offer Indexing flow runs on a Quartz schedule within the `continuumHotelOfferIndexerService`. It fetches hotel offer records from the Hotel Offer Catalog, enriches them with taxonomy data from the Taxonomy Service, assembles fully-denormalized hotel offer Elasticsearch documents, and bulk-writes them to the hotel offer index. On full rebuilds, it triggers an alias switchover to make the new index live.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (cron expression configured in `config.yml` for the Hotel Offer Indexer Service)
- **Frequency**: Periodic — full rebuild and incremental delta cadences configured per environment

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotel Offer Indexer Service | Orchestrates hotel offer indexing; fetches, enriches, and writes documents | `continuumHotelOfferIndexerService` |
| Hotel Offer Catalog Service | Provides source hotel offer records | `hotelOfferCatalogService` |
| Taxonomy Service | Provides taxonomy and category enrichment for hotel offers | `continuumTaxonomyService` |
| Elasticsearch Cluster | Receives bulk-written enriched hotel offer documents | `elasticsearchCluster` |

## Steps

1. **Schedule triggers job**: Quartz fires the hotel offer indexing job (full rebuild or incremental delta).
   - From: Quartz scheduler (internal to `continuumHotelOfferIndexerService`)
   - To: `continuumHotelOfferIndexerService` indexing job handler
   - Protocol: internal / in-process

2. **Reads last offset (incremental only)**: For incremental runs, reads the last processed offset from PostgreSQL to determine which hotel offers to fetch.
   - From: `continuumHotelOfferIndexerService`
   - To: PostgreSQL
   - Protocol: JDBC

3. **Fetches hotel offer records**: Requests hotel offer records in scope from the Hotel Offer Catalog Service.
   - From: `continuumHotelOfferIndexerService`
   - To: `hotelOfferCatalogService`
   - Protocol: REST (Retrofit2 HTTP client)

4. **Fetches taxonomy enrichment data**: For each hotel offer, fetches taxonomy and category data from the Taxonomy Service to enrich the document.
   - From: `continuumHotelOfferIndexerService`
   - To: `continuumTaxonomyService`
   - Protocol: REST (Retrofit2 HTTP client)

5. **Assembles enriched hotel offer document**: Merges hotel offer record with taxonomy data into a fully-denormalized Elasticsearch document using Jackson serialization. Applies Joda-Money for pricing normalization.
   - From: `continuumHotelOfferIndexerService` (internal merge step)
   - To: `continuumHotelOfferIndexerService` (document buffer)
   - Protocol: internal / in-process

6. **Bulk-writes documents to Elasticsearch**: Sends accumulated enriched hotel offer documents to the Elasticsearch hotel offer index via the Bulk API.
   - From: `continuumHotelOfferIndexerService`
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP / transport

7. **Updates run state and offset in PostgreSQL**: Records the completed run metadata and updates the incremental offset for the next run.
   - From: `continuumHotelOfferIndexerService`
   - To: PostgreSQL
   - Protocol: JDBC

8. **Triggers alias switchover (full rebuild only)**: On completion of a full hotel offer index rebuild, atomically switches the Elasticsearch alias to the new index.
   - From: `continuumHotelOfferIndexerService`
   - To: `elasticsearchCluster`
   - Protocol: Elasticsearch HTTP
   - See: [Index Alias Switchover](index-alias-switchover.md)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Hotel Offer Catalog unavailable | Exception thrown; job marks run as failed | Indexing run aborted; previous hotel offer index remains live; next scheduled run retries |
| Taxonomy Service unavailable | Exception thrown or enrichment skipped (implementation-dependent) | Hotel offers indexed without taxonomy enrichment, or run aborted |
| Elasticsearch bulk write failure | Bulk API response inspected; per-document errors logged | Successfully written documents indexed; failed documents skipped; operator alerted |
| PostgreSQL unavailable | Cannot read/write run state or offset | Incremental offset cannot be determined; may fall back to full rebuild or abort |

## Sequence Diagram

```
Quartz -> HotelOfferIndexerService: Fire scheduled job
HotelOfferIndexerService -> PostgreSQL: Read last offset (incremental)
HotelOfferIndexerService -> HotelOfferCatalogService: GET /hotel-offers?since={offset}
HotelOfferCatalogService --> HotelOfferIndexerService: Hotel offer records
HotelOfferIndexerService -> TaxonomyService: GET /taxonomy/{ids}
TaxonomyService --> HotelOfferIndexerService: Taxonomy data
HotelOfferIndexerService -> HotelOfferIndexerService: Merge and assemble document
HotelOfferIndexerService -> ElasticsearchCluster: POST /_bulk (enriched hotel offer documents)
ElasticsearchCluster --> HotelOfferIndexerService: Bulk response
HotelOfferIndexerService -> PostgreSQL: Update run state and offset
HotelOfferIndexerService -> ElasticsearchCluster: POST /_aliases (switchover, full rebuild only)
```

## Related

- Architecture dynamic view: `dynamic-hotel-offer-indexing`
- Related flows: [Deal Indexing Pipeline](deal-indexing-pipeline.md), [Index Alias Switchover](index-alias-switchover.md), [Logging and Validation](logging-and-validation.md)
