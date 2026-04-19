---
service: "lgtm"
title: "Trace Query and Visualization"
generated: "2026-03-03"
type: flow
flow_name: "trace-query-visualization"
flow_type: synchronous
trigger: "Engineer opens a Grafana trace search or trace detail dashboard"
participants:
  - "continuumGrafana"
  - "grafanaTraceDashboards"
  - "continuumTempo"
  - "tempoQueryApi"
  - "tempoTraceStorage"
architecture_ref: "dynamic-telemetry-ingestion-and-query-flow"
---

# Trace Query and Visualization

## Summary

This flow describes how engineers use Grafana to search for and inspect distributed traces stored in Grafana Tempo. When an engineer opens the Grafana trace search dashboard, Grafana issues a TraceQL or tag-based search query to the Tempo Query Frontend, which resolves the request across stored trace blocks in GCS. Results are returned as a paginated trace list. Clicking a trace navigates to the trace detail dashboard, which fetches the full span waterfall for a specific trace ID.

## Trigger

- **Type**: user-action
- **Source**: Engineer opens the Grafana Trace Search dashboard or follows a trace detail drill-down link
- **Frequency**: On demand — driven by engineering or SRE activity, typically during debugging or incident investigation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Grafana Trace Dashboards | Renders the trace search UI; submits queries to Tempo; displays trace results | `grafanaTraceDashboards` |
| Tempo Query Frontend API | Accepts TraceQL / HTTP search requests; shards queries to queriers | `tempoQueryApi` |
| Tempo Querier | Executes block searches against GCS and in-memory ingester data | (Tempo internal) |
| Trace Storage Backend | Provides trace blocks stored in GCS for querier reads | `tempoTraceStorage` |

## Steps

1. **Engineer opens trace search dashboard**: The engineer opens the Grafana `traces.json` dashboard (Trace Search) in their browser.
   - From: Engineer (browser)
   - To: `grafanaTraceDashboards`
   - Protocol: HTTP (Grafana UI)

2. **Grafana submits trace search query**: The Grafana Tempo datasource (UID: `tempo`) issues a search query to the Tempo Query Frontend, filtering by `service.name`, time range, and optional span-level filters.
   - From: `grafanaTraceDashboards`
   - To: `tempoQueryApi`
   - Protocol: HTTP (Tempo search API / TraceQL)

3. **Query Frontend shards request**: The Tempo Query Frontend shards the query across one or more queriers based on the time range and block layout.
   - From: `tempoQueryApi`
   - To: Tempo Queriers
   - Protocol: Internal Tempo gRPC

4. **Queriers fetch trace blocks from GCS**: Each querier reads relevant trace blocks from the GCS storage backend and searches for matching spans.
   - From: Tempo Queriers
   - To: `tempoTraceStorage` (GCS)
   - Protocol: GCS SDK

5. **Results returned to Grafana**: The Query Frontend aggregates querier results and returns a list of matching traces (trace IDs, root service, duration, timestamp) to Grafana.
   - From: `tempoQueryApi`
   - To: `grafanaTraceDashboards`
   - Protocol: HTTP (JSON)

6. **Engineer drills into trace detail**: The engineer clicks a trace in the search results list. The search dashboard links to the trace detail dashboard (`/d/cdjp318r07nr4c/03-trace-detail`) with `var-traceId` and `var-job` parameters.
   - From: Grafana trace list (traces.json dashboard)
   - To: `grafanaTraceDashboards` (trace_details.json dashboard)
   - Protocol: HTTP (browser navigation)

7. **Grafana fetches full trace by ID**: The Grafana Tempo datasource issues a fetch-by-trace-ID request to the Tempo Query Frontend.
   - From: `grafanaTraceDashboards`
   - To: `tempoQueryApi`
   - Protocol: HTTP (Tempo `GET /api/traces/<traceID>`)

8. **Tempo returns span waterfall**: The Tempo Query Frontend returns the complete span tree for the trace, which Grafana renders as a waterfall view.
   - From: `tempoQueryApi`
   - To: `grafanaTraceDashboards`
   - Protocol: HTTP (JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Tempo Query Frontend unavailable | Grafana shows datasource error in dashboard | Engineer cannot search traces; check Tempo pod status in `tempo-staging` or `tempo-production` |
| Query timeout (large time range) | Tempo applies query timeout limits | Grafana displays partial results or timeout error; engineer should narrow the time range |
| Trace ID not found | Tempo returns 404 | Grafana displays empty trace detail; trace may not have been ingested or may have been outside the retention window |
| GCS read failure during query | Querier logs GCS read errors; partial results returned | Some trace blocks may be missing from search results |

## Sequence Diagram

```
Engineer -> grafanaTraceDashboards: open trace search dashboard (HTTP)
grafanaTraceDashboards -> tempoQueryApi: search query (service.name, time range) [HTTP]
tempoQueryApi -> TempoQuerier: shard query [internal gRPC]
TempoQuerier -> tempoTraceStorage: read trace blocks [GCS SDK]
tempoTraceStorage --> TempoQuerier: trace block data
TempoQuerier --> tempoQueryApi: matching trace list
tempoQueryApi --> grafanaTraceDashboards: trace list JSON
Engineer -> grafanaTraceDashboards: click trace -> navigate to detail dashboard
grafanaTraceDashboards -> tempoQueryApi: GET /api/traces/<traceID> [HTTP]
tempoQueryApi --> grafanaTraceDashboards: full span waterfall JSON
grafanaTraceDashboards --> Engineer: renders trace detail view
```

## Related

- Architecture dynamic view: `dynamic-telemetry-ingestion-and-query-flow`
- Related flows: [Trace Storage and Compaction](trace-storage-compaction.md), [Telemetry Ingestion](telemetry-ingestion.md)
- Grafana dashboard definitions: `grafana/dashboards/traces.json`, `grafana/dashboards/trace_details.json`
- Grafana Tempo datasource UID: `tempo`
