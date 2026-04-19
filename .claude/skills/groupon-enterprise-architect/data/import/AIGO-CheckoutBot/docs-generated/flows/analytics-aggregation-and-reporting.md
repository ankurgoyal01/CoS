---
service: "AIGO-CheckoutBot"
title: "Analytics Aggregation and Reporting"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "analytics-aggregation-and-reporting"
flow_type: scheduled
trigger: "Periodic schedule or manual request from the Admin Frontend to aggregate conversation analytics"
participants:
  - "continuumAigoAdminFrontend"
  - "continuumAigoCheckoutBackend"
  - "continuumAigoPostgresDb"
architecture_ref: "dynamic-aigoCheckoutBackendComponents"
---

# Analytics Aggregation and Reporting

## Summary

The Analytics Aggregation and Reporting flow produces aggregated metrics and reports from raw conversation event data. The `backendSimulationAndAnalytics` component reads event records written to the `ng_analytics` schema during conversation turn processing, aggregates them into summary metrics (e.g., conversation completion rates, escalation rates, node traversal counts), and makes the results available through the `/api/analytics` endpoints. Reports can be triggered on a schedule or on demand by an admin operator from the Admin Frontend.

## Trigger

- **Type**: schedule or user-action
- **Source**: Periodic schedule (interval not specified in inventory) or admin operator requests a report from `continuumAigoAdminFrontend`
- **Frequency**: Scheduled (interval to be confirmed by service owner) or on demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AIGO Admin Frontend | Requests analytics reports and renders results for operators | `continuumAigoAdminFrontend` |
| AIGO Checkout Backend | Runs aggregation queries and formats report data | `continuumAigoCheckoutBackend` |
| AIGO PostgreSQL | Source of raw analytics events (`ng_analytics`) and target for aggregated reports | `continuumAigoPostgresDb` |

## Steps

1. **Triggers analytics request**: Either a schedule fires within `backendSimulationAndAnalytics`, or an admin operator requests a report from the Admin Frontend.
   - From: Scheduler (internal) or Operator (browser)
   - To: `continuumAigoCheckoutBackend` (`GET /api/analytics/reports` or internal schedule trigger)
   - Protocol: REST/HTTPS (JWT, if operator-initiated) or internal schedule

2. **Routes to analytics service**: `backendApiLayer` routes the request to `backendSimulationAndAnalytics`.
   - From: `backendApiLayer`
   - To: `backendSimulationAndAnalytics`
   - Protocol: direct (in-process)

3. **Reads raw analytics events**: `backendDataAccess` queries the `ng_analytics` schema in PostgreSQL to retrieve raw conversation event records for the target time window and project scope.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_analytics schema)
   - Protocol: PostgreSQL

4. **Aggregates metrics**: `backendSimulationAndAnalytics` computes aggregated metrics from the raw events — including conversation volume, completion rates, escalation rates, node traversal frequency, and response latency distributions.
   - From: `backendSimulationAndAnalytics`
   - To: (in-process computation)
   - Protocol: direct (in-process)

5. **Writes aggregated report**: `backendDataAccess` persists the computed report record back to PostgreSQL (`ng_analytics` schema) for caching and later retrieval.
   - From: `backendSimulationAndAnalytics` via `backendDataAccess`
   - To: `continuumAigoPostgresDb` (ng_analytics schema)
   - Protocol: PostgreSQL

6. **Returns report to caller**: The backend returns the aggregated analytics report as a JSON response to the Admin Frontend or acknowledges completion for scheduled runs.
   - From: `continuumAigoCheckoutBackend`
   - To: `continuumAigoAdminFrontend` (if operator-initiated)
   - Protocol: REST/HTTPS (JSON response)

7. **Renders analytics dashboard**: The Admin Frontend displays the report metrics and charts to the operator via `adminUiShell`.
   - From: `adminApiClients`
   - To: `adminUiShell`
   - Protocol: in-process (React Query)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| PostgreSQL read failure (analytics query) | Backend returns 500 or logs error for scheduled run | Operator sees error; scheduled run retried on next interval |
| No analytics data for time window | Backend returns empty report with zero counts | Operator sees empty analytics; no error |
| Report write failure | Aggregation completed but not cached; response still returned | Operator receives report; next request re-runs aggregation |
| JWT invalid or expired (operator request) | Backend returns 401 | Operator redirected to re-authenticate |

## Sequence Diagram

```
[Scheduler / Operator] -> continuumAigoCheckoutBackend: GET /api/analytics/reports (JWT if operator)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Read raw events (ng_analytics)
continuumAigoPostgresDb --> continuumAigoCheckoutBackend: Raw event records
continuumAigoCheckoutBackend -> continuumAigoCheckoutBackend: Aggregate metrics (in-process)
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Write aggregated report (ng_analytics)
continuumAigoCheckoutBackend --> continuumAigoAdminFrontend: JSON analytics report
adminUiShell -> Operator: Render analytics dashboard
```

## Related

- Architecture dynamic view: `dynamic-aigoCheckoutBackendComponents`
- Related flows: [User Message to Response](user-message-to-response.md), [Deal Simulation Replay](deal-simulation-replay.md)
