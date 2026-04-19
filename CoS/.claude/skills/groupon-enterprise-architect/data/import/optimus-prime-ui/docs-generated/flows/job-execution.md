---
service: "optimus-prime-ui"
title: "Job Execution Trigger and Run Monitoring"
generated: "2026-03-03"
type: flow
flow_name: "job-execution"
flow_type: event-driven
trigger: "User triggers an on-demand job run or cron schedule fires"
participants:
  - "continuumOptimusPrimeUi"
  - "continuumOptimusPrimeUiStateStore"
  - "continuumOptimusPrimeUiApiClient"
  - "continuumOptimusPrimeUiBackgroundTasks"
  - "continuumOptimusPrimeApi"
architecture_ref: "dynamic-continuumOptimusPrimeUi"
---

# Job Execution Trigger and Run Monitoring

## Summary

A user triggers an on-demand ETL job run from the Job view. The UI submits the trigger request to `optimus-prime-api`, which dispatches execution to the underlying scheduler. The UI then monitors run progress via the Background Polling Tasks component, which periodically fetches execution state updates and propagates changes to the Pinia job store via the internal EventBus. The user sees live run state updates in the Job view and run history.

## Trigger

- **Type**: user-action (on-demand) or schedule (cron-fired, reflected in job state)
- **Source**: User clicks the run/execute action in the Job view; or a cron schedule on `optimus-prime-api` fires and the background polling detects the new run
- **Frequency**: On-demand per user action; background polling runs continuously during the session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User (browser) | Initiates the trigger action | — |
| Application State Store | Holds job execution state; receives updates via EventBus | `continuumOptimusPrimeUiStateStore` |
| API Client Layer | Sends trigger request; fetches execution status polls | `continuumOptimusPrimeUiApiClient` |
| Background Polling Tasks | Timer loop that polls execution state and emits EventBus events | `continuumOptimusPrimeUiBackgroundTasks` |
| Optimus Prime API | Accepts trigger request; returns run execution records | `continuumOptimusPrimeApi` |

## Steps

1. **User triggers job execution**: User clicks the run action in the Job view. The state store dispatches a POST to the job execution endpoint.
   - From: Browser UI
   - To: `continuumOptimusPrimeUiStateStore`
   - Protocol: In-process

2. **API Client submits execution trigger**: Axios sends a POST to the backend job run endpoint (e.g., `/api/v1/jobs/:id/execute` or equivalent).
   - From: `continuumOptimusPrimeUiApiClient`
   - To: `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON (POST)

3. **Backend acknowledges and starts execution**: The API responds with the new execution record including a `dag_run_id` and initial state (`RUNNING`). The API dispatches the DAG execution to the underlying scheduler.
   - From: `continuumOptimusPrimeApi`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: HTTPS/JSON

4. **EventBus emits `onExecutionAdd`**: The API Client layer (or the trigger response handler) emits `onExecutionAdd({ execution })` on the EventBus to notify the App component of the new execution.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: EventBus -> `continuumOptimusPrimeUiBackgroundTasks`
   - Protocol: In-process (EventBus)

5. **Background task adds execution to polling set**: `tasks.executionUpdate.add(execution)` registers the execution ID for ongoing polling.
   - From: `continuumOptimusPrimeUiBackgroundTasks`
   - To: Internal polling set
   - Protocol: In-process

6. **Background task polls for execution state updates**: On each timer tick, the Background Tasks component fetches updated execution status from the backend via the API Client (GET to `/api/v1/jobs/runs/executions` or per-execution endpoint).
   - From: `continuumOptimusPrimeUiBackgroundTasks`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

7. **Backend returns updated execution state**: The API returns the current state (`RUNNING`, `SUCCESS`, `FAILED`) with step-level details and timestamps.
   - From: `continuumOptimusPrimeApi`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: HTTPS/JSON

8. **EventBus emits `onExcutionUpdate`**: The Background Tasks component emits `onExcutionUpdate({ execution })` with the latest state.
   - From: `continuumOptimusPrimeUiBackgroundTasks`
   - To: EventBus
   - Protocol: In-process (EventBus)

9. **Job store updates execution**: App's `onExcutionUpdate` listener calls `jobStore.updateJobExecution({ execution })`, updating the reactive Pinia store.
   - From: EventBus listener in `App.vue`
   - To: `continuumOptimusPrimeUiStateStore`
   - Protocol: In-process

10. **UI re-renders run state**: The Job view reactively displays the updated state (run progress bars, step logs, final state badge).
    - From: `continuumOptimusPrimeUiStateStore`
    - To: Browser UI
    - Protocol: In-process (Vue reactivity)

11. **Polling stops on terminal state**: When the execution reaches `SUCCESS` or `FAILED`, the background task removes it from the polling set.
    - From: `continuumOptimusPrimeUiBackgroundTasks`
    - To: Internal polling set
    - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Trigger POST fails (API 5xx) | Axios error interceptor; ErrorSnackbar displayed | User notified; execution not started |
| Polling request fails | Background task logs error; `onEmptyResponseBody` or `onHealthCheckError` emitted | State not updated; previous state preserved; snackbar shown |
| Execution ends in FAILED state | State store reflects FAILED; job store `lastExecutions` updated | User sees FAILED badge; can view step logs via RunHistoryDialog |
| User navigates away during run | Background tasks continue polling in background; EventBus updates state | Run state kept current; user can return to Job view to see result |

## Sequence Diagram

```
User -> JobView: click Run
JobView -> JobStore: trigger execution
JobStore -> ApiClient: POST /api/v1/jobs/:id/execute
ApiClient -> OptimusPrimeApi: HTTPS POST trigger
OptimusPrimeApi --> ApiClient: execution record (state=RUNNING)
ApiClient -> EventBus: emit onExecutionAdd
EventBus -> BackgroundTasks: add execution to poll set
loop [while state == RUNNING]
  BackgroundTasks -> ApiClient: GET /api/v1/jobs/runs/executions
  ApiClient -> OptimusPrimeApi: HTTPS GET execution status
  OptimusPrimeApi --> ApiClient: updated execution state
  ApiClient -> EventBus: emit onExcutionUpdate
  EventBus -> JobStore: updateJobExecution
  JobStore --> JobView: reactive re-render with new state
end
JobView --> User: display SUCCESS or FAILED
```

## Related

- Architecture dynamic view: `dynamic-continuumOptimusPrimeUi`
- Related flows: [Application Startup and User Profile Load](app-startup.md), [ETL Job Authoring and Save](job-authoring.md)
