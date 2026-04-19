---
service: "PmpNextDataSync"
title: "Dispatcher Flow — Email and Push"
generated: "2026-03-03"
type: flow
flow_name: "dispatcher-flow"
flow_type: scheduled
trigger: "Airflow cron every 30 minutes (*/30 * * * *)"
participants:
  - "continuumDataSyncOrchestration"
  - "continuumDataSyncCoreProcessor"
  - "continuumPmpHudiBronzeLake"
architecture_ref: "dynamic-scheduled_sync_execution"
---

# Dispatcher Flow — Email and Push

## Summary

The dispatcher flow reads enriched audience data from the Hudi bronze/gold layer and triggers email and push notification campaign dispatch. It runs every 30 minutes for both NA and EMEA regions. Each run provisions an ephemeral Dataproc cluster, submits the dispatcher Spark job (`dispatcher_na_2.12` JAR), and tears down the cluster. A separate but similar pattern exists for the RAPI consumer flow (reads real-time API data) and the enricher/producer flow (produces enriched audience records every 4 hours).

## Trigger

- **Type**: schedule
- **Source**: Airflow DAGs — `dispatcher-na.py`, `dispatcher-emea.py`
- **Frequency**: Every 30 minutes (`*/30 * * * *`); SLA: 1 hour per run; `max_active_runs=1` prevents overlap.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DataSync Orchestration (Airflow) | Schedules dispatcher runs, manages Dataproc cluster lifecycle | `continuumDataSyncOrchestration` |
| Dispatcher Spark Job | Reads audience data from Hudi and dispatches campaigns | `continuumDataSyncCoreProcessor` (dispatcher JAR) |
| PMP Hudi Bronze Lake | Source of enriched audience and arbitration data for dispatch | `continuumPmpHudiBronzeLake` |

## Steps

1. **DAG trigger (every 30 min)**: Airflow fires the `dispatcher-prod-na` DAG on the cron schedule. At most one active run is permitted (`max_active_runs=1`).
   - From: `continuumDataSyncOrchestration`
   - Protocol: Airflow scheduler

2. **Create Dataproc cluster**: Cluster `pmp-dispatcher-cluster-na` is provisioned (1 master n2-standard-32, 15 workers n2-standard-16, 1 TB disk each). Init script loads TLS certificates from GCS.
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

3. **Submit dispatcher Spark job (email)**: `DataprocSubmitJobOperator` submits `com.groupon.pmp.DispatcherJob` with `dispatcher_na_2.12` JAR. Args: `["com.groupon.pmp.EmailDispatcherNA.EmailDispatcherJobNA", "false", "prod-na"]`. Dynamic allocation: 2–100 executors, 14 GB each, 5 cores each.
   - From: `continuumDataSyncOrchestration`
   - To: Dispatcher Spark job
   - Protocol: Dataproc job submission

4. **Dispatcher reads audience data**: The dispatcher Spark job reads enriched audience data from Hudi gold tables in `continuumPmpHudiBronzeLake`.
   - From: Dispatcher Spark job
   - To: `continuumPmpHudiBronzeLake`
   - Protocol: GCS read (Hudi)

5. **Dispatch campaigns**: The dispatcher applies arbitration logic and sends campaign dispatch instructions (specific dispatch mechanism is outside this repo's scope).
   - From: Dispatcher Spark job
   - Protocol: Internal

6. **Delete Dataproc cluster**: Cluster deleted after all tasks complete (`TriggerRule.ALL_DONE`).
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

## Related Scheduled Jobs

| DAG | Schedule | Purpose |
|-----|----------|---------|
| `dispatcher-prod-na` | `*/30 * * * *` | Email dispatch for NA |
| `dispatcher-prod-emea` | `*/30 * * * *` | Email dispatch for EMEA |
| `dispatcher-prod-na-push` | `*/30 * * * *` | Push dispatch for NA |
| `dispatcher-prod-emea-push` | `*/30 * * * *` | Push dispatch for EMEA |
| `enricher-prod-na-producer` | `0 */4 * * *` | Enricher/producer job every 4 hours (NA) |
| `enricher-prod-emea-producer` | `0 */4 * * *` | Enricher/producer job every 4 hours (EMEA) |
| `rapi-consumer-prod-na` | `*/30 * * * *` | RAPI consumer every 30 min (NA) |
| `rapi-consumer-prod-emea` | `*/30 * * * *` | RAPI consumer every 30 min (EMEA) |
| `re-calc-processor-na` | `15 */4 * * *` | Re-calculation processor every 4 hours at :15 (NA) |
| `re-calc-processor-emea` | `15 */4 * * *` | Re-calculation processor every 4 hours at :15 (EMEA) |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Dispatcher Spark job failure | Zero retries at job level (`retries=0`); Airflow task retries up to 2 | Alert email to OpsGenie |
| SLA miss (1 hour) | `dag_sla_miss_alert` callback fires | Alert; investigate cluster size or data volume |
| Cluster creation failure | Task fails; delete_cluster fires anyway (ALL_DONE) | No dangling clusters; next 30-min run attempts fresh cluster |
| Concurrent run attempted | Airflow `max_active_runs=1` rejects the new run | New run skipped; existing run continues |

## Sequence Diagram

```
Airflow -> Dataproc: Create cluster pmp-dispatcher-cluster-na (15 workers)
Dataproc --> Airflow: Cluster ready
Airflow -> DispatcherJob: Submit com.groupon.pmp.DispatcherJob (email, prod-na)
DispatcherJob -> HudiBronzeLake: Read gold audience / arbitration Hudi tables
DispatcherJob -> DispatcherJob: Apply arbitration and campaign selection logic
DispatcherJob --> Airflow: Spark job success
Airflow -> Dataproc: Delete cluster (ALL_DONE)
```

## Related

- Architecture dynamic view: `dynamic-scheduled_sync_execution`
- Related flows: [Medallion Pipeline — Silver + Gold](medallion-pipeline.md), [CDP Deny-list Sync](cdp-deny-list-sync.md)
