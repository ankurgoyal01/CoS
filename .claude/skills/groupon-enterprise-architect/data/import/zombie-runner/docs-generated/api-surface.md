---
service: "zombie-runner"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [cli, python-api]
auth_mechanisms: [none]
---

# API Surface

## Overview

Zombie Runner exposes two interaction surfaces: a **command-line interface (CLI)** for data engineers to run workflows directly on Dataproc cluster nodes, and a **Python programmatic API** for embedding Zombie Runner in custom scripts or extending it with custom task types. There is no HTTP server or REST API — the service runs as a process, not as a long-lived service.

## CLI Commands

### `zombie_runner` (entry point: `zombie_runner.entry_points:runner`)

| Command | Syntax | Purpose |
|---------|--------|---------|
| `run` | `zombie_runner run <workflow_dir> [--param=value ...]` | Executes all tasks in the workflow directory |
| `help` | `zombie_runner help [command]` | Displays help for available commands |
| `daemon` | `zombie_runner daemon` | Starts the Zombie Runner daemon (not yet implemented) |

### `run` Command Options

| Option | Purpose | Default |
|--------|---------|---------|
| `--<key>=<value>` | Inject additional context variables into the workflow | None |
| `--task=<task_name>` | Run a specific task and its upstream dependencies only | All tasks |
| `--dry-run=true` | Validate workflow and resolve context without executing | false |
| `--parallelism=<N>` | Maximum number of tasks to execute in parallel | Workflow-defined |
| `--log-level=<LEVEL>` | Set logging verbosity (DEBUG, INFO, WARN, ERROR) | INFO |

### `zombie_daemon` (entry point: `zombie_runner.entry_points:daemon`)

> Not applicable — daemon mode is not yet implemented in the Dataproc fork.

## Workflow YAML API

Workflows are defined as `tasks.yml` files placed in a workflow directory. The YAML schema is the primary configuration contract.

### Top-level YAML keys

| Key | Purpose | Required |
|-----|---------|----------|
| `context` | Global variables accessible to all tasks via `${variable}` substitution | No |
| `settings` | Global retry and timeout defaults (`attempts`, `cooldown`, `timeout`) | No |
| `resources` | Named resource pools with slot counts for parallelism budgeting | No |
| `<task_name>` | Task definition block (one per task in the workflow) | Yes (at least one) |

### Task definition keys

| Key | Purpose | Required |
|-----|---------|----------|
| `class` | Task operator class name (e.g., `HiveTask`, `SparkSubmit`, `NopTask`) | Yes |
| `dependencies` | List of task names that must complete before this task runs | No |
| `resources` | List of resource slots this task acquires before execution | No |
| `settings` | Task-level overrides for `attempts`, `cooldown`, `timeout` | No |
| `parameters` / `configuration` | Task-specific configuration map (varies by operator class) | Operator-dependent |
| `emits` | Context key(s) this task publishes to the shared workflow context on completion | No |
| `conditions` | List of boolean expressions; task is skipped if any evaluates to false | No |
| `assertions` | List of boolean expressions evaluated post-execution; can fail the task | No |
| `meta_info` | Explicit source/target list for lineage metadata | No |
| `trigger` | `failure` — runs the task only if a dependency failed (for alerting tasks) | No |

## Python Programmatic API

### Running workflows

```python
from zombie_runner.workflow import WorkflowRunner

runner = WorkflowRunner("/path/to/workflow/")
result = runner.run(context={"date": "2023-09-01"})
```

### Registering custom tasks

```python
from zombie_runner.task import register_task
from my_package import MyCustomTask

register_task("MyCustomTask", MyCustomTask)
```

### Custom task contract

Custom task classes extend `zombie_runner.task.task.Base` and implement `_work()`. The full lifecycle is `_environment()` → `_setup()` → `_work()` during execute, and `_environment()` → `_teardown()` during cleanup.

## Built-in Task Classes

| Class | Operator Module | Purpose |
|-------|----------------|---------|
| `NopTask` | `task.py` | No-op placeholder; always succeeds |
| `FailTask` | `task.py` | Always fails; useful for testing |
| `EchoEmitTask` | `task.py` | Emits dummy context keys or verifies values |
| `HiveTask` | `sql_task.py` | Executes HiveQL queries or scripts |
| `SparkSubmit` | `spark_task.py` | Submits Spark jobs via `spark-submit` |
| `RestGetTask` | `rest_task.py` | HTTP GET from REST endpoints to local files |
| `RestUploadTask` | `rest_task.py` | HTTP PUT/POST data to REST endpoints |
| `SolrCreateCoreTask` | `solr_task.py` | Creates a new Solr core dynamically |
| `SolrCoreSwapTask` | `solr_task.py` | Swaps and reloads two Solr cores |
| `SolrLoadFromFileTask` | `solr_task.py` | Loads CSV data into a Solr core in batches |
| `SolrDeleteCoreDataTask` | `solr_task.py` | Deletes all documents from a Solr core |
| `SolrGenSchemaTask` | `solr_task.py` | Generates a Solr schema XML file |
| `ShellTask` | `os_task.py` | Executes shell commands |
| `SalesforceTask` | `salesforce_task.py` | Reads/writes Salesforce objects |
| `NetworkTask` | `network_task.py` | Network-level operations |
| `DataTask` | `data_task.py` | HDFS data movement and staging |
| `HadoopTask` | `hadoop_task.py` | Generic Hadoop streaming / MapReduce |

## Rate Limits

> No rate limiting configured. Zombie Runner parallelism is bounded by the `resources` section in the workflow YAML and the optional `--parallelism` CLI flag.

## Versioning

CLI and package versioning follows Git tag names. Tagged releases publish a `.tar.gz` artifact to `https://artifacts-generic.groupondev.com/python/zombie-runner/zombie-runner-<tag>.tar.gz`. The default version string is `local-snapshot` for untagged builds.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema. The workflow YAML schema is documented in `docs/API.md` in the source repository.
