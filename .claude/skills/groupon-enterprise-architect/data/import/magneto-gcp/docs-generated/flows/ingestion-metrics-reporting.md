---
service: "magneto-gcp"
title: "Ingestion Metrics Reporting"
generated: "2026-03-03"
type: flow
flow_name: "ingestion-metrics-reporting"
flow_type: scheduled
trigger: "Airflow DAG 'magneto_metric_gcp' — every 30 minutes"
participants:
  - "continuumMagnetoOrchestrator"
  - "metricsStack"
architecture_ref: "components-continuumMagnetoOrchestrator"
---

# Ingestion Metrics Reporting

## Summary

The `magneto_metric_gcp` Airflow DAG runs every 30 minutes and publishes ingestion health metrics to the internal Telegraf/InfluxDB metrics gateway. It queries the `dwh_manage.table_limits` MySQL database to compute per-table lag metrics (how many days behind `consistent_before_hard` is relative to current time), then pushes these as InfluxDB data points. This provides visibility into which Salesforce tables are falling behind their ingestion schedules without requiring log inspection.

## Trigger

- **Type**: schedule
- **Source**: Airflow schedule `timedelta(minutes=30)`; `catchup=False`; started 2 days ago from deploy
- **Frequency**: Every 30 minutes continuously

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Metrics DAG (Airflow) | Schedules and coordinates metric collection and publishing tasks | `continuumMagnetoOrchestrator` |
| Metrics Reporter (`MetricsOperator`) | Queries MySQL `table_limits`; formats InfluxDB points; writes to Telegraf gateway | `magnetoMetricsReporter` |
| MySQL table_limits (`dwh_manage`) | Source of watermark data for lag computation | `unknown_dwhmanagetablelimitsmysql_bab098d9` |
| Telegraf metrics gateway | Receives and routes InfluxDB line protocol metrics | `metricsStack` |

## Steps

1. **Start DAG**: Airflow triggers `magneto_metric_gcp` DAG every 30 minutes; `start_dag` DummyOperator fires
   - From: Airflow scheduler
   - To: DAG
   - Protocol: in-process Airflow

2. **Collect table lag metrics** (`sf_table_lag` task): `MetricsOperator` executes SQL against `megatron_table_limits` MySQL connection (DSN `megatron_table_limits`, database `dwh_manage`):
   ```sql
   SELECT DISTINCT table_name, consistent_before_hard,
     TIMESTAMPDIFF(day, consistent_before_hard, CURRENT_TIMESTAMP()) AS sf_table_lag_by_date
   FROM dwh_manage.table_limits
   WHERE content_group = 'salesforce' AND schema_name = 'Hive_gcp'
     AND table_name NOT IN ('dim_sf_record_type', 'Country__c', ...)
   ```
   Returns per-table lag in days.
   - From: `magnetoMetricsReporter`
   - To: MySQL (`dwh_manage.table_limits`)
   - Protocol: MySQL connector via `MySqlHook`

3. **Collect latest update timestamps** (`sf_table_upt` task, parallel with step 2): `MetricsOperator` executes:
   ```sql
   SELECT table_name, MAX(consistent_before_hard) AS latest_update_ts
   FROM dwh_manage.table_limits
   WHERE content_group = 'salesforce' AND schema_name = 'Hive_gcp'
   GROUP BY table_name
   ```
   - From: `magnetoMetricsReporter`
   - To: MySQL (`dwh_manage.table_limits`)
   - Protocol: MySQL connector

4. **Format InfluxDB data points**: For each result row, `MetricsOperator.create_metrics()` builds an InfluxDB measurement with:
   - Measurement name: `custom.data.magneto-gcp.<agg_function>` (e.g., `custom.data.magneto-gcp.sf_table_lag_by_date`)
   - Tags: `region=us-central1`, `env=<env>`, `source=magneto-gcp`, `atom=magneto-gcp`, `service=<table_name>`, `component=app`
   - Fields: `value=<lag_days or timestamp>`
   - From: `magnetoMetricsReporter` (in-process)
   - To: InfluxDB data structure
   - Protocol: in-process Python

5. **Push metrics to Telegraf gateway**: `MetricsOperator.send_metrics()` creates `InfluxDBClient` and calls `write_points()`:
   - Prod: `telegraf.us-central1.conveyor.prod.gcp.groupondev.com:80`
   - Stable: `telegraf.us-central1.conveyor.stable.gcp.groupondev.com:80`
   - Dev: `telegraf.general.sandbox.gcp.groupondev.com:80`
   - From: `magnetoMetricsReporter`
   - To: `metricsStack` (Telegraf gateway)
   - Protocol: HTTP (InfluxDB line protocol)

6. **End DAG**: `end_dag` DummyOperator with `trigger_rule='none_failed'` marks the run complete
   - From: DAG
   - To: Airflow state
   - Protocol: in-process Airflow

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL query failure | Task fails; DAG retry once after 10-minute delay (`retries=1, retry_delay=10min`) | Email to `dnd-ingestion@groupon.com` on failure |
| Telegraf gateway unreachable | `InfluxDBClient.write_points()` raises; task fails | Metrics gap for that 30-minute window; retry after 10 minutes |
| Missing or excluded table in `table_limits` | Table excluded by SQL WHERE clause (known exclusion list in query) | No metric published for excluded table; not an error |
| env variable not set | `Variable.get('env')` raises `KeyError` at module load | DAG fails to load in Airflow |

## Sequence Diagram

```
Airflow -> magneto_metric_gcp: trigger every 30 minutes
magneto_metric_gcp -> MySQL dwh_manage: SELECT table lag (sf_table_lag_by_date)
magneto_metric_gcp -> MySQL dwh_manage: SELECT latest update ts (hive_table_lag) [parallel]
MySQL --> MetricsOperator: per-table rows
MetricsOperator -> MetricsOperator: format InfluxDB points (measurement + tags + fields)
MetricsOperator -> TelegrafGateway: InfluxDBClient.write_points() (HTTP)
TelegrafGateway --> MetricsOperator: 204 OK
magneto_metric_gcp -> Airflow: mark run complete
```

## Related

- Architecture dynamic view: `dynamic-magneto-salesforce-ingestion-flow`
- Related flows: [Salesforce Incremental Ingestion](salesforce-incremental-ingestion.md), [Salesforce Data Validation](salesforce-validation-audit.md)
