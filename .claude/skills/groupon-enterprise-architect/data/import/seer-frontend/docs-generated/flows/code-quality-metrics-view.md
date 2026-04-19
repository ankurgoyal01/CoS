---
service: "seer-frontend"
title: "Code Quality Metrics View"
generated: "2026-03-03"
type: flow
flow_name: "code-quality-metrics-view"
flow_type: synchronous
trigger: "User navigates to /quality route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# Code Quality Metrics View

## Summary

When a user navigates to the `/quality` route, the `ServiceDropDown` component mounts and fetches SonarQube code quality metrics for all services from the backend. The response populates a service selector dropdown. Selecting a service updates the `CodeCoverageChart` bar chart to display five quality metrics: bugs, coverage, code smells, reliability rating, and duplicated lines density. A threshold reference table is also rendered to help users interpret the values.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Code Quality Metrics" in the top navigation bar, triggering React Router navigation to `/quality`
- **Frequency**: On demand, per user navigation event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes the user to `/quality`; renders `<ServiceDropDown>` | `headerNav` |
| Dropdown Filters (ServiceDropDown) | On mount, fetches service list; manages selected service state | `dropdownFilters` |
| API Client | Issues `GET /api/sonarqube/metrics` fetch call | `seerFrontend_apiClient` |
| seer-service backend | Returns JSON map of service name to SonarQube metric values | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (CodeCoverageChart) | Renders bar chart for bugs, coverage, code_smells, reliability_rating, duplicated_lines_density | `chartsDashboard` |

## Steps

1. **User navigates to /quality**: User clicks the "Code Quality Metrics" nav link.
   - From: `headerNav`
   - To: React Router renders `<ServiceDropDown>`
   - Protocol: in-process

2. **ServiceDropDown mounts**: Component initialises empty `serviceNames` and `selectedServiceName` state; `useEffect` fires.
   - From: `dropdownFilters`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

3. **Fetch all SonarQube metrics**: API Client issues HTTP GET to `/api/sonarqube/metrics`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

4. **Backend returns metrics map**: Response is a JSON object whose keys are service names and whose values are metric objects containing `bugs`, `coverage`, `code_smells`, `reliability_rating`, `duplicated_lines_density`.
   - From: `seerBackendApi_unk_7b2f`
   - To: `seerFrontend_apiClient`
   - Protocol: HTTPS/JSON

5. **Populate service dropdown**: `Object.keys(json)` extracts service names; first service is auto-selected.
   - From: `dropdownFilters`
   - To: React state update → re-render
   - Protocol: in-process

6. **Render CodeCoverageChart**: Chart component receives the currently selected service name; a separate `useEffect` in `CodeCoverageChart` calls `/api/sonarqube/metrics` again and filters the five chart keys for the selected service.
   - From: `chartsDashboard`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

7. **Render threshold table**: `CodeCoverageThresholdValues` renders a static reference table (Good / Average / Below Average bands) for Code Coverage, Reliability Rating, Code Smells, Duplicate Lines Density, and Bugs.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

8. **User changes service**: Selecting a different service from the dropdown updates `selectedServiceName` state; `CodeCoverageChart`'s `useEffect` re-fires and fetches updated data.
   - From: `dropdownFilters`
   - To: `chartsDashboard` → `seerFrontend_apiClient` → `seerBackendApi_unk_7b2f`
   - Protocol: in-process then HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Backend unreachable | `.catch()` logs error to console | Service dropdown remains empty; chart renders with no data |
| Service not found in response | `json[selectedServiceName]` returns `undefined` | Chart renders with empty dataset labels and values |
| Non-200 response | Response body still parsed as JSON; parse failure caught by `.catch()` | Chart remains empty; no user-facing error |

## Sequence Diagram

```
User -> headerNav: clicks "Code Quality Metrics"
headerNav -> ServiceDropDown: route renders component
ServiceDropDown -> seerFrontend_apiClient: useEffect triggers fetch
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/sonarqube/metrics
seerBackendApi_unk_7b2f --> seerFrontend_apiClient: { "service-a": { bugs: 0, coverage: 85.2, ... }, ... }
seerFrontend_apiClient --> ServiceDropDown: setServiceNames(Object.keys(json))
ServiceDropDown -> CodeCoverageChart: renders with selectedServiceName
CodeCoverageChart -> seerBackendApi_unk_7b2f: GET /api/sonarqube/metrics
seerBackendApi_unk_7b2f --> CodeCoverageChart: metric map
CodeCoverageChart --> User: bar chart rendered
ServiceDropDown -> CodeCoverageThresholdValues: renders
CodeCoverageThresholdValues --> User: threshold table rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [Alert Metrics View](alert-metrics-view.md), [Sprint Metrics View](sprint-metrics-view.md)
