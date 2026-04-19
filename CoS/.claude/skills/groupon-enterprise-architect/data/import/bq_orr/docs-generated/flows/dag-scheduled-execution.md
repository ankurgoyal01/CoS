---
service: "bq_orr"
title: "DAG Scheduled Execution Flow"
generated: "2026-03-03"
type: flow
flow_name: "dag-scheduled-execution"
flow_type: scheduled
trigger: "Airflow scheduler triggers daily based on DAG schedule_interval"
participants:
  - "continuumBigQueryOrchestration"
  - "bqOrr_shankarTestDag"
  - "bqOrr_amitTestDag"
  - "preGcpComposerRuntime"
  - "bigQuery"
architecture_ref: "dynamic-bq-orr-bqOrr_shankarTestDag-deploy"
---

# DAG Scheduled Execution Flow

## Summary

Once DAG files have been deployed to a Cloud Composer environment, the Airflow scheduler automatically triggers each DAG according to its configured `schedule_interval`. Both DAGs defined in this repository (`shankar_test` and `amit_test`) run on a daily schedule and execute Python callable tasks via the `PythonOperator`. The Cloud Composer environment manages all scheduling, retries, and task execution; this service only defines the DAG logic.

## Trigger

- **Type**: schedule
- **Source**: Airflow scheduler in Cloud Composer, based on `schedule_interval=timedelta(days=1)` defined in each DAG
- **Frequency**: Daily, starting from `2024-06-01` (as configured in `default_args`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cloud Composer Runtime | Hosts the Airflow scheduler; triggers DAG runs according to schedule; manages task execution workers | `preGcpComposerRuntime` (stub) |
| shankar_test DAG | Airflow DAG (`dag_id: shankar_test`) defined in `orchestrator/hello_world.py`; executes `hello_task` via `PythonOperator` | `bqOrr_shankarTestDag` |
| amit_test DAG | Airflow DAG (`dag_id: amit_test`) defined in `orchestrator/hello_world2.py`; executes `hello_task` via `PythonOperator` | `bqOrr_amitTestDag` |
| Google BigQuery | Target data warehouse; receives orchestrated workload queries from DAG tasks | `bigQuery` |

## Steps

1. **Scheduler evaluates DAG schedule**: The Airflow scheduler in Cloud Composer checks the `schedule_interval` of all loaded DAGs and identifies runs that are due.
   - From: `preGcpComposerRuntime` (Airflow scheduler)
   - To: `preGcpComposerRuntime` (Airflow scheduler, internal)
   - Protocol: Airflow scheduler internal

2. **Create DAG run**: The scheduler creates a new DAG run instance for the scheduled execution date.
   - From: `preGcpComposerRuntime` (Airflow scheduler)
   - To: `preGcpComposerRuntime` (Airflow metadata database)
   - Protocol: Airflow internal (SQLAlchemy)

3. **Queue task**: The `hello_task` task (using `PythonOperator`) is placed in the task queue for execution.
   - From: `preGcpComposerRuntime` (Airflow scheduler)
   - To: `preGcpComposerRuntime` (Airflow worker)
   - Protocol: Airflow internal (Celery/KubernetesExecutor)

4. **Execute Python callable**: The Airflow worker invokes the `print_hello` Python function defined in the DAG file.
   - From: `preGcpComposerRuntime` (Airflow worker)
   - To: `preGcpComposerRuntime` (Airflow worker, Python runtime)
   - Protocol: direct (Python function call)

5. **Orchestrate BigQuery workload**: The BigQuery Orchestration Service, through Cloud Composer, executes data warehouse tasks against Google BigQuery using the BigQuery API.
   - From: `continuumBigQueryOrchestration`
   - To: `bigQuery`
   - Protocol: Apache Airflow / BigQuery API

6. **Mark task success or failure**: Airflow records the task outcome. On failure, the retry policy (`retries: 1`, `retry_delay: timedelta(minutes=5)`) is applied.
   - From: `preGcpComposerRuntime` (Airflow worker)
   - To: `preGcpComposerRuntime` (Airflow metadata database)
   - Protocol: Airflow internal

7. **Mark DAG run complete**: Once all tasks in the DAG have succeeded (or exhausted retries), the DAG run is marked as success or failed.
   - From: `preGcpComposerRuntime` (Airflow scheduler)
   - To: `preGcpComposerRuntime` (Airflow metadata database)
   - Protocol: Airflow internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task execution fails (transient error) | Airflow retries once after 5-minute delay (`retries: 1`, `retry_delay: 5 min`) | Task marked as failed if retry also fails; DAG run marked as failed |
| BigQuery API unavailable | Task fails; retry applies | After 1 retry, task and DAG run marked as failed; no automated escalation |
| DAG file removed from Composer bucket | Airflow removes DAG from scheduler on next sync | Scheduled runs stop; DAG no longer appears in UI |
| `depends_on_past: False` | Each daily run is independent | A failed run does not block subsequent daily runs |

## Sequence Diagram

```
Cloud Composer (Airflow scheduler) -> Cloud Composer (Airflow scheduler): Evaluate daily schedule
Cloud Composer (Airflow scheduler) -> Cloud Composer (Airflow metadata DB): Create DAG run
Cloud Composer (Airflow scheduler) -> Cloud Composer (Airflow worker): Queue hello_task
Cloud Composer (Airflow worker) -> Cloud Composer (Airflow worker): Execute print_hello() callable
Cloud Composer (Airflow worker) -> Google BigQuery: Execute data warehouse tasks (BigQuery API)
Google BigQuery --> Cloud Composer (Airflow worker): Return results
Cloud Composer (Airflow worker) -> Cloud Composer (Airflow metadata DB): Mark task success/failure
Cloud Composer (Airflow scheduler) -> Cloud Composer (Airflow metadata DB): Mark DAG run complete
```

## Related

- Architecture dynamic view: `dynamic-bq-orr-bqOrr_shankarTestDag-deploy`
- Related flows: [DAG Deployment Flow](dag-deployment.md), [Production Promotion and Approval Flow](production-promotion.md)
- See [Integrations](../integrations.md) for BigQuery and Cloud Composer dependency details
- See [Architecture Context](../architecture-context.md) for component definitions
