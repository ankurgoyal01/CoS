---
service: "gazebo"
title: "Task Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "task-management"
flow_type: event-driven
trigger: "Message Bus task event received or editor manually creates a task"
participants:
  - "continuumGazeboMbusConsumer"
  - "continuumGazeboWebApp"
  - "continuumGazeboMysql"
  - "mbusSystem_18ea34"
architecture_ref: "dynamic-gazebo-task-management"
---

# Task Management

## Summary

Editorial tasks are created either via incoming Message Bus events (e.g., `goods_task`, `task_notification`) or manually by editors through the Gazebo web UI. Editors then claim tasks to assign ownership, work through the task, and mark it complete. Task state transitions are persisted to MySQL and completion events are emitted back to the Message Bus.

## Trigger

- **Type**: event (from Message Bus) or user-action (from editor)
- **Source**: Upstream systems publishing `goods_task` or `task_notification` events to Message Bus; or an editor acting via the Gazebo web UI
- **Frequency**: on-demand (per incoming event or per editor action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Upstream event producers | Publish task creation events to Message Bus | `mbusSystem_18ea34` |
| Gazebo MBus Consumer | Receives task events and creates task records | `continuumGazeboMbusConsumer` |
| Gazebo Web App | Serves task list; handles claim, unclaim, complete actions | `continuumGazeboWebApp` |
| Gazebo MySQL | Persists task state throughout lifecycle | `continuumGazeboMysql` |
| Message Bus | Delivers incoming events; receives outbound completion events | `mbusSystem_18ea34` |
| Editor (user) | Claims and completes tasks | — |

## Steps

1. **Task event arrives on Message Bus**: An upstream system publishes a `goods_task` or `task_notification` event to `mbusSystem_18ea34`.
   - From: `Upstream producer`
   - To: `mbusSystem_18ea34`
   - Protocol: message-bus

2. **MBus consumer receives event**: The `continuumGazeboMbusConsumer` subscribes to the topic and receives the event payload.
   - From: `mbusSystem_18ea34`
   - To: `continuumGazeboMbusConsumer`
   - Protocol: message-bus

3. **Task record created in MySQL**: The consumer's Task Notification Handler creates a new task record (or updates an existing one) in the `tasks` table with status `open`.
   - From: `continuumGazeboMbusConsumer`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

4. **Editor views task list**: Editor navigates to the task list via `GET /tasks` or `GET /api/tasks`.
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

5. **Web app queries tasks**: Rails queries the `tasks` table for open, unclaimed tasks matching the editor's team or role.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

6. **Editor claims task**: Editor submits a claim action via `PUT /tasks` (claim).
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

7. **Task assigned in MySQL**: Rails updates the `tasks` record with the claiming editor's user ID and sets status to `in_progress`.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

8. **Editor completes task**: After performing the editorial work, editor submits a completion action via `PUT /tasks` (complete).
   - From: `Editor (browser)`
   - To: `continuumGazeboWebApp`
   - Protocol: REST (HTTP)

9. **Task marked complete in MySQL**: Rails updates the `tasks` record with status `complete` and completion timestamp.
   - From: `continuumGazeboWebApp`
   - To: `continuumGazeboMysql`
   - Protocol: MySQL

10. **Completion event published**: Gazebo publishes a task completion event to the Message Bus to notify upstream systems.
    - From: `continuumGazeboWebApp`
    - To: `mbusSystem_18ea34`
    - Protocol: message-bus

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Task event with unknown schema | Handler logs error and discards event | Task not created; event lost unless DLQ configured |
| Duplicate task event received | Handler checks for existing task by event ID before insert | Duplicate task creation avoided (idempotency assumed by convention) |
| Editor tries to claim already-claimed task | Rails validates task is unclaimed before updating | HTTP 422 returned; editor sees current assignee |
| MySQL write failure on claim/complete | ActiveRecord exception; transaction rolled back | HTTP 500 returned; task state unchanged; editor prompted to retry |
| Message Bus publish failure on completion | Publish exception caught; task is still marked complete locally | Upstream system may not be notified; retry may be needed |

## Sequence Diagram

```
UpstreamProducer -> mbusSystem_18ea34: publish goods_task / task_notification
mbusSystem_18ea34 -> continuumGazeboMbusConsumer: deliver event
continuumGazeboMbusConsumer -> continuumGazeboMysql: insert tasks record (status: open)
continuumGazeboMysql --> continuumGazeboMbusConsumer: write confirmation
Editor -> continuumGazeboWebApp: GET /tasks (view open tasks)
continuumGazeboWebApp -> continuumGazeboMysql: query open tasks
continuumGazeboMysql --> continuumGazeboWebApp: task list
continuumGazeboWebApp --> Editor: task list response
Editor -> continuumGazeboWebApp: PUT /tasks (claim)
continuumGazeboWebApp -> continuumGazeboMysql: update tasks (status: in_progress, assignee: editor)
continuumGazeboMysql --> continuumGazeboWebApp: write confirmation
continuumGazeboWebApp --> Editor: claim confirmed
Editor -> continuumGazeboWebApp: PUT /tasks (complete)
continuumGazeboWebApp -> continuumGazeboMysql: update tasks (status: complete)
continuumGazeboMysql --> continuumGazeboWebApp: write confirmation
continuumGazeboWebApp -> mbusSystem_18ea34: publish task completion event
mbusSystem_18ea34 --> continuumGazeboWebApp: publish acknowledgement
continuumGazeboWebApp --> Editor: completion confirmed
```

## Related

- Architecture dynamic view: `dynamic-gazebo-task-management`
- Related flows: [Message Bus Event Processing](message-bus-event-processing.md), [Editorial Copy Creation](editorial-copy-creation.md)
