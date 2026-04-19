---
service: "sem-blacklist-service"
title: "Asana Task Processing"
generated: "2026-03-03"
type: flow
flow_name: "asana-task-processing"
flow_type: scheduled
trigger: "Quartz job (DenylistAsanaTaskProcessingJob) or POST /denylist/process-asana-tasks"
participants:
  - "continuumSemBlacklistService"
  - "continuumSemBlacklistPostgres"
architecture_ref: "dynamic-asana-task-processing"
---

# Asana Task Processing

## Summary

SEM campaign managers submit Asana tasks to request denylist changes. The SEM Blacklist Service polls the configured Asana project section on a recurring Quartz schedule (and can also be triggered manually via `POST /denylist/process-asana-tasks`). For each open task with a `Service Status` custom field set to `ADD_REQUEST` or `DELETE_REQUEST`, the service validates the task data, applies the corresponding database operation, and updates the Asana task status and completion flag. Tasks with invalid or incomplete data are marked `INVALID_DATA` in Asana without modifying the database.

## Trigger

- **Type**: schedule (Quartz job) or manual (api-call)
- **Source**: Quartz scheduler (`DenylistAsanaTaskProcessingJob`) running on a configured cron schedule; or `POST /denylist/process-asana-tasks` endpoint
- **Frequency**: Scheduled (interval configured in Quartz/JTier YAML config); also on-demand via HTTP trigger

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler | Triggers job on schedule | `continuumSemBlacklistService` (`asanaTaskJob`) |
| DenylistAsanaTaskProcessingJob | Entry point — retrieves processor from scheduler context and invokes processing | `continuumSemBlacklistService` (`asanaTaskJob`) |
| DenylistAsanaTaskProcessor | Core logic — fetches tasks, validates data, dispatches add/delete operations, updates Asana | `continuumSemBlacklistService` (`asanaTaskProcessor`) |
| AsanaClient | HTTP client — pages through open tasks in the section and updates task status/completion | `continuumSemBlacklistService` (`asanaClient`) |
| Asana REST API | External — stores the task board; source of denylist change requests | `asanaApi` (external stub) |
| RawBlacklistDAO | Persists the denylist change to the database | `continuumSemBlacklistService` (`blacklistDao`) |
| SEM Blacklist Postgres | Stores denylist entries | `continuumSemBlacklistPostgres` |

## Steps

1. **Quartz job fires**: `DenylistAsanaTaskProcessingJob.execute()` is called by the Quartz scheduler on schedule. It retrieves the `DenylistAsanaTaskProcessor` from the scheduler context.
   - From: Quartz Scheduler
   - To: `asanaTaskJob`
   - Protocol: direct (Quartz `Job.execute`)

2. **Fetches all open tasks from Asana section**: `AsanaClient.fetchOpenTasksFromSection()` sends a paginated `GET https://app.asana.com/api/1.0/sections/{sectionGid}/tasks?completed_since=now&opt_fields=name,created_at,completed,resource_subtype,custom_fields` using Bearer token auth. Pages through all results until `nextPage` is null.
   - From: `asanaClient`
   - To: Asana REST API
   - Protocol: HTTPS / REST

3. **Filters tasks by status**: Open, incomplete, default-subtype tasks are partitioned into `addTasks` (custom field `Service Status = ADD_REQUEST`) and `deleteTasks` (custom field `Service Status = DELETE_REQUEST`).
   - From: `asanaTaskProcessor`
   - To: `asanaTaskProcessor`
   - Protocol: direct

4. **Validates and extracts denylist data from each task**: For each task, `validateAndExtractData()` reads custom fields (`Country`, `Deal permalink`, `Program`, `Channel`, `PLA Deals`, `RTC Deal`, `Google Things ToDo Deal`). Valid tasks must have a non-blank deal permalink, an allowed program (`rtc`), an allowed channel (`g1`), a recognized country code, and at least one client flag set to `YES`. Produces one `DenylistAsanaData` record per client type.
   - From: `asanaTaskProcessor`
   - To: `asanaTaskProcessor`
   - Protocol: direct

5. **Applies database operation**:
   - For add tasks: calls `RawBlacklistDAO.insertAll(entities)` to insert new or reactivate existing entries.
   - For delete tasks: calls `RawBlacklistDAO.deletePrevious(entities, user, eventDate)` to soft-delete matching entries.
   - From: `asanaTaskProcessor`
   - To: `blacklistDao` → `continuumSemBlacklistPostgres`
   - Protocol: JDBC / SQL

6. **Updates Asana task status and closes task**:
   - On successful add: `AsanaClient.updateTask(task, PROCESSED, closeTask=true)` — sets `Service Status` to `PROCESSED` and marks task `completed = true`.
   - On successful delete: `AsanaClient.updateTask(task, DELETED, closeTask=true)`.
   - On invalid data: `AsanaClient.updateTask(task, INVALID_DATA, closeTask=false)` — leaves task open.
   - `PUT https://app.asana.com/api/1.0/tasks/{taskGid}` with updated custom fields and completion flag.
   - From: `asanaClient`
   - To: Asana REST API
   - Protocol: HTTPS / REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Asana API returns non-200 on task fetch | `IOException` thrown; caught at batch level as `AsanaTaskProcessingFatalError` | Entire run aborted; logged; retried on next schedule |
| Task has invalid or incomplete custom field data | `INVALID_DATA` status set on Asana task; no DB write | Task remains open in Asana for human review |
| Database `IOException` on insert/delete | Logged as `TransientDatabaseError` per task; loop continues | Task not updated in Asana; entry may need reprocessing |
| Unexpected exception per task | Logged as `AsanaTaskProcessingError`; loop continues to next task | Individual task skipped; others processed normally |
| Asana API returns non-200 on task update | `IOException` thrown; logged as `AsanaUpdateError` | DB change persisted; task status not updated in Asana |

## Sequence Diagram

```
QuartzScheduler -> DenylistAsanaTaskProcessingJob: execute()
DenylistAsanaTaskProcessingJob -> DenylistAsanaTaskProcessor: processDenylistingTasks()
DenylistAsanaTaskProcessor -> AsanaClient: fetchOpenTasksFromSection()
AsanaClient -> AsanaAPI: GET /sections/{sectionGid}/tasks?completed_since=now&...
AsanaAPI --> AsanaClient: paginated task list
AsanaClient --> DenylistAsanaTaskProcessor: List<AsanaTask> (filtered: not completed, default subtype)
DenylistAsanaTaskProcessor -> DenylistAsanaTaskProcessor: partition by Service Status (ADD_REQUEST / DELETE_REQUEST)
loop for each ADD task
  DenylistAsanaTaskProcessor -> DenylistAsanaTaskProcessor: validateAndExtractData(task)
  DenylistAsanaTaskProcessor -> RawBlacklistDAO: insertAll(entities)
  RawBlacklistDAO -> sem_raw_blacklist: INSERT / UPDATE (conditional)
  DenylistAsanaTaskProcessor -> AsanaClient: updateTask(task, PROCESSED, close=true)
  AsanaClient -> AsanaAPI: PUT /tasks/{taskGid}
end
loop for each DELETE task
  DenylistAsanaTaskProcessor -> DenylistAsanaTaskProcessor: validateAndExtractData(task)
  DenylistAsanaTaskProcessor -> RawBlacklistDAO: deletePrevious(entities, user, date)
  RawBlacklistDAO -> sem_raw_blacklist: UPDATE SET active=FALSE
  DenylistAsanaTaskProcessor -> AsanaClient: updateTask(task, DELETED, close=true)
  AsanaClient -> AsanaAPI: PUT /tasks/{taskGid}
end
```

## Related

- Architecture dynamic view: `dynamic-asana-task-processing`
- Related flows: [Denylist Entry Write](denylist-write.md), [Flows Index](index.md)
