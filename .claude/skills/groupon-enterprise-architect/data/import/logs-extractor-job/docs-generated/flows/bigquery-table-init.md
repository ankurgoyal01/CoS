---
service: "logs-extractor-job"
title: "BigQuery Table Initialization"
generated: "2026-03-03"
type: flow
flow_name: "bigquery-table-init"
flow_type: batch
trigger: "Called by CLI Job Runner at the start of each run when ENABLE_BIGQUERY=true"
participants:
  - "continuumLogExtractorJob_bigQueryService"
  - "continuumLogExtractorBigQuery"
architecture_ref: "dynamic-hourly-log-extraction"
---

# BigQuery Table Initialization

## Summary

Before any log data is uploaded, the BigQuery Service verifies that the target dataset and all six tables exist in BigQuery. If the dataset is absent it is created in the `US` location. If any table is absent it is created using the schema defined in `src/schemas/bigQuerySchemas.js`, with DAY-level time partitioning on the `timestamp` field. A 10-second propagation wait is applied after each table creation to allow BigQuery to register the resource before verification.

## Trigger

- **Type**: batch (in-process function call)
- **Source**: `continuumLogExtractorJob_cliRunner` calls `bigQueryService.ensureAllTablesExist()` before the first upload
- **Frequency**: Once per job run, when `ENABLE_BIGQUERY=true`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BigQuery Service | Orchestrates dataset and table checks / creation | `continuumLogExtractorJob_bigQueryService` |
| Schema Definitions | Provides field schemas and table names | `continuumLogExtractorJob_schemaDefinitions` |
| BigQuery Dataset | Target dataset; created if absent | `continuumLogExtractorBigQuery` |

## Steps

1. **Check dataset existence**: Calls `dataset.exists()` on the configured `BQ_DATASET_ID`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

2. **Create dataset if missing**: If dataset does not exist, calls `client.createDataset(datasetId, { location: 'US' })`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

3. **Iterate over all table names**: Reads `Object.keys(bigQuerySchemas)` — the six tables: `pwa_logs`, `proxy_logs`, `lazlo_logs`, `orders_logs`, `bcookie_summary`, `combined_logs`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorJob_schemaDefinitions`
   - Protocol: module import

4. **Check table existence**: For each table, calls `table.exists()`.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

5. **Create table if missing**: If table does not exist, calls `dataset.createTable(tableName, { schema, timePartitioning: { type: 'DAY', field: 'timestamp' } })`. The `timePartitioning` option is only applied to tables that have a `timestamp` field in their schema.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

6. **Wait for propagation**: Waits 10,000ms after table creation for BigQuery to register the new table.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: (async timer)
   - Protocol: in-process

7. **Verify table exists**: Calls `table.exists()` again to confirm the table is accessible.
   - From: `continuumLogExtractorJob_bigQueryService`
   - To: `continuumLogExtractorBigQuery`
   - Protocol: BigQuery API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Dataset creation failure | Error logged; rethrown | Job exits with code 1 |
| Schema not found for a table name | Throws `Error('Schema not found for table ${tableName}')` | Job exits with code 1 |
| Table creation failure | Error logged; rethrown | Job exits with code 1 |
| Table not found after creation + wait | Throws `Error('Table was created but not found')` | Job exits with code 1 |

## Sequence Diagram

```
BigQueryService -> BigQuery: dataset.exists(BQ_DATASET_ID)
BigQuery --> BigQueryService: false
BigQueryService -> BigQuery: client.createDataset(BQ_DATASET_ID, {location: 'US'})
BigQueryService -> SchemaDefinitions: Object.keys(bigQuerySchemas)
loop for each tableName
  BigQueryService -> BigQuery: table.exists(tableName)
  BigQuery --> BigQueryService: false
  BigQueryService -> BigQuery: dataset.createTable(tableName, {schema, timePartitioning})
  BigQueryService -> BigQueryService: await sleep(10000ms)
  BigQueryService -> BigQuery: table.exists(tableName) [verify]
  BigQuery --> BigQueryService: true
end
BigQueryService --> CLIRunner: All tables ready
```

## Related

- Architecture dynamic view: `dynamic-hourly-log-extraction`
- Related flows: [Hourly Log Extraction and Load](hourly-log-extraction.md), [Log Transformation and BigQuery Upload](log-transform-bigquery-upload.md)
