---
service: "optimus-prime-ui"
title: "ETL Job Authoring and Save"
generated: "2026-03-03"
type: flow
flow_name: "job-authoring"
flow_type: synchronous
trigger: "User creates or edits an ETL job"
participants:
  - "continuumOptimusPrimeUi"
  - "continuumOptimusPrimeUiRouter"
  - "continuumOptimusPrimeUiStateStore"
  - "continuumOptimusPrimeUiApiClient"
  - "continuumOptimusPrimeApi"
architecture_ref: "dynamic-continuumOptimusPrimeUi"
---

# ETL Job Authoring and Save

## Summary

A user creates or edits an ETL job by navigating to the Job view, composing a set of ordered, dependency-linked pipeline steps using the Drawflow visual DAG editor and CodeMirror SQL editor, configuring job-level settings (cron schedule, variables, email notifications, group membership), and saving. The UI submits the job definition as a structured JSON payload to `optimus-prime-api` via the API Client Layer. The backend validates and persists the job, returning the saved job record which updates the Pinia job store.

## Trigger

- **Type**: user-action
- **Source**: User navigates to the Job creation page or opens an existing job for editing
- **Frequency**: On-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| User (browser) | Composes job definition; submits save | — |
| Routing and View Composition | Renders the Job view (`src/views/job/Job.vue`) | `continuumOptimusPrimeUiRouter` |
| Application State Store | Holds draft job state; updates job list on save | `continuumOptimusPrimeUiStateStore` |
| API Client Layer | Submits job create/update via HTTPS | `continuumOptimusPrimeUiApiClient` |
| Optimus Prime API | Validates and persists the job definition | `continuumOptimusPrimeApi` |

## Steps

1. **User navigates to job creation or edit**: The router loads the `Job.vue` view; if editing, the API Client fetches the existing job definition from `/api/v1/jobs/:id` or `/api/v2/jobs/:id`.
   - From: `continuumOptimusPrimeUiRouter`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

2. **Connections list loaded**: The Job view fetches available connections from `/api/v1/connections` (or `/api/v2/connections`) to populate step source and target connection dropdowns.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

3. **User defines job steps using Drawflow**: The user adds pipeline steps (SQL, DBDataMover, RestAPITrigger, EmailSQLReport) and connects them via the visual DAG editor (`drawflow`). Each step node carries a `stepTypeName`, `srcConnectionName`, `trgConnectionName`, and `metadata` payload (e.g., `__src_db_query`, `__trg_db_table`, `__load_type`).
   - From: Browser UI (Drawflow component)
   - To: In-memory job draft in `continuumOptimusPrimeUiStateStore`
   - Protocol: In-process

4. **User edits step SQL using CodeMirror**: For SQL and DBDataMover steps, the user authors the query or stored procedure body in the embedded CodeMirror editor. Variable substitution tokens (e.g., `${runtime_date}`) are supported.
   - From: Browser UI (CodeMirror editor)
   - To: Step metadata in state store
   - Protocol: In-process

5. **User configures cron schedule**: The `JobCronSchedule` or `JobDependencySchedule` component validates the cron expression using `cron-parser` and renders a human-readable description via `cronstrue`.
   - From: Browser UI
   - To: Job draft state (cronSchedule field)
   - Protocol: In-process

6. **User configures job variables**: The user adds STANDARD, DATE, or DYNAMIC_DATE variables with names and values. Dynamic date variables support expressions like `${runtime_date}||-4d`.
   - From: Browser UI
   - To: Job draft state (variables array)
   - Protocol: In-process

7. **User saves the job**: The user submits the save action; the state store dispatches either a POST (`/api/v1/jobs`) for new jobs or a PUT (`/api/v1/jobs/:id`) for updates.
   - From: `continuumOptimusPrimeUiStateStore`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: In-process

8. **API Client submits job definition to backend**: Axios sends the structured job payload (name, cronSchedule, steps array, variables array, isEmailOnFailureRequired, isEmailOnSuccessRequired, isEnabled, groupNames) to `optimus-prime-api`.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON (POST or PUT)

9. **Backend persists and returns saved job**: The API validates the job, assigns an ID, persists the definition, and returns the saved job record.
   - From: `continuumOptimusPrimeApi`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: HTTPS/JSON

10. **State store updates job list**: The job store adds or replaces the job in the in-memory jobs collection; the UI re-renders the job list.
    - From: `continuumOptimusPrimeUiStateStore`
    - To: Browser UI (reactive)
    - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| API returns 4xx on save | Error handled by Axios interceptor; ErrorSnackbar shown | User sees error message; job not saved |
| API returns 5xx on save | Error handled by Axios interceptor; GA exception logged | User sees error snackbar; retry possible |
| Invalid cron expression | `cron-parser` rejects; UI form validation prevents submission | User corrected inline; no API call made |
| Drawflow step missing required connection | UI validation prevents submission | User corrected inline |

## Sequence Diagram

```
User -> Router: navigate to /jobs/new or /jobs/:id/edit
Router -> ApiClient: GET /api/v1/jobs/:id (edit case)
ApiClient -> OptimusPrimeApi: HTTPS GET job definition
OptimusPrimeApi --> ApiClient: job record
ApiClient -> ApiClient: GET /api/v1/connections
OptimusPrimeApi --> ApiClient: connections list
ApiClient --> JobView: render with data
User -> JobView: compose steps, set schedule, variables
User -> JobView: click Save
JobView -> JobStore: dispatch save action
JobStore -> ApiClient: POST/PUT /api/v1/jobs[/:id]
ApiClient -> OptimusPrimeApi: HTTPS POST/PUT job payload
OptimusPrimeApi --> ApiClient: saved job record
ApiClient --> JobStore: update job in store
JobStore --> JobView: reactive re-render
```

## Related

- Architecture dynamic view: `dynamic-continuumOptimusPrimeUi`
- Related flows: [Job Execution Trigger and Run Monitoring](job-execution.md)
