---
service: "cls-gcp-dags"
title: "Curated Data Load"
generated: "2026-03-03"
type: flow
flow_name: "curated-data-load"
flow_type: batch
trigger: "Dispatched by the Task Orchestrator after successful data validation within a CLS DAG run"
participants:
  - "dagTaskOrchestrator"
  - "dagDataValidationTask"
  - "dagLoadTask"
architecture_ref: "dynamic-continuumClsGcpDags"
---

# Curated Data Load

## Summary

The Curated Data Load flow is the final stage of every CLS DAG run. After the Data Validation Task (`dagDataValidationTask`) confirms that source data is complete and schema-conformant, the Task Orchestrator dispatches the Curated Load Task (`dagLoadTask`) to write the validated outputs into curated downstream storage targets on GCP. This flow is the delivery mechanism that makes CLS-processed data available for downstream analytics and science workloads.

## Trigger

- **Type**: event (Airflow task dispatch, conditional on validation success)
- **Source**: `dagTaskOrchestrator` dispatches the load task; `dagDataValidationTask` passes the validated dataset reference
- **Frequency**: Once per successful DAG run (each scheduled execution window where validation passes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Dispatches the load task as part of the DAG dependency graph | `dagTaskOrchestrator` |
| Data Validation Task | Provides the validated dataset reference consumed by the load task | `dagDataValidationTask` |
| Curated Load Task | Writes validated CLS outputs to curated downstream storage targets | `dagLoadTask` |

## Steps

1. **Receive Dispatch from Orchestrator**: The Task Orchestrator dispatches the Curated Load Task, which is upstream-gated on successful completion of the Data Validation Task.
   - From: `dagTaskOrchestrator`
   - To: `dagLoadTask`
   - Protocol: Airflow task dependency graph

2. **Receive Validated Dataset**: The Curated Load Task receives the validated dataset reference from the Data Validation Task.
   - From: `dagDataValidationTask`
   - To: `dagLoadTask`
   - Protocol: Airflow XCom or shared GCS path (Python operators)

3. **Load Validated Outputs**: The Curated Load Task writes the validated CLS dataset to the configured curated downstream storage target.
   - From: `dagLoadTask`
   - To: Curated downstream storage (GCP — e.g., BigQuery table or GCS bucket)
   - Protocol: Python load operators (GCP SDK)

4. **Confirm Load Completion**: Upon successful write, the task is marked as succeeded in Airflow, completing the DAG run.
   - From: `dagLoadTask`
   - To: `dagTaskOrchestrator` (Airflow task state update)
   - Protocol: Airflow internal task state

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Load task skipped because validation failed | Airflow dependency mechanism prevents execution | Task not run; DAG run fails at validation stage |
| Write failure to curated storage (permissions) | Python load operator raises an exception | Task marked as failed; Airflow retry policy applies; DAG run fails if retries exhausted |
| Write failure due to quota or capacity | Python load operator raises an exception | Task marked as failed; requires manual investigation and retry |
| Partial write (connection lost mid-load) | Depends on operator idempotency; no specific pattern evidenced | Data may be incomplete; manual re-trigger of load task required |

## Sequence Diagram

```
dagTaskOrchestrator -> dagLoadTask: Dispatch load task
dagDataValidationTask -> dagLoadTask: Provide validated dataset reference
dagLoadTask -> CuratedStorage: Write validated CLS outputs
CuratedStorage --> dagLoadTask: Write acknowledged
dagLoadTask --> dagTaskOrchestrator: Load task succeeded
```

## Related

- Architecture dynamic view: `dynamic-continuumClsGcpDags`
- Related flows: [Scheduled DAG Execution](scheduled-dag-execution.md), [Data Validation](data-validation.md)
