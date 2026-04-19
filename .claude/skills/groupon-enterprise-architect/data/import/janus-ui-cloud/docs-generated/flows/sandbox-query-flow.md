---
service: "janus-ui-cloud"
title: "Sandbox Query Flow"
generated: "2026-03-03"
type: flow
flow_name: "sandbox-query-flow"
flow_type: synchronous
trigger: "User submits a test query in the Sandbox module or runs a Sample Query against a canonical schema"
participants:
  - "continuumJanusUiCloudFrontend"
  - "continuumJanusUiCloudGateway"
  - "continuumJanusWebCloudService"
architecture_ref: "dynamic-janus-ui-request-flow"
---

# Sandbox Query Flow

## Summary

The Sandbox (`/sandbox`) and Sample Query sub-module (within the Canonical Schema view) allow data engineers to test and validate their Janus translation rules interactively without committing to production. The user provides input parameters and runs a query; the UI sends the query through the API proxy to the Janus metadata service, which evaluates the translation rule and returns sample output. This flow enables rapid iterative testing of rule configurations.

## Trigger

- **Type**: user-action
- **Source**: User fills in query parameters in the Sandbox or Sample Query component and clicks the run/submit button
- **Frequency**: On-demand (per user test action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Data Engineer (browser user) | Constructs and submits test queries | — |
| Janus UI Shell (Sandbox / Sample Query) | Renders query input form; dispatches query action; displays results | `continuumJanusUiCloudFrontend` |
| Janus API Proxy Middleware | Proxies the sample query request to the metadata service | `continuumJanusUiCloudGateway` |
| Janus Web Cloud Metadata Service | Evaluates the Janus translation rule against the query input; returns sample output | `continuumJanusWebCloudService` |

## Steps

1. **User navigates to Sandbox or Canonical Schema**: User opens `/sandbox` or navigates to a canonical mapping and selects the Sample Query sub-component.
   - From: Browser
   - To: `janusUiShell`
   - Protocol: Client-side routing (react-router-dom)

2. **SPA loads available schemas and dimensions**: The Sandbox or Sample Query component dispatches fetch actions to load available canonical events, attributes, and dimension options for the query form.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS/JSON GET to `/api/<schemas>` or `/api/<dimensions>`

3. **Gateway proxies data fetch**: Proxy forwards the GET requests to the Janus metadata service; returns schema and dimension data.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS

4. **SPA renders query form with options**: Redux reducers update the store with available schemas and dimensions; React renders the multi-checkbox selectors and query input fields.
   - From: Redux dispatch
   - To: React UI (DOM)
   - Protocol: In-browser

5. **User configures and submits query**: User selects canonical event, attribute filters, and dimension checkboxes via the `multi-checkbox` component; clicks the run button; the component dispatches a `sampleQueryActions` async action.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS POST to `/api/<sample-query-resource>` with query parameters

6. **Gateway proxies query request**: The API proxy middleware forwards the query payload to the Janus metadata service.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS/JSON

7. **Metadata service evaluates query**: The Janus metadata service runs the translation rule evaluation against the provided input and returns a sample output payload.
   - From: `continuumJanusWebCloudService`
   - To: `continuumJanusUiCloudGateway`
   - Protocol: HTTP/HTTPS/JSON

8. **Gateway returns results; SPA displays output**: Proxy relays the response; Redux dispatches sample query result action; the `GeneratedQueries` or sandbox result component renders the output using `react-json-view` for JSON inspection.
   - From: Redux dispatch
   - To: React UI (DOM)
   - Protocol: In-browser

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid query parameters | Metadata service returns 4xx; proxy forwards; Redux sets error state | Error message displayed; query form stays populated |
| Metadata service timeout | Axios times out; Redux sets error state | User notified of timeout; encouraged to simplify query |
| Schema/dimension fetch fails | Redux stores empty options | Query form may render with empty dropdowns; user cannot select options |

## Sequence Diagram

```
User             -> JanusUiShell (Sandbox): Navigate to /sandbox
JanusUiShell     -> APIProxy: GET /api/<canonical-events> (load options)
APIProxy         -> JanusWebCloud: GET /api/<canonical-events>
JanusWebCloud    --> APIProxy: 200 OK + canonical events/dimensions
APIProxy         --> JanusUiShell: 200 OK + options data
JanusUiShell     -> Redux Store: dispatch(setDimensions, setSchemas)
User             -> JanusUiShell: Selects options and clicks Run
JanusUiShell     -> APIProxy: POST /api/<sample-query> (query payload)
APIProxy         -> JanusWebCloud: POST /api/<sample-query>
JanusWebCloud    --> APIProxy: 200 OK + sample translation output
APIProxy         --> JanusUiShell: 200 OK + output JSON
JanusUiShell     -> Redux Store: dispatch(setSampleQueryResult(output))
Redux Store      -> React UI: render output via react-json-view
```

## Related

- Architecture dynamic view: `dynamic-janus-ui-request-flow`
- Related flows: [User Request — SPA Load and API Proxy](janus-ui-request-flow.md), [Schema Management Flow](schema-management-flow.md)
