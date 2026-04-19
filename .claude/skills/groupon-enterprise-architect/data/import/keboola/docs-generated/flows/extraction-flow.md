---
service: "keboola"
title: "Extraction Flow"
generated: "2026-03-03"
type: flow
flow_name: "extraction-flow"
flow_type: batch
trigger: "Pipeline Orchestrator schedules and triggers the extraction stage"
participants:
  - "kbcPipelineOrchestrator"
  - "kbcExtractionConnectors"
  - "kbcTransformationEngine"
  - "salesForce"
architecture_ref: "dynamic-pipeline-run-flow"
---

# Extraction Flow

## Summary

The Extraction Flow covers the first stage of the Keboola ETL pipeline: the Pipeline Orchestrator schedules and triggers the Extraction Connectors to pull raw datasets from Salesforce CRM via HTTPS/API. Once extraction completes, the raw datasets are handed off to the Transformation Engine for processing. This flow is the ingest boundary between Salesforce as the upstream source and Keboola's internal pipeline runtime.

## Trigger

- **Type**: schedule
- **Source**: `kbcPipelineOrchestrator` — triggers extraction as the first stage of a pipeline run
- **Frequency**: Configured per-pipeline schedule within Keboola orchestration settings (specific cadence not documented in codebase)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pipeline Orchestrator | Schedules and triggers extraction runs | `kbcPipelineOrchestrator` |
| Extraction Connectors | Executes source extraction against Salesforce API | `kbcExtractionConnectors` |
| Salesforce | Upstream source system providing CRM and merchant data | `salesForce` |
| Transformation Engine | Receives staged raw datasets for subsequent processing | `kbcTransformationEngine` |

## Steps

1. **Schedule extraction run**: Pipeline Orchestrator determines it is time to run extraction based on the configured schedule and triggers the Extraction Connectors.
   - From: `kbcPipelineOrchestrator`
   - To: `kbcExtractionConnectors`
   - Protocol: Internal (Keboola platform workflow)

2. **Call Salesforce API**: Extraction Connectors authenticate with Salesforce and request CRM and merchant datasets.
   - From: `kbcExtractionConnectors`
   - To: `salesForce`
   - Protocol: HTTPS/API

3. **Receive raw data**: Salesforce returns the requested datasets to the Extraction Connectors.
   - From: `salesForce`
   - To: `kbcExtractionConnectors`
   - Protocol: HTTPS/API (response)

4. **Stage for transformation**: Extraction Connectors pass the raw datasets into the Keboola staging area and notify the Transformation Engine they are ready.
   - From: `kbcExtractionConnectors`
   - To: `kbcTransformationEngine`
   - Protocol: Internal (Keboola platform staging)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Salesforce API unavailable or returns error | Extraction Connectors fail the extraction run | Pipeline Orchestrator marks the run as failed; `kbcOpsNotifier` is triggered (see [Ops Notification Flow](ops-notification-flow.md)) |
| Salesforce credential expiry | Authentication error returned by Salesforce API | Extraction fails; requires credential rotation in Keboola connector configuration |
| Partial data returned | Connector receives incomplete dataset | Depends on connector configuration; may succeed with partial data or fail with a threshold error |

## Sequence Diagram

```
PipelineOrchestrator -> ExtractionConnectors: Start extraction from configured source connector
ExtractionConnectors -> Salesforce: Pull CRM and merchant datasets (HTTPS/API)
Salesforce --> ExtractionConnectors: Raw datasets
ExtractionConnectors -> TransformationEngine: Provide raw datasets
```

## Related

- Architecture dynamic view: `dynamic-pipeline-run-flow`
- Related flows: [Pipeline Run Flow](pipeline-run-flow.md), [Ops Notification Flow](ops-notification-flow.md)
