---
service: "zombie-runner"
title: "Workflow Execution"
generated: "2026-03-03"
type: flow
flow_name: "workflow-execution"
flow_type: batch
trigger: "CLI invocation: zombie_runner run <workflow_dir> [--param=value ...]"
participants:
  - "zrCli"
  - "zrWorkflowReader"
  - "zrDagBuilder"
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "zrWorkflowStatePersistence"
  - "continuumZombieRunnerStateStore"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# Workflow Execution

## Summary

This is the primary end-to-end flow for Zombie Runner, encompassing everything from CLI invocation to final state persistence. A data engineer or automation script calls `zombie_runner run <workflow_dir>` on a Dataproc cluster node, triggering the runtime to parse YAML workflow definitions, construct a dependency DAG, orchestrate parallel task execution with resource budgeting, and persist task state to the filesystem checkpoint store. The flow terminates when all tasks have either completed successfully or exhausted their retry attempts.

## Trigger

- **Type**: user-action / manual
- **Source**: Shell invocation of `zombie_runner run <workflow_dir>` on a Dataproc cluster master node (as root user or with `ZOMBIERC`/`ODBCINI` env vars set)
- **Frequency**: On-demand per pipeline execution

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLI Entry Point | Receives the `run` command and workflow directory path; dispatches to workflow runner | `zrCli` |
| Workflow Reader | Loads `tasks.yml` and any included YAML files; resolves task class names, context, settings, and resources | `zrWorkflowReader` |
| DAG Builder | Constructs the dependency graph from task definitions; validates no circular dependencies | `zrDagBuilder` |
| Task Orchestrator | Maintains the run queue; selects runnable tasks (all dependencies met, resources available); executes tasks asynchronously; handles retries | `zrTaskOrchestrator` |
| Operator Adapters | Executes the concrete work for each task type (HiveSQL, Spark, REST, Solr, etc.) | `zrOperatorAdapters` |
| Workflow State Persistence | Writes task completion status and output context to filesystem checkpoints; asynchronously logs to MySQL via `ZrHandler` | `zrWorkflowStatePersistence` |
| Workflow State Store | Filesystem location on the cluster node storing checkpoint files | `continuumZombieRunnerStateStore` |

## Steps

1. **Parse CLI arguments**: Receives `zombie_runner run <workflow_dir> [--key=value ...]` from the shell; extracts workflow directory path and additional context overrides.
   - From: Shell / user
   - To: `zrCli`
   - Protocol: OS process invocation

2. **Load workflow YAML**: Reads `tasks.yml` from the workflow directory; resolves includes, task class names, context variables, global settings (attempts, cooldown, timeout), and resource pool definitions.
   - From: `zrCli`
   - To: `zrWorkflowReader`
   - Protocol: direct (in-process)

3. **Build dependency DAG**: Constructs a directed acyclic graph of task nodes using `networkx`; validates that all declared `dependencies` exist and that no cycles are present; merges CLI context overrides into the global context map.
   - From: `zrWorkflowReader`
   - To: `zrDagBuilder`
   - Protocol: direct (in-process)

4. **Initialize run queue**: Identifies all tasks with no dependencies (root nodes) as initially runnable; reserves resource slots for the first batch.
   - From: `zrDagBuilder`
   - To: `zrTaskOrchestrator`
   - Protocol: direct (in-process)

5. **Evaluate task execute conditions**: Before each task execution, evaluates `conditions` expressions in the task definition; skips the task (marking it complete) if any condition evaluates to false.
   - From: `zrTaskOrchestrator`
   - To: `zrOperatorAdapters` (task `task_execute_condition()`)
   - Protocol: direct (in-process)

6. **Execute task operator**: Calls the task's `execute(context)` lifecycle — `_environment()` → `_setup()` → `_work()`. The operator interacts with the appropriate external system (Hive, Spark, REST, etc.).
   - From: `zrTaskOrchestrator`
   - To: `zrOperatorAdapters`
   - Protocol: direct (in-process)

7. **Evaluate post-execution assertions**: After `_work()` completes, evaluates `assertions` expressions; logs pass/fail results; raises `RuntimeError` if any assertion has `fail: true` and evaluates to false.
   - From: `zrOperatorAdapters` (task `_task_assert()`)
   - To: `zrTaskOrchestrator`
   - Protocol: direct (in-process)

8. **Persist task status and context**: Writes task completion state and any emitted context keys to filesystem checkpoints; asynchronously sends status records through `ZrHandler` pipe to background MySQL writer.
   - From: `zrTaskOrchestrator`
   - To: `zrWorkflowStatePersistence`
   - Protocol: direct (in-process)

9. **Merge output context**: Merges context keys emitted by the completed task into the global workflow context, making them available to downstream tasks.
   - From: `zrWorkflowStatePersistence`
   - To: `zrTaskOrchestrator` (context map)
   - Protocol: direct (in-process)

10. **Schedule next runnable tasks**: Identifies tasks whose dependencies are now all complete and for which resources are available; enqueues them for parallel execution.
    - From: `zrTaskOrchestrator`
    - To: `zrTaskOrchestrator` (run queue)
    - Protocol: direct (in-process)

11. **Run task cleanup phase**: After all dependents of a task have completed successfully, calls `cleanup(context)` → `_environment()` → `_teardown()` to destroy temporary tables, directories, or other global state.
    - From: `zrTaskOrchestrator`
    - To: `zrOperatorAdapters`
    - Protocol: direct (in-process)

12. **Workflow complete**: Process exits 0 on full success, or non-zero if any task exhausted retries without succeeding.
    - From: `zrTaskOrchestrator`
    - To: Shell / user
    - Protocol: OS process exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task raises exception | Orchestrator catches exception; decrements attempt counter; waits `cooldown` seconds; retries up to `attempts` limit | Task marked failed after exhausting retries; workflow exits non-zero |
| Task execute condition false | Task is skipped without executing | Task marked complete (skipped); downstream tasks proceed |
| Assertion failure with `fail: true` | `RuntimeError` raised inside task `_task_assert()`; treated as task failure | Task retried or marked failed |
| Circular dependency in DAG | `zrDagBuilder` detects cycle at build time | Workflow refuses to start; error reported to stdout |
| Context variable not found | `KeyError` raised during `_config()` substitution | Task fails on first attempt; logged with variable name |

## Sequence Diagram

```
User/Shell -> zrCli: zombie_runner run <workflow_dir>
zrCli -> zrWorkflowReader: load_workflow(workflow_dir, context_overrides)
zrWorkflowReader -> zrDagBuilder: build_dag(task_definitions, resources, settings)
zrDagBuilder -> zrTaskOrchestrator: emit_runnable_nodes(dag)
loop [while tasks remain]
  zrTaskOrchestrator -> zrOperatorAdapters: execute(task, context)
  zrOperatorAdapters --> zrTaskOrchestrator: output_context / exception
  zrTaskOrchestrator -> zrWorkflowStatePersistence: persist(task_status, context)
  zrWorkflowStatePersistence -> continuumZombieRunnerStateStore: write_checkpoint()
  zrTaskOrchestrator -> zrTaskOrchestrator: schedule_next_runnable_nodes()
end
zrTaskOrchestrator --> User/Shell: exit(0|non-zero)
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Hive ETL Task](hive-etl-task.md), [Spark Job Submission](spark-job-submission.md), [Snowflake Data Load](snowflake-data-load.md), [Solr Index Build](solr-index-build.md), [HDFS Distribution Push](hdfs-distribution-push.md)
