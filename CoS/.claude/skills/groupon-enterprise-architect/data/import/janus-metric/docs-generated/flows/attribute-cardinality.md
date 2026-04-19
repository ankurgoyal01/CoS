---
service: "janus-metric"
title: "Attribute Cardinality Computation"
generated: "2026-03-03"
type: flow
flow_name: "attribute-cardinality"
flow_type: batch
trigger: "Airflow weekly schedule — janus-cardinality-topN DAG"
participants:
  - "continuumJanusMetricService"
  - "attributeCardinalityRunner"
  - "attributeCardinalityEngine"
  - "jm_janusApiClient"
architecture_ref: "components-janus-metric-service"
---

# Attribute Cardinality Computation

## Summary

This flow runs weekly via the `janus-cardinality-topN` Airflow DAG on an ephemeral Dataproc cluster with 10 workers (the largest cluster in the service). It reads Jupiter attribute Parquet data for a specific date and hour (2 days before the execution date), computes approximate distinct cardinality for every attribute column (excluding `yatiTimeMs`, `yatiUUID`, and `eventDestination`), and computes the top-5 most frequent values per attribute. All results are persisted to the Janus Metadata Service in a single HTTPS POST.

## Trigger

- **Type**: schedule
- **Source**: Airflow DAG `janus-cardinality-topN` — `schedule_interval = '@weekly'`
- **Frequency**: Weekly (processes data from 2 days before execution date)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Airflow Cloud Composer | DAG scheduler; calculates target date/hour from execution timestamp | External |
| Google Cloud Dataproc | Spark execution environment (10 workers) | External |
| `attributeCardinalityRunner` | Entry point — parses CLI args, initializes Spark session, delegates to `AttributeCardinalityJob` | `continuumJanusMetricService` |
| `attributeCardinalityEngine` | Reads Jupiter Parquet, computes approx distinct counts and top-N values per attribute | `continuumJanusMetricService` |
| `jm_janusApiClient` | Posts cardinality results to `/janus/api/v1/attribute/cardinality` | `continuumJanusMetricService` |
| Janus Metadata Service (`janus-web-cloud`) | Stores attribute cardinality results | External |

## Steps

1. **Airflow calculates target date/hour**: Python operator `run_cardinality_job` computes `start_date` and `start_hour` as 2 days before `data_interval_end`. This offset ensures upstream Jupiter data is fully available.
   - From: Airflow `PythonOperator`
   - To: `DataprocSubmitJobOperator` args
   - Protocol: Python calculation

2. **Airflow triggers cluster creation**: Creates `janus-cardinality-cluster-{timestamp}` with 1 master + 10 worker `n1-standard-4` nodes.
   - From: Airflow
   - To: Dataproc API
   - Protocol: GCP API

3. **Airflow submits Spark job**: Main class `com.groupon.janus.cardinality.AttributeCardinalityJobMain` with args `--configFile`, `--date`, `--hour`.
   - From: Airflow
   - To: Dataproc Spark
   - Protocol: GCP Dataproc API

4. **Parses CLI arguments**: `AttributeCardinalityConf.parse(args)` validates `--configFile`, `--date`, `--hour` using `scopt`; exits with error log if invalid.
   - From: `attributeCardinalityRunner`
   - To: CLI args
   - Protocol: scopt parsing

5. **Reads Jupiter Parquet data**: `spark.read.parquet(jupiterBasePath/ds=$date/hour=$hour)` loads all attribute columns from the Jupiter dataset.
   - From: `attributeCardinalityEngine`
   - To: GCS bucket (`jupiterBasePath`)
   - Protocol: GCS SDK (Spark)

6. **Excludes non-attribute columns**: Columns listed in `jupiterExtraColumns` (`yatiTimeMs`, `yatiUUID`, `eventDestination`) are filtered out before cardinality computation.
   - From: `attributeCardinalityEngine`
   - To: internal filter
   - Protocol: direct

7. **Computes approximate distinct cardinality**: `approx_count_distinct()` is applied to all remaining columns simultaneously in a single Spark aggregation query. Returns an array of `(columnName, approxDistinctCount)` pairs.
   - From: `attributeCardinalityEngine`
   - To: Spark SQL engine
   - Protocol: Spark SQL

8. **Computes top-N values per attribute**: For each attribute with non-zero cardinality, executes a Spark SQL `GROUP BY attributeName ORDER BY count DESC LIMIT 5` query (configurable via `attributeCardinalityTopN=5`).
   - From: `attributeCardinalityEngine`
   - To: Spark SQL engine
   - Protocol: Spark SQL

9. **Persists attribute cardinality**: All `AttributeCardinality` objects (one per column) are serialized to JSON and posted as a list to `/janus/api/v1/attribute/cardinality`. HTTP 204 = success; any other code throws `PersistAttributeCardinalityException`.
   - From: `jm_janusApiClient`
   - To: Janus Metadata Service
   - Protocol: HTTPS POST (JSON)

10. **Cluster deletion**: Trigger rule `all_done`.
    - From: Airflow
    - To: Dataproc API
    - Protocol: GCP API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid CLI arguments | `AttributeCardinalityConf.parse()` returns `None`; error logged; Spark job exits | Airflow task fails; no retry configured (`retries: 0`) |
| GCS Jupiter path not found | Spark throws exception; job exits | Airflow task fails |
| Janus API returns non-204 | `PersistAttributeCardinalityException` thrown | Spark job fails; Airflow task fails; no retry |
| Zero-cardinality attribute | Skipped — `calculateTopN()` returns empty `AttributeCardinality` with no top-N values | No error; zero-cardinality attributes persisted with empty top-N list |

## Sequence Diagram

```
Airflow (PythonOperator) -> Airflow: Calculate date = execution_date - 2 days
Airflow -> Dataproc: Create cluster (janus-cardinality-cluster-{ts}, 10 workers)
Airflow -> Dataproc: Submit Spark JAR (AttributeCardinalityJobMain, --date=X, --hour=Y)
AttributeCardinalityJobMain -> GCS: spark.read.parquet(jupiterBasePath/ds=$date/hour=$hour)
GCS --> AttributeCardinalityJobMain: Jupiter DataFrame (all attribute columns)
AttributeCardinalityJobMain -> Spark: approx_count_distinct(all columns) -> [(col, count)]
loop [for each attribute with cardinality > 0]
  AttributeCardinalityJobMain -> Spark: SELECT col, count GROUP BY col ORDER BY count DESC LIMIT 5
end
AttributeCardinalityJobMain -> JanusWebCloud: POST /janus/api/v1/attribute/cardinality [List[AttributeCardinality]]
JanusWebCloud --> AttributeCardinalityJobMain: HTTP 204
Airflow -> Dataproc: Delete cluster
```

## Related

- Architecture component view: `components-janus-metric-service`
- Related flows: [Ultron Watermark Delta Management](ultron-watermark-delta.md)
- Note: This flow does not use Ultron watermarking — it uses a fixed date/hour argument instead
