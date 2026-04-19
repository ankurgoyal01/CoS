---
service: "deals-cluster"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Cerebro Resource Manager — search "dealscluster" | http | Manual | — |
| Wavefront Dashboard — deals-cluster-v2-telegraf | http | Continuous | — |
| Kibana Dashboard — Staging / Production | http | Continuous | — |

- **Cerebro Resource Manager (Production)**: `http://cerebro-resourcemanager1.snc1:8088/cluster`
- **Cerebro Resource Manager (Staging)**: `http://cerebro-resourcemanager2.snc1:8088/cluster`
- **Currently running jobs**: `http://cerebro-resourcemanager1.snc1:8088/cluster/apps/RUNNING`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `success` (tagged `sub-service`, `country`, `rule-name`) | counter | Incremented for each successful rule/country combination | Wavefront alert if count drops below expected |
| `failed` (tagged `sub-service`, `country`, `rule-name`) | counter | Incremented for each failed rule/country combination | Wavefront alert severity 3 on any failure |
| `time.total` (tagged `sub-service`) | timer | Total elapsed time for the entire job (nanoseconds) | — |
| `success.total` (tagged `sub-service`) | counter | Incremented once when the full Spark job completes | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deals Cluster V2 Telegraf | Wavefront | `https://groupon.wavefront.com/dashboard/deals-cluster-v2-telegraf` |
| Staging alerts | Wavefront | `https://groupon.wavefront.com/u/XQjTBCFvMp` |
| Production alerts | Wavefront | `https://groupon.wavefront.com/u/WbyHDYj7kC` |
| Kibana Staging (tabular) | Kibana | `https://logging-us.groupondev.com/goto/38f9ceb2de3aa91fb02be7b51e934a31` |
| Kibana Production (tabular) | Kibana | `https://logging-us.groupondev.com/goto/b13c82c9e370baa185e85e0862019c5c` |
| PostgreSQL | CheckMK | `https://checkmk-lvl3.groupondev.com/ber1_prod/...` (see OWNERS_MANUAL.md) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Deals Cluster Spark Job Failure — Deals_Cluster Job | `failed` metric incremented for `DEALS_CLUSTER` sub-service | 3 | Check Kibana logs for `FailedCreateClusters`, `FailedDecoratingClusters`, or `FailedWriteToHDFS` event; rerun job manually |
| Deals Cluster Spark Job Failure — Top_Clusters Job | `failed` metric incremented for `TOP_CLUSTER` sub-service | 3 | Check Kibana logs for `FailedTopClustersExtraction`; rerun job manually |
| Deals Cluster Job Has Not Completed in Last 24 hours | Job `success.total` not recorded within 24h window | 3 | Check Cerebro Resource Manager; kill long-running job and let cron restart it |
| Top Cluster Job Has Not Completed in Last 24 hours | Job `success.total` not recorded within 24h window | 3 | Check Cerebro Resource Manager; kill long-running job and let cron restart it |

Alert pages go to: **deals-cluster-alerts@groupon.com** (PagerDuty)

## Common Operations

### Start DealsClusterJob Manually

SSH to Cerebro job submitter, then:

```bash
export ENV=production   # or staging
nohup /home/svc_mars_mds/deals-cluster/current/run/runDealsClusterJob <COUNTRY-LIST> <YYYYMMDD> [RULE_NAME] &
```

- `COUNTRY-LIST`: comma-separated country codes, e.g., `UK,IT,CA,FR,DE,ES,PL,AU,NL,BE,IE,AE,NZ,US,JP`
- `YYYYMMDD`: date of data to process, e.g., `20190417`
- `RULE_NAME` (optional): specific rule to run, e.g., `COUNTRY_CFT_L4`

### Start TopClustersJob Manually

```bash
export ENV=production   # or staging
nohup /home/svc_mars_mds/deals-cluster/current/run/runTopClustersJob <COUNTRY-LIST> [RULE_NAME] &
```

### Stop Running Job

1. Find the job in Cerebro Resource Manager (search "dealscluster").
2. Click "Kill Application" in the UI, OR:

```bash
# Production
ssh svc_mars_mds@cerebro-job-submitter2.snc1
yarn application -kill <application_id>

# Staging
ssh svc_mars_mds@cerebro-job-submitter3.snc1
yarn application -kill <application_id>
```

### Disable / Enable Cron Jobs

**Disable** (prevent new submissions):
```bash
ssh svc_mars_mds@cerebro-job-submitter2.snc1   # production
crontab -u
```

**Re-enable**:
```bash
ssh svc_mars_mds@cerebro-job-submitter2.snc1
crontab /home/svc_mars_mds/deals-cluster/current/crontab
```

### Database Operations

- Verify PostgreSQL health via [CheckMK dashboard](https://checkmk-lvl3.groupondev.com/ber1_prod/) — search for host `gds-snc1-prod-db062m1.snc1`, service regex `deals_cluster`.
- Contact the GDS team for PostgreSQL infrastructure issues.
- To inspect HDFS output files, use the Hue file browser: `http://cerebro-hue-server1.snc1:8000/filebrowser/#/user/grp_gdoop_mars_mds/deals_cluster_production`

## Troubleshooting

### `FailedCreateClusters` Event

- **Symptoms**: Alert fires; Kibana shows `FailedCreateClusters` log event with a `ruleName` and `country`.
- **Cause**: An exception occurred during cluster generation (Spark SQL query failure, bad rule definition, missing data).
- **Resolution**: Check the full stack trace in Kibana. If transient, rerun the job manually for the affected countries and rules.

### `FailedDecoratingClusters` Event

- **Symptoms**: Alert fires; Kibana shows `FailedDecoratingClusters` log event.
- **Cause**: Failed while loading the EDW data or joining it with the deals dataset. Often an EDW data availability issue.
- **Resolution**: Query `edwprod.agg_gbl_traffic_fin_deal` via Hue (`http://cerebro-hue-server1.snc1:8000/beeswax/`). If accessible, rerun. If not, contact the EDW team.

### `MissingHDFSFile` Event

- **Symptoms**: Alert fires; Kibana shows `MissingHDFSFile` log event.
- **Cause**: The MDS flat file for the target date/country was not produced by the upstream MDS pipeline.
- **Resolution**: Check HDFS file browser for today's file. If missing, request a re-run from the MDS pipeline team. If file exists, rerun the Deals Cluster job manually.

### `FailedWriteToHDFS` Event

- **Symptoms**: Alert fires; Kibana shows `FailedWriteToHDFS` log event.
- **Cause**: HDFS write failure — typically a transient network or HDFS issue.
- **Resolution**: Rerun the job manually for the affected clusters.

### `FailedTopClustersExtraction` Event

- **Symptoms**: Alert fires; Kibana shows `FailedTopClustersExtraction` log event.
- **Cause**: Exception during top cluster extraction (Spark job failure, missing HDFS input from `DealsClusterJob`).
- **Resolution**: Verify `DealsClusterJob` completed successfully first (check HDFS for output files). If `DealsClusterJob` output exists, rerun `TopClustersJob` manually.

### Job Running Longer Than 24 Hours

- **Symptoms**: "Job Has Not Completed in Last 24 hours" alert fires but no failure alert received.
- **Cause**: Job is still running (possibly stuck on a Spark executor or a large partition).
- **Resolution**: Navigate to Cerebro Resource Manager, find the running job, kill it, and let the cron trigger the next scheduled run (or rerun manually if time-sensitive).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Job not producing any clusters; API consumers serving stale data | Immediate | MIS team (deals-cluster-alerts@groupon.com) |
| P2 | Partial failure — some rules/countries not completing | 30 min | MIS team |
| P3 | Single rule failure or delayed completion | Next business day | MIS team via Slack #MIS |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MDS HDFS | Check Hue file browser for today's flat file | Request MDS re-run; no automated fallback |
| EDW Hive | Query `edwprod.agg_gbl_traffic_fin_deal` via Hue | Contact EDW team; no automated fallback |
| Deals Cluster Rules API | Access `http://deals-cluster-vip.snc1/rules` | No fallback; job will fail at startup without rules |
| Top Clusters Rules API | Access `http://deals-cluster-vip.snc1/topclustersrules` | No fallback; job will fail at startup without rules |
| PostgreSQL | CheckMK dashboard | Contact GDS team; no automated failover |
| InfluxDB | Non-critical; metrics failure does not block job execution | Metrics gap tolerated; job continues |
