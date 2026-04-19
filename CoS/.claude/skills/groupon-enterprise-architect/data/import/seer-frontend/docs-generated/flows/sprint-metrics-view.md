---
service: "seer-frontend"
title: "Sprint Metrics View"
generated: "2026-03-03"
type: flow
flow_name: "sprint-metrics-view"
flow_type: synchronous
trigger: "User navigates to /sprint route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# Sprint Metrics View

## Summary

When a user navigates to the `/sprint` route, the `SprintMetricsDropDownList` component fetches the list of Jira sprint boards from the backend and renders a team selector. On mount and on board selection change, `SprintChart` fetches the per-sprint report for the chosen board and renders two bar charts: a volatility percentage chart and a stacked KTLO/Bugs and Features percentage chart. These charts help engineering leaders track sprint stability and work-type distribution over time.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Sprint Metrics" in the top navigation bar, triggering React Router navigation to `/sprint`
- **Frequency**: On demand, per navigation or board selection change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes to `/sprint`; renders `<SprintMetricsDropDown>` | `headerNav` |
| Dropdown Filters (SprintMetricsDropDownList) | Fetches Jira board list; manages selected board ID state | `dropdownFilters` |
| API Client | Issues fetch calls to `/api/jira/*` | `seerFrontend_apiClient` |
| seer-service backend | Returns Jira board list and sprint report data | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (SprintChart) | Renders volatility percentage and KTLO/Bugs vs Features stacked charts | `chartsDashboard` |

## Steps

1. **User navigates to /sprint**: User clicks the "Sprint Metrics" nav link.
   - From: `headerNav`
   - To: React Router renders `<SprintMetricsDropDown>` → `<SprintMetricsDropDownList>`
   - Protocol: in-process

2. **SprintMetricsDropDownList mounts**: Default selected board ID is hardcoded to `5565`; `useEffect` fires to fetch board list.
   - From: `dropdownFilters`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

3. **Fetch Jira boards**: API Client issues HTTP GET to `/api/jira/boards`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

4. **Backend returns board list**: Response is a JSON array of objects with `id` and `name` fields representing Jira sprint boards.
   - From: `seerBackendApi_unk_7b2f`
   - To: `seerFrontend_apiClient`
   - Protocol: HTTPS/JSON

5. **Populate board dropdown**: Board names and IDs populate the team selector.
   - From: `dropdownFilters`
   - To: React state → re-render
   - Protocol: in-process

6. **SprintChart mounts**: Receives `selectedSprintDashboard` (default `5565`); `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

7. **Fetch sprint board report**: API Client issues HTTP GET to `/api/jira/get_board_sprint_report/{boardId}`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

8. **Backend returns sprint data**: Response is a JSON array of sprint objects each containing `name`, `numDefects`, `volatility`, `KTLOBugsPercentage`, `featuresPercentage`.
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

9. **Parse and set chart state**: Arrays for `volatilityPercentData`, `defectsData`, `ktloBugsPercentData`, and `featuresPercentData` are constructed from the response.
   - From: `chartsDashboard`
   - To: React state
   - Protocol: in-process

10. **Render two bar charts**: "Volatility Percentage" bar chart and "Sprint KTLO/Bugs & Feature Percentage Chart" (stacked) are rendered with sprint names as X-axis labels.
    - From: `chartsDashboard`
    - To: DOM
    - Protocol: in-process

11. **User changes board**: Selecting a different board updates `selectedSprintDashboard`; SprintChart's `useEffect` re-fires (step 7 onwards).
    - From: `dropdownFilters`
    - To: `chartsDashboard`
    - Protocol: in-process (state prop update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/api/jira/boards` fails | `.catch()` logs to console | Board dropdown remains empty; default board ID 5565 still drives chart fetch |
| `/api/jira/get_board_sprint_report/…` fails | `.catch()` logs to console | Charts render with no bars |
| Percentage strings include trailing `%` | `.slice(0, -1)` strips last character before parsing | Correct numeric values passed to Chart.js |

## Sequence Diagram

```
User -> headerNav: clicks "Sprint Metrics"
headerNav -> SprintMetricsDropDownList: route renders component
SprintMetricsDropDownList -> seerFrontend_apiClient: useEffect → fetch boards
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/jira/boards
seerBackendApi_unk_7b2f --> seerFrontend_apiClient: [{ id, name }, ...]
seerFrontend_apiClient --> SprintMetricsDropDownList: setSprintBoards(boards)
SprintMetricsDropDownList -> SprintChart: renders with selectedSprintDashboard=5565
SprintChart -> seerFrontend_apiClient: useEffect → fetch sprint report
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/jira/get_board_sprint_report/5565
seerBackendApi_unk_7b2f --> SprintChart: [{ name, volatility, KTLOBugsPercentage, featuresPercentage }, ...]
SprintChart --> User: volatility chart + stacked KTLO/features chart rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [Incident (SEV) Metrics View](incident-sev-metrics-view.md), [Code Quality Metrics View](code-quality-metrics-view.md)
