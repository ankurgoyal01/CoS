---
service: "relevance-service"
title: "Elasticsearch Index Rebuild"
generated: "2026-03-03"
type: flow
flow_name: "elasticsearch-index-rebuild"
flow_type: batch
trigger: "Scheduled job or manual trigger for index refresh"
participants:
  - "relevance_indexer"
  - "edw"
  - "continuumFeynmanSearch"
architecture_ref: "dynamic-relevance-indexer"
---

# Elasticsearch Index Rebuild

## Summary

This flow describes how the Indexer component within RAPI builds and refreshes the Elasticsearch indexes that power Feynman Search. The Indexer reads deal data and associated metadata from the Enterprise Data Warehouse (EDW) in batch, transforms it into search-optimized documents, and bulk-indexes them into the Feynman Search Elasticsearch cluster. This process ensures that search results reflect the latest deal catalog state, pricing, and availability.

## Trigger

- **Type**: schedule / manual
- **Source**: Scheduled batch job (cron) or manual trigger via operations tooling
- **Frequency**: Daily (or as configured); can be triggered on-demand for emergency reindexing

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Indexer | Reads source data from EDW, transforms it, and writes to Elasticsearch | `relevance_indexer` |
| Enterprise Data Warehouse (EDW) | Source of deal data, metadata, and attributes for index building | `edw` |
| Feynman Search (Elasticsearch) | Target Elasticsearch cluster receiving the indexed documents | `continuumFeynmanSearch` |

## Steps

1. **Trigger Index Build**: The Indexer process starts via a scheduled job (cron) or manual invocation. It initializes a new index build session.
   - From: Scheduler / Operator
   - To: `relevance_indexer`
   - Protocol: Scheduled / manual

2. **Read Source Data from EDW**: The Indexer connects to the Enterprise Data Warehouse and reads deal data in batch. This includes deal metadata, pricing, categories, locations, merchant information, and availability status.
   - From: `relevance_indexer`
   - To: `edw`
   - Protocol: Batch

3. **Transform Data**: The Indexer transforms raw EDW data into Elasticsearch-optimized documents. This includes flattening nested structures, computing derived fields, building geo-point representations, and applying index mappings.
   - From: `relevance_indexer`
   - To: (internal computation)
   - Protocol: Internal

4. **Bulk Index to Elasticsearch**: The Indexer writes transformed documents to the Feynman Search Elasticsearch cluster using the bulk indexing API. This may use a blue-green index strategy (build new index, then swap alias) to avoid serving partial data.
   - From: `relevance_indexer`
   - To: `continuumFeynmanSearch`
   - Protocol: REST (Elasticsearch Bulk API)

5. **Verify and Swap**: After indexing completes, the Indexer verifies document counts and index health, then swaps the Elasticsearch alias to point to the newly built index. The previous index is retained for rollback.
   - From: `relevance_indexer`
   - To: `continuumFeynmanSearch`
   - Protocol: REST (Elasticsearch Alias API)

6. **Report Completion**: The Indexer records the build timestamp and metrics (duration, document count, errors) for monitoring.
   - From: `relevance_indexer`
   - To: Monitoring / metrics system
   - Protocol: Metrics push

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| EDW connection failure | Retry with exponential backoff; abort after max retries | Index build fails; existing index continues serving |
| Partial data read from EDW | Abort build to avoid serving incomplete index | Existing index continues serving; alert raised |
| Elasticsearch bulk indexing errors | Log failed documents; retry batch; abort if error rate exceeds threshold | Partial index may be discarded; existing index continues serving |
| Elasticsearch cluster full (disk) | Abort indexing; alert infrastructure team | Existing index continues serving; capacity action required |
| Index alias swap failure | Retry swap; manual intervention if persistent | New index built but not serving; old index continues |

## Sequence Diagram

```
Scheduler -> Indexer: Trigger index build
Indexer -> EDW: Read deal data (Batch)
EDW --> Indexer: Deal data batch
Indexer -> Indexer: Transform data to ES documents
Indexer -> Feynman Search (ES): Bulk index documents (REST)
Feynman Search (ES) --> Indexer: Bulk index response
Indexer -> Feynman Search (ES): Swap index alias (REST)
Feynman Search (ES) --> Indexer: Alias swap confirmation
Indexer -> Monitoring: Report completion metrics
```

## Related

- Architecture dynamic view: `dynamic-relevance-indexer`
- Related flows: [Search Query Processing](search-query-processing.md), [Relevance Scoring](relevance-scoring.md)
