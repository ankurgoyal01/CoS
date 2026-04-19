---
service: "cls-gcp-dags"
title: "Scheduled DAG Execution"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-dag-execution"
flow_type: scheduled
trigger: "Google Cloud Scheduler time-based event received by the Airflow scheduler integration"
participants:
  - "dagScheduleTrigger"
  - "dagTaskOrchestrator"
  - "dagDataValidationTask"
  - "dagLoadTask"
architecture_ref: "dynamic-continuumClsGcpDags"
---

# Scheduled DAG Execution

## Summary

This flow represents the complete end-to-end lifecycle of a CLS DAG run, from the Cloud Scheduler-emitted trigger through task orchestration, data validation, and curated data load. It is the primary operational flow of `cls-gcp-dags` and encapsulates all four pipeline components within the `continuumClsGcpDags` container. The flow ensures that data quality is validated before any curated outputs are written to downstream storage targets.

## Trigger

- **Type**: schedule
- **Source**: Google Cloud Scheduler — time-based trigger delivered to Cloud Composer (Airflow scheduler)
- **Frequency**: Determined by the Cloud Scheduler cron expression configured for this DAG; specific schedule not discoverable from architecture DSL alone

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Schedule Trigger | Receives Cloud Scheduler event and initiates DAG execution window | `dagScheduleTrigger` |
| Task Orchestrator | Coordinates task dependencies and dispatches downstream tasks | `dagTaskOrchestrator` |
| Data Validation Task | Validates source completeness and schema before loading | `dagDataValidationTask` |
| Curated Load Task | Writes validated outputs to curated downstream storage | `dagLoadTask` |

## Steps

1. **Receive Schedule Trigger**: Cloud Scheduler emits a time-based trigger to the Airflow scheduler integration.
   - From: `Google Cloud Scheduler`
   - To: `dagScheduleTrigger`
   - Protocol: Airflow scheduler integration (GCP Cloud Composer trigger mechanism)

2. **Initiate DAG Run**: The Schedule Trigger component initiates a CLS DAG execution window and hands control to the Task Orchestrator.
   - From: `dagScheduleTrigger`
   - To: `dagTaskOrchestrator`
   - Protocol: Airflow internal task dependency graph

3. **Dispatch Data Validation**: The Task Orchestrator dispatches the Data Validation Task to run source completeness and schema checks.
   - From: `dagTaskOrchestrator`
   - To: `dagDataValidationTask`
   - Protocol: Airflow task dependency graph

4. **Execute Data Validation**: The Data Validation Task reads source data and validates completeness and schema expectations.
   - From: `dagDataValidationTask`
   - To: Source data (read operation)
   - Protocol: Python validation operators

5. **Dispatch Curated Load**: The Task Orchestrator, having confirmed validation success, also dispatches the Curated Load Task. The Data Validation Task passes the validated dataset reference to the Load Task.
   - From: `dagTaskOrchestrator`
   - To: `dagLoadTask`
   - Protocol: Airflow task dependency graph

6. **Pass Validated Dataset**: The validated dataset is made available to the Curated Load Task.
   - From: `dagDataValidationTask`
   - To: `dagLoadTask`
   - Protocol: Airflow XCom or shared GCS path (Python operators)

7. **Load Curated Outputs**: The Curated Load Task writes validated CLS data to the curated downstream storage targets.
   - From: `dagLoadTask`
   - To: Curated downstream storage (e.g., BigQuery or GCS)
   - Protocol: Python load operators (GCP SDK)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cloud Scheduler fails to trigger | DAG run not initiated for that window; Airflow catch-up enabled if configured | Run skipped or caught up on next cycle |
| Data Validation Task fails | Airflow marks the task as failed; downstream Curated Load Task is not executed | DAG run marked failed; no data written to curated storage |
| Curated Load Task fails | Airflow marks the task as failed | DAG run marked failed; partial or no data written; manual retry required |
| Task Orchestrator branching error | DAG run fails at orchestration stage | All downstream tasks skipped; DAG run marked failed |

## Sequence Diagram

```
Cloud Scheduler -> dagScheduleTrigger: Emit time-based trigger
dagScheduleTrigger -> dagTaskOrchestrator: Initiate DAG run
dagTaskOrchestrator -> dagDataValidationTask: Dispatch validation task
dagDataValidationTask -> dagDataValidationTask: Validate source completeness and schema
dagDataValidationTask -> dagLoadTask: Pass validated dataset
dagTaskOrchestrator -> dagLoadTask: Dispatch load task
dagLoadTask -> Curated Storage: Write validated CLS data
dagLoadTask --> dagTaskOrchestrator: Load complete
dagTaskOrchestrator --> dagScheduleTrigger: DAG run complete
```

## Related

- Architecture dynamic view: `dynamic-continuumClsGcpDags`
- Related flows: [Data Validation](data-validation.md), [Curated Data Load](curated-data-load.md)
