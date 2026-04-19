---
service: "bq_orr"
title: "Production Promotion and Approval Flow"
generated: "2026-03-03"
type: flow
flow_name: "production-promotion"
flow_type: batch
trigger: "Manual approval by operator after successful staging deployment"
participants:
  - "continuumBigQueryOrchestration"
  - "bqOrr_deployBotConfig"
  - "preGcpComposerRuntime"
architecture_ref: "dynamic-bq-orr-bqOrr_shankarTestDag-deploy"
---

# Production Promotion and Approval Flow

## Summary

After DAG artifacts have been successfully deployed to the staging Cloud Composer environment, the Jenkins pipeline halts and requires a human operator to manually approve promotion to production. This gate prevents unvalidated DAG changes from reaching the production data warehouse. Once approved, `deploybot_gcs` uploads the same artifact to the production GCS bucket and Cloud Composer syncs the updated DAGs into the production Airflow scheduler.

## Trigger

- **Type**: manual
- **Source**: Human operator approves the production promotion step in Jenkins after inspecting staging results
- **Frequency**: On demand — once per deployment cycle that reaches the production gate

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Jenkins Pipeline | Orchestrates the promotion gate; presents approval UI; invokes `deploybot_gcs` on approval | — (CI/CD infrastructure) |
| Deploy Bot Configuration | Defines production target: cluster `gcp-production-us-central1`, namespace `bigquery-production`, bucket `us-central1-grp-shared-comp-9260309b-bucket` | `bqOrr_deployBotConfig` |
| BigQuery Orchestration Service | Source of versioned DAG artifact files | `continuumBigQueryOrchestration` |
| Cloud Composer Runtime (production) | Receives promoted DAG files; loads them into the production Airflow scheduler | `preGcpComposerRuntime` (stub) |
| Human Operator | Reviews staging DAG execution results and approves or rejects production promotion | — |

## Steps

1. **Staging deployment completes**: The Jenkins pipeline successfully deploys DAG files to the staging Composer environment and Slack notification is sent to `grim---pit`.
   - From: `deploybot_gcs`
   - To: `preGcpComposerRuntime` (staging GCS bucket)
   - Protocol: GCS upload (HTTPS)

2. **Pipeline halts at manual gate**: Jenkins pauses and presents the production promotion approval step to authorised operators (`manual: true` in `.deploy_bot.yml`).
   - From: `Jenkins`
   - To: Human operator (via Jenkins UI)
   - Protocol: Jenkins manual approval UI

3. **Operator validates staging**: The operator reviews DAG execution results in the staging Airflow UI and confirms that the DAGs behave correctly.
   - From: Human operator
   - To: Cloud Composer staging Airflow UI
   - Protocol: HTTPS (browser)

4. **Operator approves promotion**: The operator clicks approve in the Jenkins UI, unblocking the production deployment stage.
   - From: Human operator
   - To: `Jenkins`
   - Protocol: Jenkins UI interaction

5. **Deploy to production**: `deploybot_gcs` (`v3.0.0`) runs in the `bigquery-production` Kubernetes namespace on `gcp-production-us-central1` and uploads DAG files to `us-central1-grp-shared-comp-9260309b-bucket`.
   - From: `bqOrr_deployBotConfig` (production target)
   - To: `preGcpComposerRuntime` (production GCS bucket)
   - Protocol: GCS upload (HTTPS)

6. **Notify production deployment**: Slack notification posted to `grim---pit` with start, complete, or override event.
   - From: `deploybot_gcs`
   - To: Slack channel `grim---pit`
   - Protocol: Slack webhook

7. **Cloud Composer production pickup**: Cloud Composer detects the updated DAG files in the production GCS bucket and loads them into the production Airflow scheduler.
   - From: `preGcpComposerRuntime` (production GCS bucket)
   - To: `preGcpComposerRuntime` (Airflow scheduler, production)
   - Protocol: GCS filesystem sync (internal to Composer)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Operator rejects production promotion | Jenkins pipeline aborts at the manual gate | DAG artifact remains at previous version in production; staging retains the new version |
| Manual approval times out | Jenkins pipeline aborts | Same as rejection — production is unchanged; operator must re-trigger the pipeline |
| `deploybot_gcs` fails during production upload | Jenkins build fails; Slack notification sent to `grim---pit` | Production Composer bucket retains the previous DAG version; operator must investigate and re-trigger |
| Production Composer unavailable | `deploybot_gcs` upload may succeed but Composer cannot sync | DAG files are in GCS but not loaded by Airflow; resolves when Composer recovers |

## Sequence Diagram

```
Jenkins -> Human Operator: Request manual approval for production promotion
Human Operator -> Cloud Composer (staging Airflow UI): Inspect DAG execution results
Cloud Composer (staging Airflow UI) --> Human Operator: DAG run status OK
Human Operator -> Jenkins: Approve production promotion
Jenkins -> deploybot_gcs: Run deployment job (production target)
deploybot_gcs -> GCS (production bucket): Upload orchestrator/*.py
deploybot_gcs -> Slack (grim---pit): Notify production deploy complete
GCS (production bucket) -> Cloud Composer (production): Sync DAG files
```

## Related

- Architecture dynamic view: `dynamic-bq-orr-bqOrr_shankarTestDag-deploy`
- Related flows: [DAG Deployment Flow](dag-deployment.md), [DAG Scheduled Execution Flow](dag-scheduled-execution.md)
- See [Deployment](../deployment.md) for environment and CI/CD pipeline details
- See [Configuration](../configuration.md) for production environment variable values
