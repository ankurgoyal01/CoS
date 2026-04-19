---
service: "seer-frontend"
title: "PR and Deployment Metrics Views"
generated: "2026-03-03"
type: flow
flow_name: "pr-and-deployment-metrics-view"
flow_type: synchronous
trigger: "User navigates to /pulls or /deployments route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# PR and Deployment Metrics Views

## Summary

Two metric views — Pull Request Merge Times (`/pulls`) and Deployment Times (`/deployments`) — follow an identical interaction pattern to the Jenkins Build Metrics view. Each fetches the service list from `/api/serviceportal/owners`, presents a service selector and date range pickers, then calls a distinct backend report endpoint to retrieve daily and weekly time-series data. The results are rendered as two bar charts (daily and weekly) per view.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Pull Request Metrics" or "Deployment Metrics" in the top navigation bar
- **Frequency**: On demand, per navigation or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes to `/pulls` or `/deployments`; renders the appropriate component | `headerNav` |
| Dropdown Filters (PRMergeTimeDropDown / DeploymentTimeDropDown) | Fetches service list; manages service selector and date range state | `dropdownFilters` |
| API Client | Issues fetch calls to `/api/serviceportal/owners` and the metric-specific report endpoint | `seerFrontend_apiClient` |
| seer-service backend | Returns service list and the requested metric report | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (PRMergeTimeChart / DeploymentTimeChart) | Renders daily and weekly bar charts for the respective metric | `chartsDashboard` |

## Steps

### Pull Request Merge Times (`/pulls`)

1. **User navigates to /pulls**: React Router renders `<PRMergeTimeDropDown>`.
   - From: `headerNav`
   - To: `dropdownFilters`
   - Protocol: in-process

2. **Fetch service list**: HTTP GET to `/api/serviceportal/owners`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

3. **Populate service dropdown**: Keys from owner map populate the selector; default is "all".
   - From: `dropdownFilters`
   - To: React state
   - Protocol: in-process

4. **PRMergeTimeChart mounts**: Receives `startDate`, `endDate`, `selectedService`; `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

5. **Fetch PR merge time report**: HTTP GET to `/api/seer/pullreq/report?startDate={startDate}&endDate={endDate}&service={selectedService}`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

6. **Backend returns PR merge times**: Response JSON contains `daily` (date → average merge time) and `weekly` (date → average merge time) maps.
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

7. **Render two charts**: "Pull Request Merge times - Daily" and "Pull Request Merge times - Weekly" bar charts rendered.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

### Deployment Times (`/deployments`)

Steps 1–3 are identical to the PR flow. From step 4:

4. **DeploymentTimeChart mounts**: Receives `startDate`, `endDate`, `selectedService`; `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

5. **Fetch deployment time report**: HTTP GET to `/api/deploybot/report?startDate={startDate}&endDate={endDate}&service={selectedService}`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

6. **Backend returns deployment times**: Response JSON contains `daily` (date → average deployment time) and `weekly` (date → average deployment time) maps.
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

7. **Render two charts**: "Deployment average times - Daily" and "Deployment average times - Weekly" bar charts rendered.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/api/serviceportal/owners` fails | `.catch()` logs to console | Service dropdown shows only "all" option |
| `/api/seer/pullreq/report` fails | `.catch()` logs to console | PR merge time charts render empty |
| `/api/deploybot/report` fails | `.catch()` logs to console | Deployment time charts render empty |
| No data for selected date range | Backend returns empty maps | Charts render with no bars |

## Sequence Diagram

```
User -> headerNav: clicks "Pull Request Metrics"
headerNav -> PRMergeTimeDropDown: route renders component
PRMergeTimeDropDown -> seerFrontend_apiClient: useEffect → fetch service list
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/serviceportal/owners
seerBackendApi_unk_7b2f --> PRMergeTimeDropDown: { "service-a": "owner", ... }
PRMergeTimeDropDown -> PRMergeTimeChart: renders with startDate, endDate, selectedService
PRMergeTimeChart -> seerFrontend_apiClient: useEffect → fetch PR merge report
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/seer/pullreq/report?startDate=...&endDate=...&service=all
seerBackendApi_unk_7b2f --> PRMergeTimeChart: { daily: {...}, weekly: {...} }
PRMergeTimeChart --> User: PR merge time charts rendered

User -> headerNav: clicks "Deployment Metrics"
headerNav -> DeploymentTimeDropDown: route renders component
DeploymentTimeDropDown -> seerFrontend_apiClient: useEffect → fetch service list
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/serviceportal/owners
seerBackendApi_unk_7b2f --> DeploymentTimeDropDown: { ... }
DeploymentTimeDropDown -> DeploymentTimeChart: renders with filters
DeploymentTimeChart -> seerFrontend_apiClient: useEffect → fetch deployment report
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/deploybot/report?startDate=...&endDate=...&service=all
seerBackendApi_unk_7b2f --> DeploymentTimeChart: { daily: {...}, weekly: {...} }
DeploymentTimeChart --> User: deployment time charts rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [Jenkins Build Metrics View](jenkins-build-metrics-view.md), [Incident (SEV) Metrics View](incident-sev-metrics-view.md)
