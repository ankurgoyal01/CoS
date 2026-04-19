---
service: "bq_orr"
title: "DAG Deployment Flow"
generated: "2026-03-03"
type: flow
flow_name: "dag-deployment"
flow_type: batch
trigger: "Push to repository main branch triggers Jenkins CI/CD pipeline"
participants:
  - "continuumBigQueryOrchestration"
  - "bqOrr_deployBotConfig"
  - "preGcpComposerRuntime"
architecture_ref: "dynamic-bq-orr-bqOrr_shankarTestDag-deploy"
---

# DAG Deployment Flow

## Summary

The DAG Deployment Flow packages all DAG Python files from the `orchestrator/` directory and uploads them to the GCS-backed Cloud Composer DAG bucket for each environment in turn (dev → staging → production). The flow is driven by Jenkins using the `dataPipeline` shared library, with `deploybot_gcs` performing the actual GCS upload in a Kubernetes job. Production requires a manual approval gate before promotion proceeds.

## Trigger

- **Type**: schedule / push
- **Source**: Push to the repository main branch triggers the Jenkins `dataPipeline` build
- **Frequency**: On every qualifying push; production promotion is manual

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| BigQuery Orchestration Service | Source of DAG artifact files; defines deployment config | `continuumBigQueryOrchestration` |
| Deploy Bot Configuration | Provides environment-specific GCS bucket names, Kubernetes namespace, cluster context, and promotion chain | `bqOrr_deployBotConfig` |
| Cloud Composer Runtime (dev) | Receives DAG files into `bigquery-dev` namespace via GCS bucket | `preGcpComposerRuntime` (stub) |
| Cloud Composer Runtime (staging) | Receives DAG files into `bigquery-staging` namespace via GCS bucket | `preGcpComposerRuntime` (stub) |
| Cloud Composer Runtime (production) | Receives DAG files into `bigquery-production` namespace via GCS bucket after manual approval | `preGcpComposerRuntime` (stub) |

## Steps

1. **Receive push event**: Jenkins detects a push to the repository and triggers the `dataPipeline` build using the `java-pipeline-dsl@dpgm-1396-pipeline-cicd` shared library.
   - From: `git repository`
   - To: `Jenkins`
   - Protocol: GitHub webhook

2. **Build and package artifact**: Jenkins collects all files matching `**/*` (including `orchestrator/*.py`, `.deploy_bot.yml`) as the deployment artifact.
   - From: `Jenkins`
   - To: `Jenkins artifact store`
   - Protocol: direct (local file system)

3. **Deploy to dev**: `deploybot_gcs` container (`v3.0.0`) runs in the `bigquery-dev` Kubernetes namespace on `gcp-stable-us-central1` and uploads DAG files to `us-central1-grp-shared-comp-155675d0-bucket`.
   - From: `bqOrr_deployBotConfig` (dev target)
   - To: `preGcpComposerRuntime` (dev GCS bucket)
   - Protocol: GCS upload (HTTPS)

4. **Notify dev deployment**: Slack notification posted to `rma-pipeline-notifications` with start, complete, or override event.
   - From: `deploybot_gcs`
   - To: Slack channel `rma-pipeline-notifications`
   - Protocol: Slack webhook

5. **Cloud Composer dev pickup**: Cloud Composer detects updated files in the GCS DAG bucket and syncs them into the Airflow scheduler.
   - From: `preGcpComposerRuntime` (dev GCS bucket)
   - To: `preGcpComposerRuntime` (Airflow scheduler, dev)
   - Protocol: GCS filesystem sync (internal to Composer)

6. **Promote to staging**: On successful dev deployment, `deploybot_gcs` uploads DAG files to `us-central1-grp-shared-comp-03dba3de-bucket` in the `bigquery-staging` namespace.
   - From: `bqOrr_deployBotConfig` (staging target)
   - To: `preGcpComposerRuntime` (staging GCS bucket)
   - Protocol: GCS upload (HTTPS)

7. **Notify staging deployment**: Slack notification posted to `grim---pit`.
   - From: `deploybot_gcs`
   - To: Slack channel `grim---pit`
   - Protocol: Slack webhook

8. **Await manual approval for production**: Pipeline halts and waits for a human operator to approve the production promotion (`manual: true`).
   - From: `Jenkins`
   - To: Human operator
   - Protocol: Jenkins manual approval UI

9. **Deploy to production**: After approval, `deploybot_gcs` uploads DAG files to `us-central1-grp-shared-comp-9260309b-bucket` in the `bigquery-production` namespace on `gcp-production-us-central1`.
   - From: `bqOrr_deployBotConfig` (production target)
   - To: `preGcpComposerRuntime` (production GCS bucket)
   - Protocol: GCS upload (HTTPS)

10. **Cloud Composer production pickup**: Cloud Composer detects updated DAG files and loads them into the production Airflow scheduler.
    - From: `preGcpComposerRuntime` (production GCS bucket)
    - To: `preGcpComposerRuntime` (Airflow scheduler, production)
    - Protocol: GCS filesystem sync (internal to Composer)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `deploybot_gcs` cannot reach GCS bucket | Build fails; Slack notification sent | Jenkins pipeline stops; operator must re-trigger after resolving connectivity |
| Kubernetes cluster unavailable | Build fails; Slack notification sent | Pipeline stops at the failing environment stage; dev and staging remain unaffected if production fails |
| DAG file has Python syntax error | Deployment succeeds (file is uploaded); Airflow fails to parse the DAG | DAG does not appear in Airflow UI; requires fix and re-deployment |
| Manual approval times out | Jenkins pipeline aborts | DAG remains at staging version in production; re-trigger required |

## Sequence Diagram

```
Jenkins -> deploybot_gcs: Run deployment job (dev target)
deploybot_gcs -> GCS (dev bucket): Upload orchestrator/*.py
GCS (dev bucket) -> Cloud Composer (dev): Sync DAG files
deploybot_gcs -> Slack (rma-pipeline-notifications): Notify deploy complete
Jenkins -> deploybot_gcs: Run deployment job (staging target)
deploybot_gcs -> GCS (staging bucket): Upload orchestrator/*.py
GCS (staging bucket) -> Cloud Composer (staging): Sync DAG files
deploybot_gcs -> Slack (grim---pit): Notify deploy complete
Jenkins -> Human Operator: Request manual approval
Human Operator -> Jenkins: Approve production promotion
Jenkins -> deploybot_gcs: Run deployment job (production target)
deploybot_gcs -> GCS (production bucket): Upload orchestrator/*.py
GCS (production bucket) -> Cloud Composer (production): Sync DAG files
deploybot_gcs -> Slack (grim---pit): Notify deploy complete
```

## Related

- Architecture dynamic view: `dynamic-bq-orr-bqOrr_shankarTestDag-deploy`
- Related flows: [DAG Scheduled Execution Flow](dag-scheduled-execution.md), [Production Promotion and Approval Flow](production-promotion.md)
- See [Deployment](../deployment.md) for environment and infrastructure details
- See [Configuration](../configuration.md) for per-environment variable values
