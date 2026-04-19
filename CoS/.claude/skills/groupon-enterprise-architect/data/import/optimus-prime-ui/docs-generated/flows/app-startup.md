---
service: "optimus-prime-ui"
title: "Application Startup and User Profile Load"
generated: "2026-03-03"
type: flow
flow_name: "app-startup"
flow_type: synchronous
trigger: "Browser page load"
participants:
  - "continuumOptimusPrimeUi"
  - "continuumOptimusPrimeUiRouter"
  - "continuumOptimusPrimeUiStateStore"
  - "continuumOptimusPrimeUiApiClient"
  - "continuumOptimusPrimeUiBackgroundTasks"
  - "continuumOptimusPrimeApi"
architecture_ref: "dynamic-continuumOptimusPrimeUi"
---

# Application Startup and User Profile Load

## Summary

When a user first navigates to Optimus Prime UI in their browser, the application bootstraps itself by loading the authenticated user's profile from the backend, then loading all initial domain data (jobs, connections, workspaces, etc.) into Pinia stores. Background polling tasks are started after bootstrap to keep execution state current. If any step fails, the application displays a splash-screen error.

## Trigger

- **Type**: user-action (browser navigation)
- **Source**: User opens the Optimus Prime UI URL in their browser
- **Frequency**: Per browser session / page load

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser / User | Initiates navigation | — |
| Routing and View Composition | Mounts the App component and renders the initial route | `continuumOptimusPrimeUiRouter` |
| Application State Store | Holds loading state (`isAppLoading`, `isAppLoadingError`) and domain data | `continuumOptimusPrimeUiStateStore` |
| API Client Layer | Executes HTTPS calls to the backend for profile and data | `continuumOptimusPrimeUiApiClient` |
| Background Polling Tasks | Starts recurring browser timer loops after successful bootstrap | `continuumOptimusPrimeUiBackgroundTasks` |
| Optimus Prime API | Returns user profile and all domain data | `continuumOptimusPrimeApi` |

## Steps

1. **Browser loads index.html**: nginx serves the compiled Vue SPA entry point; the browser downloads JS/CSS bundles. User identity headers (`X-GRPN-USERNAME`, `X-GRPN-EMAIL`, `X-GRPN-FIRSTNAME`, `X-GRPN-LASTNAME`) are injected by the upstream SSO proxy and set as cookies (`op-user`, `op-email`, `op-firstname`, `op-lastname`) by nginx on the response.
   - From: Browser
   - To: `continuumOptimusPrimeUi` (nginx)
   - Protocol: HTTP

2. **Vue application mounts**: `src/main.js` initializes Pinia, Vue Router, Vuetify, the GA mixin, and mounts the `App` component. The router renders the initial route.
   - From: Browser runtime
   - To: `continuumOptimusPrimeUiRouter`
   - Protocol: In-process

3. **App `created()` calls `loadUserProfile()`**: The main Pinia store (`useMainStore`) dispatches an API call to fetch the authenticated user's profile from the backend.
   - From: `continuumOptimusPrimeUiStateStore`
   - To: `continuumOptimusPrimeUiApiClient`
   - Protocol: In-process

4. **API client requests user profile from backend**: Axios sends an HTTPS GET to the `optimus-prime-api` user profile endpoint via the nginx `/api/v2` proxy.
   - From: `continuumOptimusPrimeUiApiClient`
   - To: `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

5. **Backend returns user profile**: The API responds with user identity and configuration data; the store persists `meta.user`.
   - From: `continuumOptimusPrimeApi`
   - To: `continuumOptimusPrimeUiStateStore`
   - Protocol: HTTPS/JSON

6. **BackgroundTasks instance created**: `new BackgroundTasks(this.meta.user)` instantiates the background task manager using the loaded user identity.
   - From: `App.vue created()`
   - To: `continuumOptimusPrimeUiBackgroundTasks`
   - Protocol: In-process

7. **`loadUserData()` is called**: The store fetches all domain data (jobs list, connections, workspaces, etc.) via a series of API calls through the API Client Layer.
   - From: `continuumOptimusPrimeUiStateStore`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

8. **Background tasks start**: `this.tasks.start()` begins the recurring polling loops for execution updates, schedule ticks, and health checks.
   - From: `App.vue created()`
   - To: `continuumOptimusPrimeUiBackgroundTasks`
   - Protocol: In-process

9. **Workspace analytics load**: `workspaceAnalyticsStore.loadWorkspaceAnalytics()` fires asynchronously in the background.
   - From: `continuumOptimusPrimeUiStateStore`
   - To: `continuumOptimusPrimeUiApiClient` -> `continuumOptimusPrimeApi`
   - Protocol: HTTPS/JSON

10. **GA load event fired**: `this.$root.gaLoad()` records the application load event in Google Analytics.
    - From: `App.vue`
    - To: Google Analytics (`googleAnalytics`)
    - Protocol: HTTPS (gtag)

11. **SplashScreen dismissed, main UI rendered**: The router view transitions from SplashScreen to the main application layout.
    - From: `continuumOptimusPrimeUiRouter`
    - To: Browser
    - Protocol: In-process (Vue reactivity)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `loadUserProfile()` API call fails | `catch` block calls `setAppLoadingError(true)`; GA exception logged | SplashScreen shown with error state (`hasError=true`); user cannot proceed |
| `loadUserData()` API call fails | Same catch block; `setAppLoadingError(true)` | SplashScreen with error; no domain data loaded |
| Individual domain data call fails | Depends on store implementation; partial load may succeed | Some views may show empty state |

## Sequence Diagram

```
Browser -> nginx: GET / (page load)
nginx -> Browser: index.html + SSO cookies
Browser -> VueApp: mount App
VueApp -> MainStore: loadUserProfile()
MainStore -> ApiClient: GET /api/v2/users/profile
ApiClient -> OptimusPrimeApi: HTTPS GET profile
OptimusPrimeApi --> ApiClient: { user profile }
ApiClient --> MainStore: profile data stored
VueApp -> BackgroundTasks: new BackgroundTasks(user)
VueApp -> MainStore: loadUserData()
MainStore -> ApiClient: GET /api/v2/jobs, connections, workspaces
ApiClient -> OptimusPrimeApi: HTTPS GET domain data
OptimusPrimeApi --> ApiClient: domain data
ApiClient --> MainStore: stores populated
VueApp -> BackgroundTasks: tasks.start()
VueApp -> GoogleAnalytics: gaLoad()
VueApp --> Browser: render main UI
```

## Related

- Architecture dynamic view: `dynamic-continuumOptimusPrimeUi`
- Related flows: [Job Execution Trigger and Run Monitoring](job-execution.md)
