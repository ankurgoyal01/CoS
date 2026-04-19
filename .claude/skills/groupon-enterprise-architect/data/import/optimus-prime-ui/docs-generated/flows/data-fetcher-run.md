---
service: "optimus-prime-ui"
title: "Data Fetcher Run"
generated: "2026-03-03"
type: flow
flow_name: "data-fetcher-run"
flow_type: event-driven
trigger: "User initiates an ad-hoc data fetch operation"
participants:
  - "continuumOptimusPrimeUi"
  - "continuumOptimusPrimeUiStateStore"
  - "continuumOptimusPrimeUiApiClient"
  - "continuumOptimusPrimeUiBackgroundTasks"
  - "continuumOptimusPrimeApi"
architecture_ref: "dynamic-continuumOptimusPrimeUi"
---

# Data Fetcher Run

## Summary

The Data Fetcher feature allows users to execute a one-off DBDATAMOVER step that reads from a source database connection (POSTGRES, MYSQL, etc.) and writes results to a target (GoogleSheet or S3). The user configures the source query and target destination in the DataFetcher view, submits the run, and monitors progress via the background polling task. The run record (with `runId`, `status`, and step-level details) is returned from `/api/v2/datafetcher`.

## Trigger

- **Type**: user-action
- **Source**: User navigates to the DataFetcher view and initiates a run
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User (browser) | Configures and submits the data fetch | — |
| Application State Store | Holds datafetcher run state; updated on polling events | `continuumOptimusPrimeUiStateStore` |
| API Client Layer | Submits the datafetcher run request and polls status | `continuumOptimusPrimeUiApiClient` |
| Background Polling Tasks | Polls datafetcher run state and emits EventBus events | `continuumOptimusPrimeUiBackgroundTasks` |
| Optimus Prime API | Accepts the datafetcher run; executes the DBDATAMOVER step | `continuumOptimusPrimeApi` |

## Steps

1. **User opens DataFetcher view**: Router navigates to the DataFetcher page (`src/views/datafetcher/DataFetcher.vue`); the existing list of runs is loaded from `GET /api/v2/datafetcher`.
   - From: `continuumOptimusPrimeUiRouter`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

2. **User selects source connection and enters query**: The user picks a database connection from the connections list and writes a SQL query (e.g., `select * from public.employees`). Connection types supported include POSTGRES, MYSQL, Teradata, etc.
   - From: Browser UI (`DataFetcher.vue`)
   - To: In-memory form state
   - Protocol: In-process

3. **User selects target type**: The user chooses GOOGLESHEET (specifying a sheet URL and tab name and publish strategy) or S3 (specifying delimiter, quoting, header options). The `FileTarget.vue` component handles S3 target configuration.
   - From: Browser UI
   - To: In-memory form state
   - Protocol: In-process

4. **User submits the data fetch run**: The state store dispatches a POST to `/api/v2/datafetcher` with the step definition (sourceConnection, targetConnection, type=DBDATAMOVER).
   - From: `continuumOptimusPrimeUiStateStore`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: In-process

5. **API Client submits datafetcher run request**: Axios sends the POST to `optimus-prime-api` via the nginx `/api/v2/datafetcher` proxy.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON (POST)

6. **Backend acknowledges and returns run ID**: The API creates the run record, assigns a `runId` (UUID), sets initial `status: RUNNING`, and returns the record.
   - From: `continuumOptimusPrimeApi`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: HTTPS/JSON

7. **EventBus emits `onDatafetcherAdd`**: The response handler emits `onDatafetcherAdd({ runId })` to register the run for background polling.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: EventBus -> `App.vue` listener -> `continuumOptimusPrimeUiBackgroundTasks`
   - Protocol: In-process (EventBus)

8. **Background task polls datafetcher status**: On each timer tick, the Background Tasks component fetches updated run status from `/api/v2/datafetcher` (or a per-run endpoint).
   - From: `continuumOptimusPrimeUiBackgroundTasks`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

9. **EventBus emits `onDatafetcherUpdate`**: On each poll, the background task emits `onDatafetcherUpdate({ datafetcher })` with the updated run record.
   - From: `continuumOptimusPrimeUiBackgroundTasks`
   - To: EventBus
   - Protocol: In-process (EventBus)

10. **Datafetcher store updates run state**: The `datafetcherStore.updateDatafetcher({ datafetcher })` call updates the reactive store; the DataFetcher list view re-renders showing current status (`RUNNING`, `SUCCEEDED`, `FAILED`).
    - From: `continuumOptimusPrimeUiStateStore`
    - To: Browser UI
    - Protocol: In-process (Vue reactivity)

11. **User downloads results (optional)**: For runs that produced downloadable output, the user can fetch results via `GET /api/v2/datafetcher/download`.
    - From: `continuumOptimusPrimeUiApiClient`
    - To: `continuumOptimusPrimeApi`
    - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| POST to `/api/v2/datafetcher` fails | Axios error interceptor; ErrorSnackbar shown | Run not created; user can retry |
| Run ends with `status: FAILED` | Polling detects terminal state; store updated | User sees FAILED status in list; step logs available in run details |
| Source connection unreachable (backend-side) | Backend sets run status to FAILED | User sees FAILED with step logs explaining the failure |
| GoogleSheet permission denied | Backend sets run status to FAILED | User may need to update sheet sharing; `GoogleSheetPermissions.vue` component assists |

## Sequence Diagram

```
User -> DataFetcherView: configure source + target, submit
DataFetcherView -> DatafetcherStore: dispatch run
DatafetcherStore -> ApiClient: POST /api/v2/datafetcher
ApiClient -> OptimusPrimeApi: HTTPS POST run config
OptimusPrimeApi --> ApiClient: { runId, status: RUNNING }
ApiClient -> EventBus: emit onDatafetcherAdd(runId)
EventBus -> App: listener -> BackgroundTasks.add(runId)
loop [while status == RUNNING]
  BackgroundTasks -> ApiClient: GET /api/v2/datafetcher
  ApiClient -> OptimusPrimeApi: HTTPS GET runs
  OptimusPrimeApi --> ApiClient: run list with updated status
  ApiClient -> EventBus: emit onDatafetcherUpdate
  EventBus -> DatafetcherStore: updateDatafetcher
  DatafetcherStore --> DataFetcherView: reactive re-render
end
User -> DataFetcherView: sees SUCCEEDED or FAILED
User -> ApiClient: GET /api/v2/datafetcher/download (optional)
```

## Related

- Architecture dynamic view: `dynamic-continuumOptimusPrimeUi`
- Related flows: [Job Execution Trigger and Run Monitoring](job-execution.md)
