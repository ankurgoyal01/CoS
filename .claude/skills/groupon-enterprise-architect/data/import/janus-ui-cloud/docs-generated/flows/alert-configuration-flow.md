---
service: "janus-ui-cloud"
title: "Alert Configuration Flow"
generated: "2026-03-03"
type: flow
flow_name: "alert-configuration-flow"
flow_type: synchronous
trigger: "User registers a new alert or edits an existing alert threshold in the Alerts module"
participants:
  - "continuumJanusUiCloudFrontend"
  - "continuumJanusUiCloudGateway"
  - "continuumJanusWebCloudService"
architecture_ref: "dynamic-janus-ui-request-flow"
---

# Alert Configuration Flow

## Summary

The Alerts module (`/alerts`) in Janus UI Cloud allows platform operators to register alert rules, view all alerts, edit threshold configurations, and manage alerts by user. This flow covers how a user creates or modifies an alert and how the alert configuration is persisted through the API proxy to the Janus metadata service.

## Trigger

- **Type**: user-action
- **Source**: User opens the Alerts module, fills out an alert registration or threshold edit form, and submits
- **Frequency**: On-demand (per user action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Platform Operator (browser user) | Configures alert rules and thresholds | — |
| Janus UI Shell (Alerts module) | Renders alert list, registration form, threshold editor; manages Redux alert state | `continuumJanusUiCloudFrontend` |
| Janus API Proxy Middleware | Proxies alert CRUD requests to the metadata service | `continuumJanusUiCloudGateway` |
| Janus Web Cloud Metadata Service | Stores alert configurations; returns threshold templates and notification types | `continuumJanusWebCloudService` |

## Steps

1. **User navigates to Alerts module**: User clicks `/alerts` in the SPA navigation.
   - From: Browser
   - To: `janusUiShell` (Alerts component)
   - Protocol: Client-side routing (react-router-dom)

2. **SPA initialises alerts state**: The Alerts component dispatches `alerts/INIT`, followed by `alerts/FETCH` and `alerts/GET_THRESHOLD_TEMPLATES` and `alerts/GET_NOTIFICATION_TYPES` actions to load existing alerts and configuration metadata.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS/JSON (multiple GET requests to `/api/alerts`, `/api/alert-templates`, `/api/notification-types`)

3. **Gateway proxies fetch requests**: Proxy forwards each GET to the metadata service; returns alert list, threshold templates, and notification types.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS

4. **SPA populates Redux store and renders alert list**: Redux reducers handle `alerts/SET_ALERTS`, `alerts/THRESHOLD_TEMPLATES_FETCHED`, and `alerts/NOTIFICATION_TYPES_FETCHED`; UI renders the `AllAlerts` and `UserAlerts` components.
   - From: Redux dispatch
   - To: React UI (DOM)
   - Protocol: In-browser

5. **User registers a new alert or edits a threshold**: User fills in the `RegisterAlert` or `EditThreshold` form and submits. Redux dispatches `alerts/UPDATE`.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS POST or PUT to `/api/alerts`

6. **Gateway proxies alert write**: Proxy forwards the create/update payload to the metadata service.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS/JSON

7. **Metadata service persists alert configuration**: The Janus service stores the alert rule; returns success with updated alert data.
   - From: `continuumJanusWebCloudService`
   - To: `continuumJanusUiCloudGateway`
   - Protocol: HTTP/HTTPS/JSON

8. **Gateway returns response; SPA updates**: Proxy relays the response; Redux dispatches `alerts/UPDATED` or `alerts/STATUS_UPDATED`; UI refreshes the alert list and shows a success notification.
   - From: Redux dispatch
   - To: React UI (DOM)
   - Protocol: In-browser

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Alert fetch fails | Axios error; Redux stores empty alerts list | UI renders empty Alerts view; user sees no data |
| Alert registration fails (4xx) | Proxy forwards error; Redux resets `alertInProcess` | Error notification displayed; form stays populated |
| Threshold template fetch fails | Redux receives error; templates not loaded | Threshold edit form may be unavailable or show defaults |

## Sequence Diagram

```
User             -> JanusUiShell (Alerts): Navigate to /alerts
JanusUiShell     -> APIProxy: GET /api/alerts
JanusUiShell     -> APIProxy: GET /api/alert-templates
JanusUiShell     -> APIProxy: GET /api/notification-types
APIProxy         -> JanusWebCloud: GET (each resource)
JanusWebCloud    --> APIProxy: 200 OK + alert data, templates, types
APIProxy         --> JanusUiShell: 200 OK + data
JanusUiShell     -> Redux Store: dispatch(setAlerts, thresholdTemplatesFetched, notificationTypesFetched)
User             -> JanusUiShell: Submits RegisterAlert form
JanusUiShell     -> APIProxy: POST /api/alerts (new alert payload)
APIProxy         -> JanusWebCloud: POST /api/alerts
JanusWebCloud    --> APIProxy: 201 Created + alert record
APIProxy         --> JanusUiShell: 201 Created
JanusUiShell     -> Redux Store: dispatch(alertRegistered)
Redux Store      -> React UI: re-render with updated alert list
```

## Related

- Architecture dynamic view: `dynamic-janus-ui-request-flow`
- Related flows: [User Request — SPA Load and API Proxy](janus-ui-request-flow.md), [Schema Management Flow](schema-management-flow.md)
