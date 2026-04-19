---
service: "mbus-sigint-frontend"
title: "SPA Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "spa-bootstrap"
flow_type: synchronous
trigger: "User navigates to the portal URL in a browser"
participants:
  - "Browser (Groupon engineer)"
  - "sigintBackendController"
  - "sigintReactUi"
  - "continuumMbusSigintConfigurationService"
  - "servicePortal"
architecture_ref: "components-continuum-mbus-sigint-frontend"
---

# SPA Bootstrap

## Summary

When an engineer navigates to the MessageBus portal (`https://mbus.groupondev.com` or the staging equivalent), the Node.js backend serves the SPA HTML shell. The React application then initialises in the browser and issues four concurrent API calls to fetch the data it needs to operate: application configuration, authenticated session info, the list of MessageBus clusters, and the full list of Groupon service names. All four calls flow through the iTier backend — the first two are handled directly by the backend controller, and the latter two are proxied to `mbus-sigint-config` and `service-portal` respectively.

## Trigger

- **Type**: user-action
- **Source**: Browser navigation to the portal URL
- **Frequency**: Per session / per page load

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (Groupon engineer) | Initiates navigation; mounts React app | — |
| Okta / Hybrid Boundary | Authenticates the request; injects GRPN identity headers | External |
| `sigintBackendController` | Serves SPA shell HTML; responds to app-config and session-info requests | `sigintBackendController` |
| `sigintReactUi` | React application that issues bootstrap API calls and populates Redux store | `sigintReactUi` |
| `sigintBackendApiProxy` | Forwards cluster-list request to `mbus-sigint-config` | `sigintBackendApiProxy` |
| `continuumMbusSigintConfigurationService` | Returns list of available MessageBus clusters | `continuumMbusSigintConfigurationService` |
| `servicePortal` | Returns full list of Groupon service names | `servicePortal` |

## Steps

1. **Navigate to portal**: Engineer opens the portal URL in a browser.
   - From: Browser
   - To: Groupon Hybrid Boundary (Okta)
   - Protocol: HTTPS

2. **Authenticate and forward**: Hybrid Boundary validates the Okta session and injects identity headers (`x-grpn-username`, `x-grpn-email`, `x-grpn-firstname`, `x-grpn-lastname`), then forwards the request.
   - From: Hybrid Boundary
   - To: `sigintBackendController`
   - Protocol: HTTPS

3. **Serve SPA shell**: The backend controller returns the HTML shell page referencing the Webpack-compiled `main.js` and `main.css` assets.
   - From: `sigintBackendController`
   - To: Browser
   - Protocol: HTTPS/HTML

4. **Load static assets**: Browser fetches JavaScript and CSS bundles from the CDN (`www<1,2>.grouponcdn.com` in production).
   - From: Browser
   - To: CDN
   - Protocol: HTTPS

5. **Mount React application**: `main.js` executes; `AppContainer` component mounts and triggers four concurrent `useEffect` calls.
   - From: `sigintReactUi`
   - To: (Internal browser execution)
   - Protocol: Direct

6. **Fetch app config**: React calls `GET /api/mbus-sigint-frontend/app-config`; backend controller responds with `{ jiraBaseUrl, name, servicePortalBaseUrl }` from the keldor config.
   - From: `sigintReactUi`
   - To: `sigintBackendController`
   - Protocol: HTTPS/JSON

7. **Fetch session info**: React calls `GET /api/mbus-sigint-frontend/session-info`; backend controller extracts identity from request headers and generates a CSRF token, returning `{ okta: { username, email, firstname, lastname }, csrfToken }`.
   - From: `sigintReactUi`
   - To: `sigintBackendController`
   - Protocol: HTTPS/JSON

8. **Fetch cluster list**: React calls `GET /api/mbus-sigint-config/cluster`; the API proxy forwards to `mbus-sigint-config` and returns the cluster list.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy` → `continuumMbusSigintConfigurationService`
   - Protocol: HTTPS/JSON

9. **Fetch service names**: React calls `GET /api/service-portal/services.json`; the API proxy forwards to `service-portal` and returns all service names.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy` → `servicePortal`
   - Protocol: HTTPS/JSON

10. **Populate Redux store**: Successful responses dispatch `initAppConfig`, `initSessionInfo`, `initClusters`, and `initServiceNames` Redux actions; the UI renders the home page.
    - From: `sigintReactUi`
    - To: Redux store
    - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| App config call fails | `console.error` + retry every 5 seconds via `setTimeout` | UI remains in loading state until resolved |
| Session info call fails | `console.error` + retry every 5 seconds | CSRF token unavailable; change request submission blocked |
| Cluster list call fails | `console.error` + retry every 5 seconds | Cluster selector empty; no configuration browseable |
| Service names call fails | `console.error` + retry every 5 seconds | Service name autocomplete unavailable; user can still type manually |

## Sequence Diagram

```
Browser -> HybridBoundary: GET https://mbus.groupondev.com/
HybridBoundary -> sigintBackendController: GET /* (with x-grpn-* headers)
sigintBackendController --> Browser: 200 SPA HTML shell
Browser -> CDN: GET /mbus-sigint-frontend/assets/main.js
CDN --> Browser: 200 JavaScript bundle
sigintReactUi -> sigintBackendController: GET /api/mbus-sigint-frontend/app-config
sigintBackendController --> sigintReactUi: 200 { jiraBaseUrl, name, servicePortalBaseUrl }
sigintReactUi -> sigintBackendController: GET /api/mbus-sigint-frontend/session-info
sigintBackendController --> sigintReactUi: 200 { okta: {...}, csrfToken }
sigintReactUi -> sigintBackendApiProxy: GET /api/mbus-sigint-config/cluster
sigintBackendApiProxy -> continuumMbusSigintConfigurationService: GET /cluster
continuumMbusSigintConfigurationService --> sigintBackendApiProxy: 200 [clusters]
sigintBackendApiProxy --> sigintReactUi: 200 [clusters]
sigintReactUi -> sigintBackendApiProxy: GET /api/service-portal/services.json
sigintBackendApiProxy -> servicePortal: GET /services.json
servicePortal --> sigintBackendApiProxy: 200 [serviceNames]
sigintBackendApiProxy --> sigintReactUi: 200 [serviceNames]
```

## Related

- Architecture dynamic view: `dynamic-configuration-change-flow`
- Related flows: [Configuration Browse](configuration-browse.md), [Configuration Change Request](configuration-change-request.md)
