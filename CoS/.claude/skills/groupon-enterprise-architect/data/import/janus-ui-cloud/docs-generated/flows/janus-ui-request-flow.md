---
service: "janus-ui-cloud"
title: "User Request — SPA Load and API Proxy"
generated: "2026-03-03"
type: flow
flow_name: "janus-ui-request-flow"
flow_type: synchronous
trigger: "User navigates to the Janus UI URL in a browser"
participants:
  - "continuumJanusUiCloudFrontend"
  - "continuumJanusUiCloudGateway"
  - "continuumJanusWebCloudService"
architecture_ref: "dynamic-janus-ui-request-flow"
---

# User Request — SPA Load and API Proxy

## Summary

This is the primary request flow for Janus UI Cloud. A user opens the Janus UI URL in a browser, causing the Express gateway to deliver the compiled React SPA. Once the SPA is running in the browser, every interaction that requires data (loading schema lists, fetching attributes, submitting forms) triggers an HTTPS call from the frontend to the gateway's `/api/*` path, which the gateway proxies transparently to the Janus Web Cloud metadata service.

## Trigger

- **Type**: user-action
- **Source**: Browser navigation to the Janus UI URL (e.g., `https://janus-ui-cloud.us-central1.conveyor.prod.gcp.groupondev.com`)
- **Frequency**: Per-request (on-demand, every user session and every data interaction)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser User | Initiates the session; navigates the SPA | — |
| Janus UI Frontend | Serves as the SPA in the browser; dispatches Redux actions and Axios API calls | `continuumJanusUiCloudFrontend` |
| Janus UI Cloud Gateway | Serves static assets; proxies `/api/*` requests to the metadata service | `continuumJanusUiCloudGateway` |
| Janus Web Cloud Metadata Service | Receives proxied API requests; returns metadata, schema, and rule data | `continuumJanusWebCloudService` |

## Steps

1. **User opens browser**: User navigates to the Janus UI URL.
   - From: Browser
   - To: `continuumJanusUiCloudGateway` (`janusUiAssetServer` component)
   - Protocol: HTTPS GET `/`

2. **Gateway delivers SPA entrypoint**: The Static Asset Server returns `index.html` and linked compiled bundles.
   - From: `continuumJanusUiCloudGateway`
   - To: Browser
   - Protocol: HTTPS (static assets)

3. **Browser bootstraps React SPA**: The browser executes the JavaScript bundle, initialises Redux store, and mounts the React application with connected-react-router.
   - From: Browser (runtime)
   - To: Browser (runtime)
   - Protocol: In-browser execution

4. **SPA dispatches data fetch**: On module load (e.g., navigating to `/raw`), the Janus UI Shell dispatches a Redux async action via `redux-thunk`, which calls Axios to make a request to `/api/<resource>`.
   - From: `janusUiShell` (within `continuumJanusUiCloudFrontend`)
   - To: `juic_janusApiClient` (within `continuumJanusUiCloudGateway`)
   - Protocol: HTTPS/JSON

5. **Gateway proxies API request**: The Janus API Proxy Middleware intercepts the `/api/*` path, rewrites it, and forwards the request to the environment-specific Janus metadata service endpoint.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS

6. **Metadata service responds**: The Janus Web Cloud metadata service processes the request and returns the data payload (e.g., list of raw schemas, attribute definitions).
   - From: `continuumJanusWebCloudService`
   - To: `continuumJanusUiCloudGateway`
   - Protocol: HTTP/HTTPS/JSON

7. **Gateway forwards response**: The proxy returns the metadata service response body and status code unchanged to the browser.
   - From: `continuumJanusUiCloudGateway`
   - To: `janusUiShell` (browser)
   - Protocol: HTTPS/JSON

8. **SPA updates Redux store and re-renders**: The Redux reducer processes the response, updates the store, and React re-renders the appropriate UI module with the fetched data.
   - From: Browser (runtime)
   - To: Browser (DOM)
   - Protocol: In-browser (Redux dispatch)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Metadata service unreachable | Axios receives network error; Redux reducer sets error state | UI module shows empty data or error notification via `noty` |
| Metadata service returns 4xx | Proxy forwards error status; Redux processes non-2xx response | UI displays error state; user can retry |
| Metadata service returns 5xx | Proxy forwards error status to browser | UI displays error state; ops team alerted via Wavefront/PagerDuty |
| Static asset delivery failure | Gateway pod unhealthy; Kubernetes liveness probe fails | Pod restarted by Kubernetes; 300s initial delay before probes begin |

## Sequence Diagram

```
Browser         -> Gateway (Static Asset Server): GET / (HTTPS)
Gateway         -> Browser: index.html + JS bundles
Browser (SPA)   -> Gateway (API Proxy): GET /api/<resource> (HTTPS/JSON)
Gateway         -> JanusWebCloudService: GET /api/<resource> (HTTP/HTTPS)
JanusWebCloudService --> Gateway: 200 OK + JSON payload
Gateway         --> Browser (SPA): 200 OK + JSON payload
Browser (SPA)   -> Redux Store: dispatch(setData(payload))
Redux Store     -> React UI: re-render with data
```

## Related

- Architecture dynamic view: `dynamic-janus-ui-request-flow`
- Related flows: [Schema Management Flow](schema-management-flow.md), [Alert Configuration Flow](alert-configuration-flow.md), [Sandbox Query Flow](sandbox-query-flow.md)
