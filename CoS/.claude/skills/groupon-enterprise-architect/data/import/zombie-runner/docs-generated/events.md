---
service: "zombie-runner"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Zombie Runner does not publish or consume asynchronous events via a message bus, Kafka, RabbitMQ, SQS, or any other messaging system. All inter-task coordination is synchronous and internal to the running process via the DAG orchestrator. The closest equivalent to async messaging is the out-of-process MySQL metadata logging performed by `ZrHandler` / `ZrMetaTableUpdate` over a Unix pipe to a background daemon process — but this is a logging side-channel, not an event contract.

## Published Events

> No evidence found in codebase. Zombie Runner does not publish to any message bus or event topic.

## Consumed Events

> No evidence found in codebase. Zombie Runner does not subscribe to any message bus or event topic. Workflows are triggered by direct CLI invocation.

## Dead Letter Queues

> No evidence found in codebase. No DLQ pattern is used.

## Metadata Side-Channel (Internal)

While not a formal event system, Zombie Runner does asynchronously write structured records to a MySQL metadata store during workflow execution. This uses a Python `multiprocessing.Pipe` and a background daemon process (`ZrHandler` / `ZrMetaTableUpdate`).

| Record Type | Target Table | Key Fields | Trigger |
|-------------|-------------|------------|---------|
| `task_status` | `TASK_STATUS` | `job_name`, `wf_name`, `dateid`, `wf_id`, `task_name`, `status` | Task state transition |
| `workflow_status` | `WORKFLOW_STATUS` | `job_name`, `wf_name`, `dateid`, `wf_id`, `status` | Workflow state transition |
| `output_context` | `OUTPUT_CONTEXT` | `task_name`, `context_name`, `context_value` | Task emits context key |
| `output_stat` | `OUTPUT_STAT` | `task_name`, `stat_name`, `stat_value` | Task `_statput()` call |
| `source_list` | `RUN_SOURCE_LIST`, `SOURCE_LIST` | `task_name`, `stype`, `name`, `location` | Task meta_info source |
| `target_list` | `RUN_TARGET_LIST`, `TARGET_LIST` | `task_name`, `stype`, `name`, `location` | Task meta_info target |
| `workflow_metainfo` | `WORKFLOW_METAINFO` | `job_name`, `wf_name`, `meta_info` | Workflow metadata emit |

> The active Dataproc fork uses `ZrDummyMetaTableUpdate` which no-ops all database writes. The full `ZrMetaTableUpdate` path is retained for legacy compatibility.
