---
service: "keboola"
title: "Pipeline Run Flow"
generated: "2026-03-03"
type: flow
flow_name: "pipeline-run-flow"
flow_type: batch
trigger: "Scheduled orchestration trigger or manual run initiated in Keboola UI"
participants:
  - "kbcPipelineOrchestrator"
  - "kbcExtractionConnectors"
  - "kbcTransformationEngine"
  - "kbcDestinationWriters"
  - "kbcOpsNotifier"
  - "salesForce"
  - "bigQuery"
  - "googleChat"
architecture_ref: "dynamic-pipeline-run-flow"
---

# Pipeline Run Flow

## Summary

The Pipeline Run Flow is the primary end-to-end ETL workflow executed by Keboola Connection. The Pipeline Orchestrator coordinates all stages in sequence: it triggers extraction from Salesforce, hands extracted datasets to the Transformation Engine, dispatches transformed data to the Destination Writers for loading into BigQuery, and finally receives and forwards operational status through the Ops Notifier to Google Chat. This flow represents the complete data integration lifecycle from source to destination.

## Trigger

- **Type**: schedule or manual
- **Source**: `kbcPipelineOrchestrator` — scheduled within Keboola's orchestration configuration or manually triggered via the Keboola web UI
- **Frequency**: Configured per-pipeline schedule (specific schedule not documented in codebase)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pipeline Orchestrator | Coordinates and sequences all pipeline stages | `kbcPipelineOrchestrator` |
| Extraction Connectors | Pulls raw data from Salesforce | `kbcExtractionConnectors` |
| Transformation Engine | Applies transformation and augmentation logic | `kbcTransformationEngine` |
| Destination Writers | Loads transformed data into BigQuery | `kbcDestinationWriters` |
| Ops Notifier | Publishes run status and failure alerts | `kbcOpsNotifier` |
| Salesforce | Source system providing CRM and merchant data | `salesForce` |
| BigQuery | Destination analytics warehouse | `bigQuery` |
| Google Chat | Receives operational status notifications | `googleChat` |

## Steps

1. **Initiate extraction**: Pipeline Orchestrator schedules and triggers the extraction run.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcExtractionConnectors`
   - Protocol: Internal (Keboola platform workflow)

2. **Pull source data**: Extraction Connectors call Salesforce API to retrieve CRM and merchant datasets.
   - From: `kbcExtractionConnectors`
   - To: `salesForce`
   - Protocol: HTTPS/API

3. **Stage raw datasets**: Extraction Connectors deliver raw datasets to the Transformation Engine.
   - From: `kbcExtractionConnectors`
   - To: `kbcTransformationEngine`
   - Protocol: Internal (Keboola platform staging)

4. **Start transformation**: Pipeline Orchestrator also directly triggers configured transformation steps.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcTransformationEngine`
   - Protocol: Internal (Keboola platform workflow)

5. **Apply transformations**: Transformation Engine applies augmentation and transformation logic, producing transformed datasets.
   - From: `kbcTransformationEngine`
   - To: `kbcDestinationWriters`
   - Protocol: Internal (Keboola platform staging)

6. **Dispatch load stage**: Pipeline Orchestrator dispatches the load stage to Destination Writers.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcDestinationWriters`
   - Protocol: Internal (Keboola platform workflow)

7. **Load to BigQuery**: Destination Writers batch-load transformed datasets into BigQuery.
   - From: `kbcDestinationWriters`
   - To: `bigQuery`
   - Protocol: HTTPS/Batch Load

8. **Report load outcome**: Destination Writers report load status (success or failure) to Ops Notifier.
   - From: `kbcDestinationWriters`
   - To: `kbcOpsNotifier`
   - Protocol: Internal (Keboola platform event)

9. **Emit pipeline status**: Pipeline Orchestrator emits overall success/failure status to Ops Notifier.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcOpsNotifier`
   - Protocol: Internal (Keboola platform event)

10. **Notify operations**: Ops Notifier sends run status and any failure alerts to Google Chat via webhook.
    - From: `kbcOpsNotifier`
    - To: `googleChat`
    - Protocol: Webhook (HTTPS POST)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable | Extraction run fails; `kbcOpsNotifier` emits failure event | Google Chat alert sent; BigQuery not updated for this run |
| Transformation script error | Transformation stage fails; downstream load stage does not execute | Google Chat alert sent; BigQuery receives no data for this run |
| BigQuery load failure | `kbcDestinationWriters` reports failure to `kbcOpsNotifier` | Google Chat alert sent; data remains in Keboola staging for manual replay |
| Google Chat webhook failure | Notification delivery fails silently | Pipeline run result is unnotified; Keboola UI still reflects run status |

## Sequence Diagram

```
PipelineOrchestrator -> ExtractionConnectors: Start extraction from configured source connector
ExtractionConnectors -> Salesforce: Pull CRM and merchant datasets (HTTPS/API)
Salesforce --> ExtractionConnectors: Raw datasets
ExtractionConnectors -> TransformationEngine: Provide raw datasets
PipelineOrchestrator -> TransformationEngine: Start configured transformation steps
TransformationEngine -> DestinationWriters: Provide transformed datasets
PipelineOrchestrator -> DestinationWriters: Dispatch load stage
DestinationWriters -> BigQuery: Batch load transformed data (HTTPS/Batch Load)
BigQuery --> DestinationWriters: Load acknowledgment
DestinationWriters -> OpsNotifier: Emit load status and errors
PipelineOrchestrator -> OpsNotifier: Emit success/failure status events
OpsNotifier -> GoogleChat: Send operational alert (Webhook)
```

## Related

- Architecture dynamic view: `dynamic-pipeline-run-flow`
- Related flows: [Extraction Flow](extraction-flow.md), [Ops Notification Flow](ops-notification-flow.md)
