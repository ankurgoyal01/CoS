---
service: "darwin-indexer"
title: "Logging and Validation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "logging-and-validation"
flow_type: event-driven
trigger: "Each indexing job run and each document write attempt"
participants:
  - "continuumDealIndexerService"
  - "continuumHotelOfferIndexerService"
architecture_ref: "dynamic-logging-and-validation"
---

# Logging and Validation

## Summary

The Logging and Validation flow describes the cross-cutting concerns that run throughout every indexing pipeline execution. Before writing each document to Elasticsearch, darwin-indexer validates the assembled document structure (required fields, data types, pricing via Joda-Money). It logs progress and errors throughout the pipeline using the Dropwizard/SLF4J logging framework. Run outcomes — success, partial failure, or full failure — are persisted to PostgreSQL for audit and operational visibility.

## Trigger

- **Type**: event-driven
- **Source**: Fired at each significant pipeline event: job start, batch enrichment completion, document validation, bulk write completion, job completion or failure
- **Frequency**: Continuous — occurs at every step of every indexing run

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Indexer Service | Performs document validation, structured logging, and run state recording for deal indexing | `continuumDealIndexerService` |
| Hotel Offer Indexer Service | Performs document validation, structured logging, and run state recording for hotel offer indexing | `continuumHotelOfferIndexerService` |

> PostgreSQL is also a participant (for run state recording) but is captured in [Data Stores](../data-stores.md) rather than as a named architecture container.

## Steps

1. **Logs job start**: On Quartz trigger, the indexing service logs a structured entry with job name, run type (full/incremental), run ID, and start timestamp.
   - From: `continuumDealIndexerService` / `continuumHotelOfferIndexerService`
   - To: Log output (SLF4J / Logback via Dropwizard)
   - Protocol: internal / in-process

2. **Records run state as started in PostgreSQL**: Inserts a run state record into PostgreSQL with status "STARTED" to enable operational tracking and crash detection.
   - From: Indexer service
   - To: PostgreSQL
   - Protocol: JDBC

3. **Validates each assembled document**: Before each document is queued for bulk write, validates required fields (e.g., deal ID, title, pricing fields via Joda-Money), data type constraints, and enrichment completeness.
   - From: Indexer service (internal validation step)
   - To: In-process document model
   - Protocol: internal / in-process

4. **Logs validation failures**: For any document that fails validation, logs a structured warning or error entry including the document ID, the failed field(s), and the source data that caused the failure.
   - From: Indexer service
   - To: Log output (SLF4J)
   - Protocol: internal / in-process

5. **Logs bulk write outcomes**: After each Elasticsearch bulk write call, logs the number of documents accepted, the number of per-document errors from the bulk response, and any partial failure details.
   - From: Indexer service
   - To: Log output (SLF4J)
   - Protocol: internal / in-process

6. **Logs enrichment errors**: If a REST call to an upstream service fails or returns unexpected data during enrichment, a structured error is logged with the upstream service name, HTTP status, and affected deal/offer IDs.
   - From: Indexer service
   - To: Log output (SLF4J)
   - Protocol: internal / in-process

7. **Logs job completion or failure**: On job end, logs the final run outcome with total documents processed, total documents indexed, validation failure count, and elapsed duration.
   - From: Indexer service
   - To: Log output (SLF4J)
   - Protocol: internal / in-process

8. **Updates run state in PostgreSQL**: Updates the run state record to "COMPLETED" or "FAILED" with a final document count, error summary, and end timestamp.
   - From: Indexer service
   - To: PostgreSQL
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Document fails validation | Document skipped; warning logged with document ID and field details | Invalid document not written to Elasticsearch; indexing continues for remaining documents |
| Log output fails (disk full, logging backend down) | JVM-level logging error; may propagate or be silently dropped depending on Logback config | Log data lost; service may continue or crash depending on severity |
| PostgreSQL run state write fails | Exception logged; run continues if non-fatal | Run state not persisted; operator cannot determine run outcome from database; service may continue indexing |
| Upstream service returns malformed response | Parsing exception caught; document assembled with partial data or skipped | Partial enrichment or skip, logged with details; Elasticsearch document may be incomplete |

## Sequence Diagram

```
Quartz -> IndexerService: Fire job
IndexerService -> Logger: Log job started (job name, run type, run ID)
IndexerService -> PostgreSQL: INSERT run_state (STARTED)
IndexerService -> IndexerService: Fetch and enrich documents
IndexerService -> Logger: Log enrichment errors (if any)
IndexerService -> Validator: Validate assembled document
Validator --> IndexerService: Valid / Invalid
IndexerService -> Logger: Log validation failure (if invalid, with field details)
IndexerService -> ElasticsearchCluster: POST /_bulk
ElasticsearchCluster --> IndexerService: Bulk response (accepted / per-doc errors)
IndexerService -> Logger: Log bulk write outcome (accepted count, error count)
IndexerService -> Logger: Log job completed/failed (totals, duration)
IndexerService -> PostgreSQL: UPDATE run_state (COMPLETED / FAILED)
```

## Related

- Architecture dynamic view: `dynamic-logging-and-validation`
- Related flows: [Deal Indexing Pipeline](deal-indexing-pipeline.md), [Hotel Offer Indexing](hotel-offer-indexing.md), [Metrics Export](metrics-export.md)
