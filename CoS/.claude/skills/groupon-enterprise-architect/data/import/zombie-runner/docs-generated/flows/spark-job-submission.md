---
service: "zombie-runner"
title: "Spark Job Submission"
generated: "2026-03-03"
type: flow
flow_name: "spark-job-submission"
flow_type: batch
trigger: "Task node scheduled by zrTaskOrchestrator when all dependencies are met and resources are available"
participants:
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "cloudPlatform"
  - "hdfsStorage"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# Spark Job Submission

## Summary

The Spark Job Submission flow describes how Zombie Runner's `SparkSubmit` operator (in `spark_task.py`) constructs and executes a `spark-submit` command on the Dataproc cluster. The operator resolves `SPARK_HOME` from context or environment, builds the full command line from `app-config`, `cluster-config`, and `other-config` YAML keys, and runs it as a subprocess. On success, if the task declares `emits`, the driver's stdout is parsed as YAML and merged into the workflow context.

## Trigger

- **Type**: schedule (within workflow DAG)
- **Source**: `zrTaskOrchestrator` schedules the `SparkSubmit` node when upstream dependencies complete and resource slots are available
- **Frequency**: Once per workflow execution per task node; typically used for data transformation steps in ETL pipelines

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Schedules and dispatches the SparkSubmit task | `zrTaskOrchestrator` |
| Operator Adapters (SparkSubmit) | Resolves SPARK_HOME; builds `spark-submit` command; executes subprocess; parses stdout | `zrOperatorAdapters` |
| Cloud Platform (Dataproc/YARN) | Runs the Spark driver and executor processes on cluster nodes | `cloudPlatform` |
| HDFS Storage | Source and sink for Spark input/output data | `hdfsStorage` |

## Steps

1. **Acquire resource slots**: Orchestrator acquires declared resource slots (e.g., `memory: 4`) before dispatching.
   - From: `zrTaskOrchestrator`
   - To: Resource pool (in-process)
   - Protocol: direct

2. **Resolve SPARK_HOME**: `SparkSubmit._environment()` resolves the Spark installation path in priority order: (1) `spark-home` config key in YAML, (2) `SPARK_HOME` context variable from `.zrc2` or `context` section, (3) `SPARK_HOME` environment variable. Raises `AssertionError` if not found or path does not exist.
   - From: `zrOperatorAdapters`
   - To: in-process environment resolution
   - Protocol: direct

3. **Load optional spark config file**: If `config-file` is specified in the task, loads shared cluster and other configuration from the YAML file and merges it with inline task settings.
   - From: `zrOperatorAdapters`
   - To: filesystem (config file read)
   - Protocol: direct

4. **Build spark-submit command**: Constructs the full command as: `$SPARK_HOME/bin/spark-submit [cluster-config options] [other-config options] [--pyfiles/--jars/--files resources] <application> [app params]`
   - From: `zrOperatorAdapters`
   - To: in-process command builder
   - Protocol: direct

5. **Execute spark-submit subprocess**: Runs the constructed command; streams stdout/stderr via `sideput`; records wall-clock time.
   - From: `zrOperatorAdapters`
   - To: `cloudPlatform` (YARN / Dataproc cluster)
   - Protocol: subprocess (`spark-submit` binary)

6. **Read and write HDFS data**: The Spark application reads input data from HDFS and writes transformed output back to HDFS as part of the job execution.
   - From: Spark executors (on `cloudPlatform`)
   - To: `hdfsStorage`
   - Protocol: Spark HDFS client

7. **Parse emitted context (optional)**: If the task declares `emits`, parses the driver stdout as YAML and returns the resulting key-value pairs to the orchestrator for merging into the workflow context.
   - From: `zrOperatorAdapters`
   - To: `zrTaskOrchestrator`
   - Protocol: direct (return value)

8. **Release resource slots**: Orchestrator releases the acquired slots back to the pool.
   - From: `zrTaskOrchestrator`
   - To: Resource pool (in-process)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `SPARK_HOME` not found | `AssertionError` raised in `_environment()` | Task fails immediately; no retry helps without fixing config |
| `spark-submit` exits non-zero | Exception raised: "spark job failed with code N" | Orchestrator retries up to `attempts` times |
| stdout YAML parse failure (emits mode) | Exception logged and re-raised | Task fails; check driver log for malformed output |
| YARN resource unavailability | Spark job queues until resources are free or times out | Depends on YARN queue configuration and task `timeout` |

## Sequence Diagram

```
zrTaskOrchestrator -> zrOperatorAdapters: execute(SparkSubmit, context)
zrOperatorAdapters -> zrOperatorAdapters: resolve_spark_home()
zrOperatorAdapters -> zrOperatorAdapters: build_spark_submit_command()
zrOperatorAdapters -> cloudPlatform: spark-submit [options] <application> [args]
cloudPlatform -> hdfsStorage: read input data
hdfsStorage --> cloudPlatform: data
cloudPlatform -> hdfsStorage: write output data
cloudPlatform --> zrOperatorAdapters: exit(0), stdout (driver output)
zrOperatorAdapters -> zrOperatorAdapters: parse_emitted_context(stdout) [if emits]
zrOperatorAdapters --> zrTaskOrchestrator: output_context
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Workflow Execution](workflow-execution.md), [Hive ETL Task](hive-etl-task.md)
