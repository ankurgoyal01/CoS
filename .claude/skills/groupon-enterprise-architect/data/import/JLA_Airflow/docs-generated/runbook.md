---
service: "JLA_Airflow"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Airflow webserver UI (Composer-managed) | http | Composer-managed | Composer-managed |
| `jla-eba-rules-exec` status alert task | exec (DAG task) | Per scheduled run | Per DAG timeout |
| DB Watchman (`db-watchman`) daily run | exec (DAG task) | Daily at `15 1 * * *` | Per DAG timeout |

## Monitoring

### Metrics

> No evidence found in codebase of Prometheus, Datadog, or Grafana metrics instrumentation. Monitoring is primarily via Airflow UI DAG run states and Google Chat alerts.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| DAG run state (Airflow UI) | gauge | Success/failed/running per DAG | Any failure triggers `on_failure_callback` |
| `jla-eba-rules-exec` EBA summary | counter | Journal entry count, rule count, debit total | Missing rulesets trigger alert |
| `jla-pipeline-customers` variance | counter | Count of customer records not processed by NetSuite | Any variance > 0 fails DAG and triggers alert |
| DB Watchman alerts | event | Configurable checks against Teradata object metadata | `alert_flag = 1` triggers Google Chat alert |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| `.sre.dashboards` | — | `n/a` (as declared in `.service.yml`) |
| Airflow DAG UI | Apache Airflow | Composer webserver URL |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DAG task failure | Any task failure (`on_failure_callback`) | critical | Check Airflow task log; inspect Google Chat `ENGINEERING_ALERTS` space |
| EBA missing rulesets | Missing entries in EBA task run table after rules execution | critical | Investigate JLA EBA service; check `acct_jla_eba_rulesets` table |
| Customer sync variance | `count_variance > 0` in `jla-pipeline-customers` | critical | Check NetSuite integration service logs; review `acct_jla_customer_staging` |
| DB Watchman configurable alert | Alert query returns `alert_flag = 1` | warning | Review alert in `meta_db_watchman_alerts`; investigate Teradata object changes |
| No new customer data | `acct_jla_customer_staging` shows no data loaded in > 7 days | warning | Verify `ads_billing_report` source data; check upstream data pipelines |

## Common Operations

### Restart Service

Apache Airflow on Composer is managed by GCP. To restart individual DAG runs:
1. Navigate to the Airflow web UI
2. Locate the failed or stuck DAG run in the DAG list
3. Clear the failed task(s) to re-queue them, or trigger a new manual run

### Manual Pipeline Re-run

To rerun the JLA ETL pipeline without publishing the BigQuery dataset:
```json
{"manual-run-NO-update-dataset": true}
```
Trigger on any ETL DAG (steps 1–8). The flag propagates to all downstream triggered DAGs.

To rerun the full pipeline and force dataset publication:
```json
{"manual-run-update-dataset": true}
```
Trigger on the `jla-mart-etl-1-startup` DAG (step 1).

To rerun from a mid-pipeline step (e.g., step 3):
1. Trigger `jla-mart-etl-3-extract` (or the desired step) manually
2. Pass `{"manual-run-NO-update-dataset": true}` to prevent accidental dataset re-publication
3. The flag will propagate through all downstream triggered DAGs

### DB Gatekeeper — Execute a SQL Script

1. Prepare a SQL file in the appropriate `database/` folder in the FSA Database Git repo
2. Name the file following the convention: `[TICKET_PREFIX]-NNNN_short_description.sql` (e.g., `FINS-1234_add_index.sql`)
3. Merge to `main` branch (required for production)
4. Trigger `db-gatekeeper` DAG with config:
```json
{"script_list": ["https://raw.github.groupondev.com/FSA/FSA_Database/main/Teradata/Scripts/FINS-1234_add_index.sql"]}
```
5. The DAG validates naming conventions, verifies the Jira ticket exists, executes the script, and logs results to `meta_db_gatekeeper_log`

### Scale Up / Down

> Scaling is managed by Google Cloud Composer. Contact GCP/platform team to adjust Composer environment size.

### Database Operations

- **DDL changes**: Use the `db-gatekeeper` DAG (see above)
- **Environment setup/refresh**: Use the `db-summoner` DAG with one of three modes: Create+Update, Drop, or Update
- **DB object monitoring**: `db-watchman` runs daily at `15 1 * * *`; review `meta_db_watchman_*` tables for changes

## Troubleshooting

### ETL Pipeline Stalled or Failed Mid-Chain

- **Symptoms**: One of the ETL DAGs (`jla-mart-etl-2-lookups` through `jla-mart-etl-8-*`) shows failed status; downstream DAGs did not trigger
- **Cause**: A `TriggerDagRunOperator` at the end of the failed DAG did not fire, breaking the chain
- **Resolution**: Clear the failed task or manually trigger the next DAG in the chain with `{"manual-run-NO-update-dataset": true}` to continue without republishing

### Customer Sync Variance Alert

- **Symptoms**: `jla-pipeline-customers` DAG fails with "A variance was identified"; `ENGINEERING_ALERTS` Google Chat shows detailed variance message
- **Cause**: NetSuite integration service did not process all staged customer records (`count_target != count_netsuite`)
- **Resolution**: Check NetSuite integration service health; review `acct_jla_customer_staging` for error records; re-trigger DAG after NetSuite service is restored

### DB Gatekeeper Pre-Validation Failure

- **Symptoms**: `db-gatekeeper` DAG fails at `pre_validate` task
- **Cause**: Script URL is not from `raw.github.groupondev.com`; filename does not match `[A-Z]+-\d{2,7}_*.sql` convention; Jira ticket does not exist; branch is not `main` in production
- **Resolution**: Correct the script URL or filename; ensure Jira ticket is valid; merge to `main` for production runs

### Kyriba SFTP No Files Found

- **Symptoms**: Kyriba DAG fails at file download step
- **Cause**: Kyriba has not placed files at `/out/` matching `GROUPON.NC4.REPORT.*.PAYMENTS*`
- **Resolution**: Confirm with treasury/Kyriba that the payment clearing file was generated; check SFTP connectivity via `kyriba_sftp` Airflow connection

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | JLA ETL pipeline completely blocked; accounting data not updated | Immediate | FSA Engineering (`fsa-eng@groupon.com`), FSA team lead |
| P2 | Individual pipeline (ads billing, customers, EBA) failing; partial data impact | 30 min | FSA Engineering (`fsa-eng@groupon.com`) |
| P3 | DB Watchman alert; non-critical DAG failure | Next business day | FSA Engineering (`fsa-eng@groupon.com`) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Teradata (`dwh_fsa_prd`) | Query `acct_jla_run_process`; check DAG task logs | No automated fallback; DAG fails and alerts |
| JLA EBA Service | `http_jla_services_root` HTTP GET returns 200 | EBA DAG fails; journal entries not staged |
| JLA NetSuite Integration Service | Final status report in customer/ads DAGs | Customer/invoice DAGs fail with variance; manual rerun after service recovery |
| Kyriba SFTP | File presence at `/out/` with expected mask | No automated fallback; DAG fails |
| Google Chat | Webhook HTTP 200 | Alert silently dropped; does not affect pipeline |
