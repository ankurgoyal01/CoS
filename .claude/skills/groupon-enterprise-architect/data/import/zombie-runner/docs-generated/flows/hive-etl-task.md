---
service: "zombie-runner"
title: "Hive ETL Task"
generated: "2026-03-03"
type: flow
flow_name: "hive-etl-task"
flow_type: batch
trigger: "Task node scheduled by zrTaskOrchestrator when all dependencies are met and resources are available"
participants:
  - "zrTaskOrchestrator"
  - "zrOperatorAdapters"
  - "hiveWarehouse"
  - "hdfsStorage"
architecture_ref: "dynamic-zombie-runner-workflow-execution"
---

# Hive ETL Task

## Summary

The Hive ETL Task flow describes how Zombie Runner executes HiveQL-based extract or load operations against the Hive Warehouse. The `HiveTask` operator (part of `zrOperatorAdapters`, implemented in `sql_task.py`) receives a query string or script path from the workflow YAML, performs context variable substitution, and executes the query via the `hive -e` CLI subprocess. Results are written to HDFS-backed Hive tables, making them available to downstream tasks. This is the most common operator pattern in Groupon ETL pipelines.

## Trigger

- **Type**: schedule (within workflow DAG)
- **Source**: `zrTaskOrchestrator` schedules the HiveTask node when all upstream dependencies are complete and sufficient resource slots are available
- **Frequency**: Once per workflow execution; backfills may re-run with different `date` context values

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Task Orchestrator | Selects HiveTask node as runnable; acquires resource slots; dispatches execution | `zrTaskOrchestrator` |
| Operator Adapters (HiveTask) | Performs context substitution; manages temporary tables in setup/teardown; invokes hive CLI subprocess | `zrOperatorAdapters` |
| Hive Warehouse | Executes HiveQL queries; manages table metadata; reads/writes HDFS-backed data | `hiveWarehouse` |
| HDFS Storage | Stores Hive table data as distributed files | `hdfsStorage` |

## Steps

1. **Acquire resource slots**: Task Orchestrator acquires the declared resource slots (e.g., `database_connections: 1`) from the shared resource pool, blocking if slots are unavailable.
   - From: `zrTaskOrchestrator`
   - To: Resource pool (in-process)
   - Protocol: direct

2. **Initialize environment**: `HiveTask._environment()` instantiates the SQL interface (`SQL(adapter="hive", ...)`) using the `db` configuration key and current workflow context.
   - From: `zrOperatorAdapters`
   - To: in-process SQL factory
   - Protocol: direct

3. **Create setup tables**: `HiveTask._setup()` executes any `setup_query` or `setup_script` (e.g., creating temporary staging tables) before the main work query.
   - From: `zrOperatorAdapters`
   - To: `hiveWarehouse`
   - Protocol: `hive -e "<query>"` subprocess

4. **Substitute context variables**: Resolves all `${variable}` tokens in the `query` or `script` configuration using the current workflow context (e.g., replaces `${date}` with `2023-09-15`).
   - From: `zrOperatorAdapters`
   - To: in-process context resolver
   - Protocol: direct

5. **Execute main HiveQL query**: Runs the resolved query via `hive -e "<query>"` or `hive -f <script.hql>` subprocess. The Hive Warehouse reads from and writes to HDFS-backed tables.
   - From: `zrOperatorAdapters`
   - To: `hiveWarehouse` (via `hdfsStorage`)
   - Protocol: `hive` CLI subprocess / HiveQL

6. **Collect output statistics**: Parses subprocess stdout for row counts, file sizes, or other metrics; calls `_statput()` to emit named statistics to the metadata side-channel.
   - From: `zrOperatorAdapters`
   - To: `zrWorkflowStatePersistence` (side-channel)
   - Protocol: direct

7. **Teardown temporary objects**: `HiveTask._teardown()` drops any temporary tables created during setup.
   - From: `zrOperatorAdapters`
   - To: `hiveWarehouse`
   - Protocol: `hive -e "DROP TABLE ..."` subprocess

8. **Release resource slots**: Task Orchestrator releases the acquired resource slots back to the shared pool.
   - From: `zrTaskOrchestrator`
   - To: Resource pool (in-process)
   - Protocol: direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Non-zero `hive` subprocess exit code | Exception raised; task fails | Orchestrator retries up to `attempts` times with `cooldown` wait |
| Context variable unresolved | `KeyError` raised during substitution | Task fails immediately; error identifies the missing variable |
| Temporary table already exists | Hive DDL uses `CREATE TABLE IF NOT EXISTS` or `DROP TABLE IF EXISTS` in idempotent setup | Task proceeds safely on re-run |
| Output table partition conflict | `INSERT OVERWRITE` replaces existing partition data | Idempotent; safe to re-run |

## Sequence Diagram

```
zrTaskOrchestrator -> zrOperatorAdapters: execute(HiveTask, context)
zrOperatorAdapters -> zrOperatorAdapters: substitute_context_variables(query)
zrOperatorAdapters -> hiveWarehouse: hive -e "setup_query" (setup)
hiveWarehouse -> hdfsStorage: CREATE TABLE / stage data
zrOperatorAdapters -> hiveWarehouse: hive -e "main_query" (work)
hiveWarehouse -> hdfsStorage: SELECT / INSERT INTO
hdfsStorage --> hiveWarehouse: data
hiveWarehouse --> zrOperatorAdapters: exit(0)
zrOperatorAdapters -> hiveWarehouse: hive -e "DROP TABLE ..." (teardown)
zrOperatorAdapters --> zrTaskOrchestrator: output_context
```

## Related

- Architecture dynamic view: `dynamic-zombie-runner-workflow-execution`
- Related flows: [Workflow Execution](workflow-execution.md), [Snowflake Data Load](snowflake-data-load.md)
