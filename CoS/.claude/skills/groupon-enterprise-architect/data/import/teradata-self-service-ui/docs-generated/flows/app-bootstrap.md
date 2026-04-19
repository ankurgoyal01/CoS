---
service: "teradata-self-service-ui"
title: "Application Bootstrap"
generated: "2026-03-03"
type: flow
flow_name: "app-bootstrap"
flow_type: synchronous
trigger: "User navigates to the application URL in a browser"
participants:
  - "continuumTeradataSelfServiceUi"
  - "teradataSelfServiceApi"
architecture_ref: "dynamic-appBootstrap"
---

# Application Bootstrap

## Summary

When a user first loads the Teradata Self Service UI, the application performs a sequential initialisation sequence to fetch all data needed to render the full UI. The SPA reads identity information from browser cookies (set by Nginx from upstream SSO headers), then makes four sequential API calls to load the authenticated user's profile, global configuration, Teradata accounts, and request history. A splash screen is shown until all data is loaded, after which the main application view is rendered.

## Trigger

- **Type**: user-action
- **Source**: Browser navigation to the application URL
- **Frequency**: Once per page load / browser session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / SPA | Orchestrates bootstrap sequence, renders splash screen then main UI | `continuumTeradataSelfServiceUi` |
| Nginx (embedded) | Injects SSO identity headers as browser cookies before serving `index.html` | `continuumTeradataSelfServiceUi` |
| teradata-self-service-api | Responds to all data fetch requests | `teradataSelfServiceApi` |

## Steps

1. **Corporate SSO proxy injects identity headers**: The upstream proxy (Okta/SSO gateway) adds `X-GRPN-USERNAME`, `X-GRPN-EMAIL`, `X-GRPN-FIRSTNAME`, `X-GRPN-LASTNAME` request headers.
   - From: `Corporate SSO proxy`
   - To: `continuumTeradataSelfServiceUi` (Nginx)
   - Protocol: HTTP headers

2. **Nginx serves `index.html` and sets cookies**: Nginx reads the SSO headers and writes `tss-user`, `tss-email`, `tss-firstname`, `tss-lastname` cookies in the `Set-Cookie` response headers for all HTML responses.
   - From: `Nginx`
   - To: `Browser`
   - Protocol: HTTP response headers

3. **Vue app mounts and reads identity cookies**: `App.vue` calls `store.dispatch('initAppShell')`, which calls `Api.loadAppShell()`. This reads the `tss-user`, `tss-firstname`, `tss-lastname`, and `tss-email` cookies and stores them in the Vuex `meta` state.
   - From: `SPA UI`
   - To: `Browser cookies`
   - Protocol: direct

4. **Fetch user profile**: `store.dispatch('getUser')` calls `GET /api/v1/users/:userName` using the username from `meta.user`. The response populates the Vuex `user` state (displayName, email, managerName, userName).
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST (proxied by Nginx)

5. **Fetch global configuration**: `store.dispatch('getConfiguration')` calls `GET /api/v1/configuration`. The response populates the Vuex `configuration` state (lockDurationInHours, passwordExpiryInDays, jiraBaseUrl, uiUrl).
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

6. **Fetch accounts**: `store.dispatch('getAccounts')` calls `GET /api/v1/accounts`. The response is split by the `managed` flag: personal accounts populate `state.account`, managed service accounts populate `state.serviceAccounts`.
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

7. **Fetch requests and history**: `store.dispatch('getRequests')` calls `GET /api/v1/requests`. The response is split: items where `status === 'PENDING'` and `approver === currentUser` populate `state.requests` (pending approvals queue); all other items populate `state.history`.
   - From: `continuumTeradataSelfServiceUi` (API Client)
   - To: `teradataSelfServiceApi`
   - Protocol: HTTPS REST

8. **Dismiss splash screen and render main UI**: The `isLoading` Vuex flag is cleared. `App.vue` hides the `SplashScreen` component and renders `AppBar`, the `router-view` (defaulting to `/accounts`), and `Footer`.
   - From: `Vuex store`
   - To: `SPA UI`
   - Protocol: reactive binding

9. **Record page view in Google Analytics**: The Vue Router `afterEach` hook calls `gtag('config', GA_TRACKING_ID, { page_path, page_title })` for the initial route.
   - From: `Analytics Adapter`
   - To: `googleAnalytics`
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing `tss-user` cookie (SSO not injecting headers) | `Api.loadAppShell()` falls back to the default value `ijohansson`; subsequent `getUser` call uses this fallback | Wrong user context; data shown for the fallback user |
| `GET /api/v1/users/:userName` fails | Error propagated up; `NETWORK_ERROR` or API error code sent to GA; EventBus emits `error` event | Error snackbar shown; `user` state remains empty; subsequent `getRequests` throws "No user set in store" |
| Any API call returns a network error | `getErrorCode()` in the API Client classifies as `NETWORK_ERROR`; GA exception event fired | Error notification displayed; affected data views are empty |
| Vue error in component mounting | `Vue.config.errorHandler` catches; GA exception event fired; EventBus emits `error` | Error snackbar; partial UI may render |

## Sequence Diagram

```
Browser -> Nginx: GET / (with X-GRPN-USERNAME header)
Nginx -> Browser: 200 index.html (Set-Cookie: tss-user, tss-email, ...)
Browser -> SPA: Mount Vue application
SPA -> SPA: initAppShell() — read cookies into Vuex meta
SPA -> teradataSelfServiceApi: GET /api/v1/users/:userName
teradataSelfServiceApi --> SPA: 200 {data: {userName, displayName, managerName, ...}}
SPA -> teradataSelfServiceApi: GET /api/v1/configuration
teradataSelfServiceApi --> SPA: 200 {data: {passwordExpiryInDays, lockDurationInHours, ...}}
SPA -> teradataSelfServiceApi: GET /api/v1/accounts
teradataSelfServiceApi --> SPA: 200 {data: [{name, status, managed, ...}, ...]}
SPA -> teradataSelfServiceApi: GET /api/v1/requests
teradataSelfServiceApi --> SPA: 200 {data: [{id, status, approver, type, ...}, ...]}
SPA -> SPA: isLoading = false — render main UI
SPA -> GoogleAnalytics: gtag page_view event
```

## Related

- Architecture dynamic view: `dynamic-appBootstrap`
- Related flows: [New Account Request](new-account-request.md), [Manager Approval](manager-approval.md)
