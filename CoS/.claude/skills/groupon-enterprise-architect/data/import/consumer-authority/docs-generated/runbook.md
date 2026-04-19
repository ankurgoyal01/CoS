---
service: "consumer-authority"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow DAG run status | exec (Airflow UI / CLI) | Daily (per scheduled run) | Per YARN job timeout |
| YARN application state | exec (`yarn application -status`) | On demand | N/A |
| Output partition validation | exec (Hive query on `continuumConsumerAuthorityWarehouse`) | Post-run | N/A |

> Consumer Authority is a batch pipeline with no persistent HTTP health endpoint. Job health is assessed through Airflow DAG run status and YARN application state.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Airflow DAG run success/failure | counter | Daily run outcome per region (NA, INTL, GBL) | Any failure |
| YARN application duration | gauge | Wall-clock time for Spark job execution | > No evidence found |
| Output partition row count | gauge | Number of attribute records written to `user_attrs`, `user_attrs_intl`, `user_attrs_gbl` | Anomalous drop vs. prior run |
| Message Bus publish count | counter | Number of consumer-attribute events published to `messageBus` | > No evidence found |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Airflow DAG runs | Airflow UI | > No evidence found — internal Airflow instance |
| Pipeline metrics | > No evidence found | > No evidence found |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Daily run failure | Airflow DAG task fails for any region | critical | Check YARN application logs; inspect `cdeAlertingNotifier` email for failure message; re-trigger via Airflow backfill |
| Output anomaly | Partition row count drops significantly vs. prior run date | warning | Validate source data availability in `hiveWarehouse`; check Spark executor logs for skew or OOM |
| AMS push failure | HTTP call to `continuumAudienceManagementService` returns non-2xx | warning | Verify AMS service availability; re-run publish step if supported |
| Message Bus publish failure | Holmes publisher reports delivery failure | warning | Check `messageBus` broker health; inspect Holmes publisher retry behavior |

> Alert delivery is via `cdeAlertingNotifier` through `smtpRelay`. Recipients are configured in job settings.

## Common Operations

### Restart Service

Consumer Authority has no persistent process to restart. To re-execute a failed or missed run:

1. Identify the failed DAG run in the Airflow UI
2. Clear the failed task instance(s) for the target run date and region
3. Airflow re-triggers `cdeJobOrchestrator` via Cerebro Job Submitter
4. Monitor YARN application status until completion
5. Validate output partitions in `continuumConsumerAuthorityWarehouse`

### Scale Up / Down

Resource scaling is managed via Cerebro job definitions and YARN cluster configuration:

1. Update executor memory and core settings in the Cerebro job definition for the `consumer-authority` job
2. Adjust `spark.executor.memory`, `spark.executor.cores`, and `spark.dynamicAllocation.*` in `spark-defaults.conf` or the job submission template
3. Re-submit via Airflow to pick up new resource settings

### Database Operations

- **Backfill output partitions**: Trigger a backfill run via Airflow with explicit `--run-date` and `--region` arguments; `cdeSparkExecutionEngine` will overwrite the target partition
- **Drop stale partitions**: Use `ALTER TABLE user_attrs DROP PARTITION (run_date='YYYY-MM-DD')` directly against `continuumConsumerAuthorityWarehouse` before re-running
- **Verify partition availability**: Run `SHOW PARTITIONS user_attrs` in the Hive Metastore or via Spark SQL

## Troubleshooting

### Job Fails at Metadata Resolution

- **Symptoms**: Spark job fails early with Hive Metastore connection errors or missing table exceptions
- **Cause**: `hiveWarehouse` is unreachable, Kerberos ticket expired, or source table/partition does not exist for the run date
- **Resolution**: Verify Kerberos ticket validity; confirm `HIVE_METASTORE_URI` is correct; check that source data partitions exist for the target run date

### Output Partition Row Count Anomaly

- **Symptoms**: `user_attrs` / `user_attrs_intl` / `user_attrs_gbl` partition has significantly fewer rows than prior runs
- **Cause**: Missing or incomplete upstream source data in `hiveWarehouse`; Spark executor OOM causing partial writes; skewed data in specific attribute scripts
- **Resolution**: Query source tables in `hiveWarehouse` to confirm data completeness; check YARN executor logs for OOM or task failure; increase executor memory if needed and re-run

### Message Bus Publish Failures

- **Symptoms**: `cdeAlertingNotifier` reports publish errors; downstream consumers missing attribute events
- **Cause**: `messageBus` broker unavailable or Holmes publisher misconfigured
- **Resolution**: Check Message Bus broker health; verify `HOLMES_PUBLISHER_ENDPOINT` configuration; re-trigger publish step if the Spark job supports idempotent re-publishing

### AMS Metadata Push Failures

- **Symptoms**: Alert email from `cdeAlertingNotifier` reports AMS HTTP error
- **Cause**: `continuumAudienceManagementService` unavailable or `AMS_API_BASE_URL` misconfigured
- **Resolution**: Verify AMS service health; confirm endpoint URL; retry via backfill or manual invocation of the publish step

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Daily attribute computation missing for all regions; downstream marketing and personalization running on stale data | Immediate | Data Engineering on-call |
| P2 | Single region missing; or output anomaly detected | 30 min | Data Engineering on-call |
| P3 | AMS metadata push failure; alert delivery failure (SMTP) | Next business day | Data Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `hiveWarehouse` | Query Hive Metastore via `beeline` or Spark SQL | No fallback — job cannot proceed without source metadata |
| `hdfsStorage` | `hdfs dfs -ls` on relevant data paths | No fallback — source data files required |
| `messageBus` | Holmes publisher connectivity check | Attributes still written to warehouse; event publishing retried on next run |
| `continuumAudienceManagementService` | HTTP GET to AMS health endpoint | Warehouse output still available; metadata catalog may lag one run |
| `smtpRelay` | SMTP connection test | Alerts not delivered; job outcome still logged |

> Operational procedures not covered above should be defined by the service owner.
