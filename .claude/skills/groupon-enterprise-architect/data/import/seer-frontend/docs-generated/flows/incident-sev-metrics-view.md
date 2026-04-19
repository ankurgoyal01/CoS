---
service: "seer-frontend"
title: "Incident (SEV) Metrics View"
generated: "2026-03-03"
type: flow
flow_name: "incident-sev-metrics-view"
flow_type: synchronous
trigger: "User navigates to /incidents route"
participants:
  - "continuumSeerFrontendApp"
  - "headerNav"
  - "dropdownFilters"
  - "chartsDashboard"
  - "seerFrontend_apiClient"
  - "seerBackendApi_unk_7b2f"
architecture_ref: "dynamic-continuumSeerFrontendApp"
---

# Incident (SEV) Metrics View

## Summary

When a user navigates to the `/incidents` route, the `IncidentsDropDown` component fetches the service-to-owner mapping from the Service Portal endpoint. This populates both a service dropdown and a service-owner dropdown. Users can also set a date range (start/end) and a severity range (min SEV 1–5, max SEV 1–5). On any filter change, `IncidentChart` fetches incident counts from the Jira incidents endpoint and renders daily and weekly incident bar charts.

## Trigger

- **Type**: user-action
- **Source**: User clicks "SEV Metrics" in the top navigation bar, triggering React Router navigation to `/incidents`
- **Frequency**: On demand, per navigation or filter change

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Header Navigation | Routes to `/incidents`; renders `<IncidentsDropDown>` | `headerNav` |
| Dropdown Filters (IncidentsDropDownList) | Fetches service/owner map; manages service, owner, date range, and SEV range state | `dropdownFilters` |
| API Client | Issues fetch calls to `/api/serviceportal/owners` and `/api/jira/incidents` | `seerFrontend_apiClient` |
| seer-service backend | Returns service owner map and incident data | `seerBackendApi_unk_7b2f` |
| Dashboard Charts (IncidentChart) | Renders daily and weekly incident count bar charts | `chartsDashboard` |

## Steps

1. **User navigates to /incidents**: User clicks the "SEV Metrics" nav link.
   - From: `headerNav`
   - To: React Router renders `<IncidentsDropDown>` → `<IncidentsDropDownList>`
   - Protocol: in-process

2. **IncidentsDropDown mounts**: `useEffect` fires to fetch service/owner map.
   - From: `dropdownFilters`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

3. **Fetch service/owner map**: API Client issues HTTP GET to `/api/serviceportal/owners`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

4. **Backend returns owner map**: Response is a JSON object where keys are service names and values are owner names.
   - From: `seerBackendApi_unk_7b2f`
   - To: `seerFrontend_apiClient`
   - Protocol: HTTPS/JSON

5. **Populate dropdowns**: Service names (keys) and owner names (values) populate their respective selectors. Default "all" option is prepended to both.
   - From: `dropdownFilters`
   - To: React state → re-render
   - Protocol: in-process

6. **IncidentChart mounts**: Receives `selectedService=""`, `selectedOwner=""`, `startDate="2024-01-01"`, `endDate=today`, `minSEV="1"`, `maxSEV="5"`; `useEffect` fires.
   - From: `chartsDashboard`
   - To: `seerFrontend_apiClient`
   - Protocol: in-process

7. **Fetch incident data**: API Client issues HTTP GET to `/api/jira/incidents?service={service}&owner={owner}&startDate={startDate}&endDate={endDate}&minSEV={minSEV}&maxSEV={maxSEV}`.
   - From: `seerFrontend_apiClient`
   - To: `seerBackendApi_unk_7b2f`
   - Protocol: HTTPS/JSON

8. **Backend returns incident maps**: Response JSON contains `daily` (date → count) and `weekly` (date → count) maps.
   - From: `seerBackendApi_unk_7b2f`
   - To: `chartsDashboard`
   - Protocol: HTTPS/JSON

9. **Render two bar charts**: "Number of Incidents - Daily" and "Number of Incidents - Weekly" charts rendered with date labels.
   - From: `chartsDashboard`
   - To: DOM
   - Protocol: in-process

10. **User changes filters**: Any change to service, owner, date range, or SEV range re-triggers `IncidentChart`'s `useEffect`, repeating steps 7–9.
    - From: `dropdownFilters`
    - To: `chartsDashboard`
    - Protocol: in-process (state prop update)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `/api/serviceportal/owners` fails | `.catch()` logs to console | Service and owner dropdowns show only the "all" option |
| `/api/jira/incidents` fails | `.catch()` logs to console | Both charts render empty |
| SEV range produces no results | Backend returns empty maps | Charts render with no bars |

## Sequence Diagram

```
User -> headerNav: clicks "SEV Metrics"
headerNav -> IncidentsDropDown: route renders component
IncidentsDropDown -> seerFrontend_apiClient: useEffect → fetch owners
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/serviceportal/owners
seerBackendApi_unk_7b2f --> seerFrontend_apiClient: { "service-a": "owner-team", ... }
seerFrontend_apiClient --> IncidentsDropDown: setServices(keys), setOwners(values)
IncidentsDropDown -> IncidentsDropDownList: renders with services, owners
IncidentsDropDownList -> IncidentChart: renders with filters
IncidentChart -> seerFrontend_apiClient: useEffect → fetch incidents
seerFrontend_apiClient -> seerBackendApi_unk_7b2f: GET /api/jira/incidents?service=all&owner=all&startDate=2024-01-01&endDate=today&minSEV=1&maxSEV=5
seerBackendApi_unk_7b2f --> IncidentChart: { daily: {...}, weekly: {...} }
IncidentChart --> User: daily + weekly incident charts rendered
```

## Related

- Architecture dynamic view: `dynamic-continuumSeerFrontendApp`
- Related flows: [Alert Metrics View](alert-metrics-view.md), [Jenkins Build Metrics View](jenkins-build-metrics-view.md)
