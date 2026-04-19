---
service: "seer-frontend"
title: "Alert Metrics View"
generated: "2026-03-03"
type: flow
flow_name: "alert-metrics-view"
flow_type: synchronous
trigger: "User navigates to /alerts route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# Alert Metrics View

## Summary

When a user navigates to the `/alerts` route, the `AlertsDropDownList` component mounts, fetches the list of OpsGenie teams from the backend, and presents a team selector. The view also exposes start-date and end-date pickers. On selection change or date change, `AlertsChart` fetches a weekly alert report for the selected team and renders two bar charts: total weekly alerts and weekly auto-resolved (auto-acknowledged) alerts.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Alert Metrics" in the top navigation bar, triggering React Router navigation to `/alerts`
- **Frequency**: On demand, per navigation or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes to `/alerts`; renders `<OpsGenieAlertsDropDown>` | `headerNav` |
| Dropdown Filters (AlertsDropDownList) | Fetches OpsGenie team list; manages selected team, start date, end date state | `dropdownFilters` |
| API Client | Issues fetch calls to `/api/opsgenie/*` | `seerFrontend_apiClient` |
| seer-service backend | Returns OpsGenie team list and weekly alert report | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (AlertsChart) | Renders two bar charts: weekly alerts and weekly auto-resolved alerts | `chartsDashboard` |

## Steps

1. **User navigates to /alerts**: User clicks the "Alert Metrics" nav link.
   - From: `headerNav`
   - To: React Router renders `<OpsGenieAlertsDropDown>` → `<AlertsDropDownList>`
   - Protocol: in-process

2. **AlertsDropDownList mounts**: Component initialises team list state; `useEffect` fires.
   - From: `dropdownFilters`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

3. **Fetch OpsGenie team list**: API Client issues HTTP GET to `/api/opsgenie/teams`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

4. **Backend returns team list**: Response is a JSON array of objects with `id` and `name` fields.
   - From: `seerBackendApi_unk_7b2f`
   - To: `seerFrontend_apiClient`
   - Protocol: HTTPS/JSON

5. **Populate team dropdown**: Team names and IDs populate the selector; default `selectedTeamID` is hardcoded to `"bea767a5-1653-47e3-bf9d-0902cac708cd"` (Push Marketing Team).
   - From: `dropdownFilters`
   - To: React state → re-render
   - Protocol: in-process

6. **AlertsChart mounts**: Chart component receives `selectedTeamID`, `startDate` (default `"2024-01-01"`), `endDate` (default: today); `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

7. **Fetch weekly alert report**: API Client issues HTTP GET to `/api/opsgenie/team/{teamId}/report_by_freq?startDate={startDate}&endDate={endDate}&frequency=weekly`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

8. **Backend returns alert report**: Response JSON contains `numAlertsMap` (date → count) and `numAutoAckAlertsMap` (date → count).
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

9. **Render two bar charts**: "Number of Weekly Alerts" and "Number of Weekly Auto Resolved Alerts" bar charts are rendered with date labels on the X axis.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

10. **User changes filters**: Changing team, start date, or end date triggers `AlertsChart`'s `useEffect` dependency to re-fire, repeating steps 7–9.
    - From: `dropdownFilters`
    - To: `chartsDashboard`
    - Protocol: in-process (state prop update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/api/opsgenie/teams` fails | `.catch()` logs to console | Team dropdown shows only the hardcoded "Push Marketing Team" option |
| `/api/opsgenie/team/…/report_by_freq` fails | `.catch()` logs to console | Both charts render with no bars |
| Response JSON missing `numAlertsMap` | Chart data resolves to empty object | Charts render with no bars and no labels |

## Sequence Diagram

```
User -> headerNav: clicks "Alert Metrics"
headerNav -> AlertsDropDownList: route renders component
AlertsDropDownList -> seerFrontend_apiClient: useEffect triggers fetch
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/opsgenie/teams
seerBackendApi_unk_7b2f --> seerFrontend_apiClient: [{ id, name }, ...]
seerFrontend_apiClient --> AlertsDropDownList: setTeams(results)
AlertsDropDownList -> AlertsChart: renders with selectedTeamID, startDate, endDate
AlertsChart -> seerFrontend_apiClient: useEffect triggers fetch
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/opsgenie/team/{teamId}/report_by_freq?...
seerBackendApi_unk_7b2f --> AlertsChart: { numAlertsMap, numAutoAckAlertsMap }
AlertsChart --> User: two bar charts rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [Code Quality Metrics View](code-quality-metrics-view.md), [Incident (SEV) Metrics View](incident-sev-metrics-view.md)
