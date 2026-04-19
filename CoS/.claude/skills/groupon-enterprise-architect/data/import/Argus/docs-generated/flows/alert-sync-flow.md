---
service: "argus"
title: "Alert Sync Flow"
generated: "2026-03-03"
type: flow
flow_name: "alert-sync-flow"
flow_type: batch
trigger: "Commit to master branch (changeset-gated by Jenkins) or manual ./gradlew updateAlerts* invocation"
participants:
  - "continuumArgusAlertSyncJob"
  - "argusAlertDefinitionLoader"
  - "argusAlertTemplateRenderer"
  - "argusAlertSubmitter"
  - "wavefront"
architecture_ref: "dynamic-argus-alert-sync-flow"
---

# Alert Sync Flow

## Summary

The Alert Sync Flow reads all YAML alert definition files from `src/main/resources/alerts/<env>/`, renders each alert's Wavefront condition and display expressions by substituting template variables (metric, method, threshold, colo, host), then synchronizes the rendered definitions to the Wavefront API — creating alerts that do not yet exist and updating alerts whose definition has changed. This flow is the primary mechanism by which Groupon's production monitoring configuration is kept current with the YAML source of truth in Git.

## Trigger

- **Type**: batch (CI-triggered or manual)
- **Source**: Jenkins `Jenkinsfile` — changeset-gated stage fires when files under `src/main/resources/alerts/<env>/**/*` are modified on `master` branch; operators may also run `./gradlew updateAlerts<Environment>` directly
- **Frequency**: On every qualifying merge to `master`; also on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Alert Sync Job | Orchestrates the full sync lifecycle | `continuumArgusAlertSyncJob` |
| Alert Definition Loader | Reads and parses YAML definition files | `argusAlertDefinitionLoader` |
| Alert Template Renderer | Renders Wavefront TS condition and display expressions | `argusAlertTemplateRenderer` |
| Alert Submitter | Performs create/update via Wavefront REST API | `argusAlertSubmitter` |
| Wavefront | External monitoring platform; target of all API calls | `wavefront` |

## Steps

1. **Resolve alert directory**: The Gradle task passes a `-d alerts/<env>` argument to `alerts-builder.groovy`. The script resolves the directory path from the classpath resources root.
   - From: `continuumArgusAlertSyncJob` (Gradle task invocation)
   - To: `argusAlertDefinitionLoader`
   - Protocol: In-process (CLI argument parsing via `CliBuilder`)

2. **Recurse and parse YAML files**: `Alert Definition Loader` walks all files in the resolved directory using `FileType.FILES` recursion. Each file is parsed by SnakeYAML into a Groovy map containing `host`, `colo`, `template`, `displayExpression`, `target`, `tags`, `servers`, and the `alerts` list.
   - From: `argusAlertDefinitionLoader`
   - To: File system (`src/main/resources/alerts/<env>/`)
   - Protocol: Groovy File I/O

3. **Expand per-server alerts**: For each alert instance in the `alerts` list, if the YAML file defines `servers: N`, the loader generates one alert definition per server (e.g., `api-lazlo-app1` through `api-lazlo-app50`), cloning the alert map and injecting a per-host `name` prefix.
   - From: `argusAlertDefinitionLoader`
   - To: `argusAlertTemplateRenderer`
   - Protocol: In-process (Groovy list)

4. **Render template expressions**: `Alert Template Renderer` applies `SimpleTemplateEngine` to the `template` and `displayExpression` strings from each YAML file, substituting variables: `${metric}`, `${method}`, `${threshold}`, `${colo}`, `${host}`, `${httpMethod}`, `${clientName}`. The rendered strings become the `condition` and `displayExpression` fields of the alert payload.
   - From: `argusAlertTemplateRenderer`
   - To: `argusAlertSubmitter`
   - Protocol: In-process (Groovy map list)

5. **Search for existing alert**: For each rendered alert definition, `Alert Submitter` sends `POST /api/v2/search/alert` to Wavefront with a body containing an `EXACT` name match query. The response includes `totalItems` and `items`.
   - From: `argusAlertSubmitter`
   - To: `wavefront` (`POST https://groupon.wavefront.com/api/v2/search/alert`)
   - Protocol: REST / HTTPS (HTTPBuilder, `Authorization: Bearer <token>`)

6. **Create or update**:
   - If `totalItems == 0`: Sends `POST /api/v2/alert` with the full alert payload to create a new alert. Logs `SUCCESS: Create alert <name>`.
   - If `totalItems == 1`: Compares the rendered payload against the existing alert's fields (`name`, `condition`, `minutes`, `target`, `severity`, `tags`, `displayExpression`, `resolveAfterMinutes`). If any field differs, sends `PUT /api/v2/alert/:id` to update. Logs `SUCCESS: Updated alert <name>`.
   - If `totalItems > 1`: Throws an exception — duplicate alert names are not allowed.
   - From: `argusAlertSubmitter`
   - To: `wavefront` (`POST /api/v2/alert` or `PUT /api/v2/alert/:id`)
   - Protocol: REST / HTTPS (HTTPBuilder, `Authorization: Bearer <token>`, `Accept: application/json`)

7. **Log completion**: After processing all definitions, prints `done` to stdout. Jenkins captures the exit code; non-zero exits fail the pipeline stage.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wavefront API returns 4xx/5xx on create | Logs `Failure: create failed <status>` + response body to stdout | Alert not created; execution continues for remaining definitions; CI stage may still pass |
| Wavefront API returns 4xx/5xx on update | Logs `Failure: update failed <status>` + response body to stdout | Alert not updated; execution continues |
| More than one alert with same name exists in Wavefront | Throws `Exception: Found more than one alert with name: <name>` | Script terminates; all subsequent alerts in batch are not processed |
| YAML file cannot be parsed | SnakeYAML throws parse exception | Script terminates immediately |
| Alert directory does not exist | Prints error and calls `System.exit(1)` | Script exits with failure |

## Sequence Diagram

```
Jenkins -> continuumArgusAlertSyncJob: ./gradlew updateAlerts<Environment>
continuumArgusAlertSyncJob -> argusAlertDefinitionLoader: resolve directory, recurse YAML files
argusAlertDefinitionLoader -> argusAlertTemplateRenderer: parsed alert definitions (list)
argusAlertTemplateRenderer -> argusAlertSubmitter: rendered alert payloads (list)
argusAlertSubmitter -> wavefront: POST /api/v2/search/alert (name match)
wavefront --> argusAlertSubmitter: { totalItems, items[] }
alt alert not found
  argusAlertSubmitter -> wavefront: POST /api/v2/alert
  wavefront --> argusAlertSubmitter: 200 OK
else alert found and different
  argusAlertSubmitter -> wavefront: PUT /api/v2/alert/:id
  wavefront --> argusAlertSubmitter: 200 OK
else alert found and same
  argusAlertSubmitter -> argusAlertSubmitter: skip (no change)
end
continuumArgusAlertSyncJob -> Jenkins: exit 0 (done)
```

## Related

- Architecture dynamic view: `dynamic-argus-alert-sync-flow`
- Related flows: [Dashboard Sync Flow](dashboard-sync-flow.md), [Alert Summary Report Flow](alert-summary-report-flow.md)
