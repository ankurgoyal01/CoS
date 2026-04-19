---
service: "PmpNextDataSync"
title: "Medallion Pipeline — Silver + Gold"
generated: "2026-03-03"
type: flow
flow_name: "medallion-pipeline"
flow_type: scheduled
trigger: "Airflow cron (0 2 * * * UTC); runs after bronze DataSync tasks complete in the same DAG"
participants:
  - "continuumDataSyncOrchestration"
  - "continuumDataSyncCoreProcessor"
  - "continuumPmpHudiBronzeLake"
architecture_ref: "dynamic-scheduled_sync_execution"
---

# Medallion Pipeline — Silver + Gold

## Summary

The medallion pipeline is a three-layer Spark batch pipeline orchestrated by the `pmp-medallion-na.py` (and EMEA equivalent) Airflow DAG. After the bronze DataSync layer extracts data from PostgreSQL sources into Hudi tables, the silver transformation layer applies business logic transformations, and the gold processor layer generates final campaign audiences and arbitration outputs. All three layers run on the same ephemeral Dataproc cluster within a single DAG run. Task dependencies ensure bronze completes before silver starts, and silver completes before gold starts.

## Trigger

- **Type**: schedule
- **Source**: Airflow `pmp-medallion-na` DAG (and `pmp-medallion-emea` for EMEA)
- **Frequency**: Daily at `0 2 * * *` (02:00 UTC); SLA set to 5 hours from DAG start.

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| DataSync Orchestration (Airflow) | Orchestrates all three pipeline layers; manages cluster lifecycle | `continuumDataSyncOrchestration` |
| DataSyncCore Spark Processor | Executes bronze extraction jobs (datasynccore JAR) | `continuumDataSyncCoreProcessor` |
| Transformer Spark Jobs | Executes silver transformation logic (transformer JAR) | `continuumDataSyncCoreProcessor` (same cluster) |
| Processor Spark Jobs | Executes gold processing and audience generation (processor JAR) | `continuumDataSyncCoreProcessor` (same cluster) |
| PMP Hudi Bronze Lake | Source for silver/gold; target for bronze writes | `continuumPmpHudiBronzeLake` |

## Steps

1. **DAG trigger**: Airflow fires `medallion-prod-na` DAG at `0 2 * * *`.
   - From: `continuumDataSyncOrchestration`
   - Protocol: Airflow scheduler

2. **Create Dataproc cluster**: Single cluster `pmp-medallion-cluster-na` (1 master n2-standard-16, 18 workers n2-standard-32, 2 TB disk each) is provisioned.
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

3. **Fetch config files**: `fetch_config_files` Python task calls GitHub API to list YAML files in `DataSyncConfig/na-prod/`, pushing the file list to Airflow XCom.
   - From: `continuumDataSyncOrchestration`
   - To: `externalGitHubApi`
   - Protocol: HTTPS

4. **[BRONZE] DataSync Spark jobs**: One `DataprocSubmitJobOperator` task is created per YAML config file (e.g., `bronze_cm_sync_na_yaml`, `bronze_gss_sync_na_yaml`). Each runs `com.groupon.pmp.Job` with `datasynccore_2.12` JAR. All bronze tasks run in parallel (Airflow task parallelism).
   - From: `continuumDataSyncOrchestration`
   - To: `continuumDataSyncCoreProcessor` (datasynccore JAR)
   - Protocol: Dataproc job submission

5. **[SILVER] Transformation Spark jobs**: After all bronze jobs complete, silver transformation tasks run. Each task runs a specific transformation class from the `transformer_2.12` JAR. Dependencies are defined in `pmp-medallion-config.json`:
   - `Push-ActiveCalcUsersTransformationJob` and `Email-ActiveCalcUsersTransformationJob` run first (no dependencies).
   - `Push-PushSubscriptionsTransformationJob` depends on `Push-ActiveCalcUsersTransformationJob`.
   - `Email-GSSTransformationJob` depends on `Email-ActiveCalcUsersTransformationJob`.
   - `AudienceTransformationJobEmail` and `AudienceTransformationJobPush` depend on their respective ActiveCalcUsers jobs.
   - `Email-CampaignTransformationJob` and `Push-CampaignTransformationJob` run independently.
   - From: `continuumDataSyncOrchestration`
   - To: Transformer Spark jobs (reads bronze Hudi tables, writes silver Hudi tables)
   - Protocol: Dataproc job submission

6. **[GOLD] Processor Spark jobs**: After all silver jobs complete, gold processor tasks run in sequence (defined by `dependencies` in config):
   - `EmailCampaignProcessor` (`NAEmailCampaignProcessor`) runs first.
   - `NaEmailArbitrationProcessor` depends on `EmailCampaignProcessor`.
   - `PushCampaignProcessor` depends on `NaEmailArbitrationProcessor`.
   - `NaPushArbitrationProcessor` depends on `PushCampaignProcessor`.
   - From: `continuumDataSyncOrchestration`
   - To: Processor Spark jobs (`processor_2.12` JAR; reads silver Hudi tables, writes gold outputs)
   - Protocol: Dataproc job submission

7. **Delete Dataproc cluster**: Cluster deleted after all tasks complete or fail (`TriggerRule.ALL_DONE`).
   - From: `continuumDataSyncOrchestration`
   - To: `externalDataprocService`
   - Protocol: GCP Dataproc API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Bronze task failure | Airflow task retry (up to 2); silver/gold tasks blocked | Alert email; downstream layers not run |
| Silver task failure | Airflow task retry; dependent silver tasks blocked | Partial silver output; gold tasks that depend on failed silver are blocked |
| Gold task failure | Airflow task retry; downstream gold tasks blocked | Partial gold output; campaign dispatch may be stale |
| SLA miss (5 hours) | `dag_sla_miss_alert` callback fires | Alert email to OpsGenie; investigate slow tasks |
| Cluster deletion failure | Cluster may persist; GCP quota at risk | Manual cleanup via GCP Dataproc console |

## Sequence Diagram

```
Airflow -> GitHub API: List DataSyncConfig/na-prod/ YAML files
Airflow -> Dataproc: Create cluster pmp-medallion-cluster-na (18 workers)
Airflow -> DataSyncCore [bronze]: Submit datasynccore jobs (one per YAML file, parallel)
DataSyncCore [bronze] -> PostgreSQL: Extract delta/full rows
DataSyncCore [bronze] -> HudiBronzeLake: Write/upsert bronze Hudi tables
Airflow -> Transformer [silver]: Submit transformation jobs (per jobs_list, with dependencies)
Transformer [silver] -> HudiBronzeLake: Read bronze Hudi tables, apply transforms
Transformer [silver] -> HudiBronzeLake: Write silver Hudi tables
Airflow -> Processor [gold]: Submit processor jobs (sequential: Email -> Arbitration -> Push)
Processor [gold] -> HudiBronzeLake: Read silver Hudi tables
Processor [gold] -> HudiBronzeLake: Write gold audience/arbitration outputs
Airflow -> Dataproc: Delete cluster (ALL_DONE)
```

## Related

- Architecture dynamic view: `dynamic-scheduled_sync_execution`
- Related flows: [Bronze DataSync — Incremental Sync](bronze-datasync-incremental.md), [Bronze DataSync — Full Load Sync](bronze-datasync-full-load.md), [Dispatcher Flow — Email and Push](dispatcher-flow.md)
