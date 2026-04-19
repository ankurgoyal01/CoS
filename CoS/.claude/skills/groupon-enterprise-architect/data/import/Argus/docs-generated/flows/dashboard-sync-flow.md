---
service: "argus"
title: "Dashboard Sync Flow"
generated: "2026-03-03"
type: flow
flow_name: "dashboard-sync-flow"
flow_type: batch
trigger: "Manual ./gradlew apiLazlo or ./gradlew apiProxy invocation, or CI BUILD-PROJECT stage when non-alert code changes"
participants:
  - "continuumArgusDashboardSyncJob"
  - "argusDashboardTemplateLoader"
  - "argusDashboardChartBuilder"
  - "argusDashboardSubmitter"
  - "wavefront"
architecture_ref: "dynamic-argus-alert-sync-flow"
---

# Dashboard Sync Flow

## Summary

The Dashboard Sync Flow constructs and pushes Wavefront dashboard payloads based on live metrics discovered from Wavefront and dashboard layout definitions stored in YAML. The job queries Wavefront for active metric time series matching configured patterns, matches those metrics against graph definitions and SLA configurations, assembles structured dashboard section/chart objects, then submits the completed payload to the Wavefront dashboard API. This keeps service performance dashboards in Wavefront aligned with the actual set of metrics being emitted by the monitored services.

## Trigger

- **Type**: batch (manual or CI-triggered)
- **Source**: Manual invocation via `./gradlew apiLazlo` or `./gradlew apiProxy` (passing a specific definition YAML); also triggered by the `BUILD-PROJECT` Jenkins stage when non-alert files change on `master`
- **Frequency**: On-demand or when non-alert code changes are merged to `master`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dashboard Sync Job | Orchestrates discovery, assembly, and submission | `continuumArgusDashboardSyncJob` |
| Dashboard Definition Loader | Loads YAML graph definitions, SLA config, and chart templates | `argusDashboardTemplateLoader` |
| Dashboard Payload Builder | Queries metrics from Wavefront, assembles chart and section payloads | `argusDashboardChartBuilder` |
| Dashboard Submitter | POSTs completed dashboard payloads to Wavefront | `argusDashboardSubmitter` |
| Wavefront | Provides live metric time series; stores updated dashboards | `wavefront` |

## Steps

1. **Load chart templates**: `Dashboard Definition Loader` scans the `templates/` resource directory, loading each `.yml` file as a chart template (type + named TS query strings). Template query strings are pre-compiled as Groovy `SimpleTemplateEngine` templates.
   - From: `argusDashboardTemplateLoader`
   - To: File system (`src/main/resources/templates/*.yml`)
   - Protocol: Groovy File I/O / SnakeYAML

2. **Load SLA definitions**: Reads `src/main/resources/definitions/clientsSLA.yml`, which maps service name and method to SLA threshold values. These thresholds are injected into chart queries for SLA-aware visualizations.
   - From: `argusDashboardTemplateLoader`
   - To: File system (`src/main/resources/definitions/clientsSLA.yml`)
   - Protocol: Groovy File I/O / SnakeYAML

3. **Load graph definitions**: Reads the definition YAML file specified by the `-d` CLI argument (e.g., `definitions/api-lazlo.yml`). This file defines `definitions` (cluster, hosts, colos) and `graphDefs` (graph groups with match/extract regexes and chart templates).
   - From: `argusDashboardTemplateLoader`
   - To: File system
   - Protocol: Groovy File I/O / SnakeYAML

4. **Query live Wavefront metrics**: `Dashboard Payload Builder` calls `GET /chart/api` on Wavefront with a wildcard `ts("*", source=<hosts>)` query scoped to the past 10 minutes, requesting time series labels in list mode. This discovers what metrics are actively being emitted.
   - From: `argusDashboardChartBuilder`
   - To: `wavefront` (`GET https://groupon.wavefront.com/chart/api`)
   - Protocol: REST / HTTPS (`X-AUTH-TOKEN` header)

5. **Match metrics to graph definitions**: For each graph definition group, the builder filters the discovered metric labels using the group's `matchRegex` and extracts template field values (e.g., `svcName`, `methodName`) using `extractRegex`. Matches that have corresponding SLA definitions are retained.

6. **Assemble chart payloads**: For each matched metric/SLA combination, the builder renders chart `name`, `description`, and TS `query` strings by substituting template fields (including SLA thresholds). Charts are grouped into named dashboard sections. Rows are laid out in groups of up to 3 charts per row.
   - From: `argusDashboardChartBuilder`
   - To: `argusDashboardSubmitter`
   - Protocol: In-process (Groovy map)

7. **Build dashboard payload**: The builder constructs the full Wavefront dashboard JSON payload including:
   - `customer: "groupon"`
   - `url` (derived from dashboard name via `name_to_url()` — lowercase, spaces replaced with `-`)
   - `parameterDetails` for host, colo, and timeRange list parameters
   - `sections` with `rows` of `charts`
   - Chart settings: `summarization: MEAN`, `interpolatePoints: false`, `noDefaultEvents: false`

8. **Submit dashboard to Wavefront**: `Dashboard Submitter` sends `POST /api/dashboard` for each assembled dashboard payload.
   - From: `argusDashboardSubmitter`
   - To: `wavefront` (`POST https://groupon.wavefront.com/api/dashboard`)
   - Protocol: REST / HTTPS (`X-AUTH-TOKEN` header, JSON body)
   - On success: Logs `SUCCESS: Updated dashboard <name>`
   - On failure: Logs `request failed <status>` and the response body

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wavefront metric query fails | HTTPBuilder throws exception | Script terminates; no dashboards submitted |
| No metrics match a graph definition | Empty chart list for that group | Section is omitted from the dashboard payload |
| Dashboard submission returns non-2xx | Logs `request failed <status>` + response body | That dashboard not updated; execution continues for other dashboards |
| Definition or template file not found | Prints error and exits with code 1 | Script terminates before any API calls |

## Sequence Diagram

```
Operator -> continuumArgusDashboardSyncJob: ./gradlew apiLazlo (or apiProxy)
continuumArgusDashboardSyncJob -> argusDashboardTemplateLoader: load templates, SLA definitions, graph definitions
argusDashboardTemplateLoader --> argusDashboardChartBuilder: templates, slaDefinitions, graphDefs, definitions
argusDashboardChartBuilder -> wavefront: GET /chart/api?q=ts("*", source=<hosts>)
wavefront --> argusDashboardChartBuilder: { timeseries: [ { label, ... } ] }
argusDashboardChartBuilder -> argusDashboardChartBuilder: match metrics, render chart payloads, assemble sections
argusDashboardChartBuilder -> argusDashboardSubmitter: dashboard payload map
argusDashboardSubmitter -> wavefront: POST /api/dashboard (JSON body)
wavefront --> argusDashboardSubmitter: 200 OK
continuumArgusDashboardSyncJob -> Operator: done (stdout)
```

## Related

- Architecture dynamic view: `dynamic-argus-alert-sync-flow`
- Related flows: [Alert Sync Flow](alert-sync-flow.md), [Alert Summary Report Flow](alert-summary-report-flow.md)
