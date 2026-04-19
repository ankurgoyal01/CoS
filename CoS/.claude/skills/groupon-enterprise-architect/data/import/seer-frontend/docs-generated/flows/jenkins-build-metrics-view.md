---
service: "seer-frontend"
title: "Jenkins Build Metrics View"
generated: "2026-03-03"
type: flow
flow_name: "jenkins-build-metrics-view"
flow_type: synchronous
trigger: "User navigates to /builds route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# Jenkins Build Metrics View

## Summary

When a user navigates to the `/builds` route, the `BuildTimeDropDown` component fetches the list of services from the Service Portal owners endpoint. Users can select a service (or "all") and a date range. On filter change, `BuildTimeChart` fetches Jenkins build time data from the backend and renders two bar charts showing daily and weekly average build durations.

## Trigger

- **Type**: user-action
- **Source**: User clicks "Jenkin Build Metrics" in the top navigation bar, triggering React Router navigation to `/builds`
- **Frequency**: On demand, per navigation or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes to `/builds`; renders `<BuildTimeDropDown>` | `headerNav` |
| Dropdown Filters (BuildTimeDropDown) | Fetches service list; manages service selector and date range state | `dropdownFilters` |
| API Client | Issues fetch calls to `/api/serviceportal/owners` and `/api/jenkins/build/report` | `seerFrontend_apiClient` |
| seer-service backend | Returns service list and Jenkins build time report | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (BuildTimeChart) | Renders "Jenkins Build times - Daily" and "Jenkins Build times - Weekly" bar charts | `chartsDashboard` |

## Steps

1. **User navigates to /builds**: User clicks the "Jenkin Build Metrics" nav link.
   - From: `headerNav`
   - To: React Router renders `<BuildTimeDropDown>`
   - Protocol: in-process

2. **BuildTimeDropDown mounts**: `useEffect` fires to fetch service list.
   - From: `dropdownFilters`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

3. **Fetch service list**: API Client issues HTTP GET to `/api/serviceportal/owners` (same endpoint as Incidents view; keys used as service names).
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

4. **Backend returns owner map**: Response keys (service names) populate the dropdown.
   - From: `seerBackendApi_unk_7b2f`
   - To: `seerFrontend_apiClient`
   - Protocol: HTTPS/JSON

5. **Populate service dropdown**: Service names fill the selector; default is "all" (pre-selected).
   - From: `dropdownFilters`
   - To: React state → re-render
   - Protocol: in-process

6. **BuildTimeChart mounts**: Receives `startDate="2024-01-01"`, `endDate=today`, `selectedService=""`; `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

7. **Fetch Jenkins build report**: API Client issues HTTP GET to `/api/jenkins/build/report?startDate={startDate}&endDate={endDate}&service={selectedService}`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

8. **Backend returns build time data**: Response JSON contains `daily` (date → average build time) and `weekly` (date → average build time) maps.
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

9. **Render two bar charts**: "Jenkins Build times - Daily" and "Jenkins Build times - Weekly" bar charts are rendered.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

10. **User changes filters**: Selecting a service or changing dates re-triggers `BuildTimeChart`'s `useEffect` (steps 7–9).
    - From: `dropdownFilters`
    - To: `chartsDashboard`
    - Protocol: in-process (state prop update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/api/serviceportal/owners` fails | `.catch()` logs to console | Service dropdown shows only the "all" option |
| `/api/jenkins/build/report` fails | `.catch()` logs to console | Both charts render empty |
| No data for selected date range | Backend returns empty maps | Charts render with no bars |

## Sequence Diagram

```
User -> headerNav: clicks "Jenkin Build Metrics"
headerNav -> BuildTimeDropDown: route renders component
BuildTimeDropDown -> seerFrontend_apiClient: useEffect → fetch service list
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/serviceportal/owners
seerBackendApi_unk_7b2f --> seerFrontend_apiClient: { "service-a": "owner", ... }
seerFrontend_apiClient --> BuildTimeDropDown: setServices(Object.keys(json))
BuildTimeDropDown -> BuildTimeChart: renders with startDate, endDate, selectedService
BuildTimeChart -> seerFrontend_apiClient: useEffect → fetch build report
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/jenkins/build/report?startDate=2024-01-01&endDate=today&service=all
seerBackendApi_unk_7b2f --> BuildTimeChart: { daily: {...}, weekly: {...} }
BuildTimeChart --> User: daily + weekly build time charts rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [PR and Deployment Metrics Views](pr-and-deployment-metrics-view.md), [Incident (SEV) Metrics View](incident-sev-metrics-view.md)
