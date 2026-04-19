---
service: "cls-gcp-dags"
title: "Data Validation"
generated: "2026-03-03"
type: flow
flow_name: "data-validation"
flow_type: batch
trigger: "Dispatched by the Task Orchestrator as part of a CLS DAG run"
participants:
  - "dagTaskOrchestrator"
  - "dagDataValidationTask"
  - "dagLoadTask"
architecture_ref: "dynamic-continuumClsGcpDags"
---

# Data Validation

## Summary

The Data Validation flow is the quality gate within every CLS DAG run. Dispatched by the Task Orchestrator (`dagTaskOrchestrator`), the Data Validation Task (`dagDataValidationTask`) reads source datasets and checks completeness and schema expectations. Only upon successful validation does the pipeline allow the Curated Load Task to proceed. This flow is critical for ensuring that downstream curated storage targets receive only clean, schema-conformant data.

## Trigger

- **Type**: event (Airflow task dispatch)
- **Source**: `dagTaskOrchestrator` — dispatches this task as part of the DAG dependency graph during an active CLS DAG run
- **Frequency**: Once per DAG run (each scheduled execution window)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Dispatches the validation task and controls downstream task execution based on result | `dagTaskOrchestrator` |
| Data Validation Task | Performs completeness and schema validation on source datasets | `dagDataValidationTask` |
| Curated Load Task | Receives the validated dataset reference upon successful validation | `dagLoadTask` |

## Steps

1. **Receive Dispatch from Orchestrator**: The Task Orchestrator dispatches the Data Validation Task as part of the DAG execution plan.
   - From: `dagTaskOrchestrator`
   - To: `dagDataValidationTask`
   - Protocol: Airflow task dependency graph

2. **Read Source Dataset**: The Data Validation Task reads the source dataset from the configured upstream data location.
   - From: `dagDataValidationTask`
   - To: Source data (upstream CLS data source)
   - Protocol: Python validation operators (GCP SDK / file I/O)

3. **Validate Completeness**: The Data Validation Task checks that all expected records, partitions, or files are present in the source dataset.
   - From: `dagDataValidationTask`
   - To: `dagDataValidationTask` (internal check)
   - Protocol: Python validation operators

4. **Validate Schema**: The Data Validation Task checks that the source data conforms to expected schema (column names, data types, required fields).
   - From: `dagDataValidationTask`
   - To: `dagDataValidationTask` (internal check)
   - Protocol: Python validation operators

5. **Pass Validated Dataset to Load Task**: Upon successful validation, the validated dataset reference is made available to the Curated Load Task for downstream processing.
   - From: `dagDataValidationTask`
   - To: `dagLoadTask`
   - Protocol: Airflow XCom or shared GCS path (Python operators)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Source data missing or incomplete | Validation operators raise an exception | Task marked as failed; Airflow stops the DAG run; no data written to curated storage |
| Schema mismatch detected | Validation operators raise a schema error | Task marked as failed; DAG run fails; downstream load task does not execute |
| Source data connection failure | Python operator raises an exception | Task marked as failed; Airflow retry policy applies (if configured); DAG run eventually fails if retries exhausted |

## Sequence Diagram

```
dagTaskOrchestrator -> dagDataValidationTask: Dispatch validation task
dagDataValidationTask -> SourceData: Read source dataset
SourceData --> dagDataValidationTask: Return dataset
dagDataValidationTask -> dagDataValidationTask: Check completeness
dagDataValidationTask -> dagDataValidationTask: Check schema
dagDataValidationTask -> dagLoadTask: Pass validated dataset reference
```

## Related

- Architecture dynamic view: `dynamic-continuumClsGcpDags`
- Related flows: [Scheduled DAG Execution](scheduled-dag-execution.md), [Curated Data Load](curated-data-load.md)
