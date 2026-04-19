---
service: "argus"
title: "Alert Summary Report Flow"
generated: "2026-03-03"
type: flow
flow_name: "alert-summary-report-flow"
flow_type: scheduled
trigger: "Jenkins TimerTrigger (scheduled CI run) or ./gradlew showAlertSummary"
participants:
  - "continuumArgusSummaryReportJob"
  - "argusSummaryQueryBuilder"
  - "argusSummaryReporter"
  - "wavefront"
architecture_ref: "dynamic-argus-alert-sync-flow"
---

# Alert Summary Report Flow

## Summary

The Alert Summary Report Flow identifies the most frequently firing production alerts over the past week by querying Wavefront's `flapping()` function for each known alert. It loads all production alert definitions from the YAML files (the same definitions used by the Alert Sync Flow), constructs a firing-frequency query per alert, fetches the result from Wavefront, and prints a ranked list of alerts that exceeded a configurable firing threshold to stdout. Operators use this report to identify noisy or misconfigured alerts that should be tuned.

## Trigger

- **Type**: scheduled (and on-demand)
- **Source**: Jenkins `TimerTrigger` executes the `SHOW-ALERT-SUMMARY` stage, which runs `./gradlew showAlertSummary`; operators may also invoke it directly
- **Frequency**: Scheduled (timer-driven in Jenkins); also on-demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Alert Summary Job | Orchestrates the summary report lifecycle | `continuumArgusSummaryReportJob` |
| Summary Query Builder | Builds flapping queries per alert ID | `argusSummaryQueryBuilder` |
| Summary Reporter | Fetches query results and filters by threshold | `argusSummaryReporter` |
| Wavefront | Executes firing-frequency queries; returns time series data | `wavefront` |

## Steps

1. **Load all production alert definitions**: The summary report runs `alerts-builder.groovy` with the `-s` (summary) and `-t <threshold>` flags. It first processes all alert definitions using the same `FileType.FILES` recursion and SnakeYAML parsing as the Alert Sync Flow. Alerts with `"staging"` in their name are skipped during summary mode.
   - From: `continuumArgusSummaryReportJob` (Gradle `showAlertSummary` task — `args("-s", "-t5")`)
   - To: `argusSummaryQueryBuilder`
   - Protocol: In-process (CLI argument `-s -t5`)

2. **Search Wavefront for each alert's ID**: For each production alert definition, the job sends `POST /api/v2/search/alert` with an exact name match to retrieve the Wavefront alert ID.
   - From: `argusSummaryQueryBuilder`
   - To: `wavefront` (`POST https://groupon.wavefront.com/api/v2/search/alert`)
   - Protocol: REST / HTTPS (`Authorization: Bearer <token>`)

3. **Build flapping query**: Using the Wavefront alert ID obtained in step 2, `Summary Query Builder` constructs the query:
   ```
   flapping(1w, -1*ts(~alert.isfiring.<alertId>))
   ```
   This measures how many times the alert transitioned from non-firing to firing over the past week.
   - From: `argusSummaryQueryBuilder`
   - To: `argusSummaryReporter`
   - Protocol: In-process (Groovy string)

4. **Execute firing-frequency query**: `Summary Reporter` calls `GET /chart/api` on Wavefront with the flapping query, scoped to 3 minutes ago (to get the most recent result):
   - Query params: `q=flapping(1w, -1*ts(~alert.isfiring.<alertId>))`, `g=m`, `s=<3_minutes_ago>`, `listMode=true`, `sorted=false`
   - From: `argusSummaryReporter`
   - To: `wavefront` (`GET https://groupon.wavefront.com/chart/api`)
   - Protocol: REST / HTTPS (`X-AUTH-TOKEN` header)

5. **Extract firing count and alert name**: The reporter reads `response["timeseries"][-1]["data"][0][1]` for the firing count and `response["timeseries"][-1]["tags"]["alertName"]` for the display name.
   - From: `argusSummaryReporter`
   - To: in-memory map

6. **Filter by threshold and print ranked summary**: After processing all alerts, the reporter sorts the `alertSummary` map by descending firing count and prints:
   ```
   Alert <name> has fired <count> times
   ...
   Summary: {<name>=<count>, ...}
   ```
   Only alerts with `firingCounts > threshold` (default `5`, from `showAlertSummary` task argument `-t5`) are included in the final summary.
   - From: `argusSummaryReporter`
   - To: Stdout / Jenkins CI log

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wavefront search returns no alert ID | Alert not found; `constructAlertSummary` is not called | Alert is silently skipped in summary |
| Wavefront `chart/api` query fails | HTTPBuilder throws exception | Script terminates; partial summary may have been printed |
| Alert name contains `"staging"` | Skipped in summary mode (`if (options.s && !definition["name"].contains("staging"))`) | Staging alerts never appear in summary report |
| Firing count below threshold | Alert not added to `alertSummary` map | Alert does not appear in final ranked summary output |

## Sequence Diagram

```
Jenkins TimerTrigger -> continuumArgusSummaryReportJob: ./gradlew showAlertSummary (-s -t5)
continuumArgusSummaryReportJob -> argusSummaryQueryBuilder: load all production alert definitions
argusSummaryQueryBuilder -> wavefront: POST /api/v2/search/alert (name=EXACT match)
wavefront --> argusSummaryQueryBuilder: { items: [{ id, name }] }
argusSummaryQueryBuilder -> argusSummaryReporter: alertId, rendered flapping query
argusSummaryReporter -> wavefront: GET /chart/api?q=flapping(1w, -1*ts(~alert.isfiring.<alertId>))
wavefront --> argusSummaryReporter: { timeseries: [{ tags: { alertName }, data: [[ts, count]] }] }
argusSummaryReporter -> argusSummaryReporter: filter by threshold (> 5)
argusSummaryReporter -> Jenkins log: print "Alert <name> has fired <count> times"
continuumArgusSummaryReportJob -> Jenkins log: print sorted Summary map
```

## Related

- Architecture dynamic view: `dynamic-argus-alert-sync-flow`
- Related flows: [Alert Sync Flow](alert-sync-flow.md), [Dashboard Sync Flow](dashboard-sync-flow.md)
