---
service: "janus-ui-cloud"
title: "Schema Management — Create or Edit Rule"
generated: "2026-03-03"
type: flow
flow_name: "schema-management-flow"
flow_type: synchronous
trigger: "User submits a create or edit form in the Raw Schema or Canonical Schema module"
participants:
  - "continuumJanusUiCloudFrontend"
  - "continuumJanusUiCloudGateway"
  - "continuumJanusWebCloudService"
architecture_ref: "dynamic-janus-ui-request-flow"
---

# Schema Management — Create or Edit Rule

## Summary

This flow covers how data engineers use Janus UI Cloud to create or modify raw schema definitions and canonical schema mappings. The user interacts with React forms (managed by `redux-form`) in either the Raw Schema Manager (`/manage/raw-schema`) or the Canonical Schema Manager (`/manage/canonical-schema`). On submission, the UI dispatches an API write operation through the gateway proxy to the Janus metadata service, which persists the change.

## Trigger

- **Type**: user-action
- **Source**: User completes a create or edit form in the Raw Schema Manager or Canonical Schema Manager and clicks submit
- **Frequency**: On-demand (per user action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Data Engineer (browser user) | Fills in and submits schema forms | — |
| Janus UI Shell | Renders the form components; manages form state via redux-form; dispatches submit action | `continuumJanusUiCloudFrontend` |
| Janus API Proxy Middleware | Receives the POST/PUT request and forwards it to the metadata service | `continuumJanusUiCloudGateway` |
| Janus Web Cloud Metadata Service | Validates and persists the schema definition | `continuumJanusWebCloudService` |

## Steps

1. **User navigates to schema manager**: User opens `/manage/raw-schema` or `/manage/canonical-schema` in the SPA.
   - From: Browser
   - To: `janusUiShell`
   - Protocol: Client-side routing (react-router-dom)

2. **SPA fetches existing schema data**: On mount, the schema manager component dispatches an Axios GET to `/api/schemas` (or equivalent) to pre-populate the form for an edit, or displays a blank form for a create.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS/JSON

3. **User fills in schema form**: User enters schema name, field definitions, data types, and mapping rules. redux-form manages field validation state locally in the Redux store.
   - From: User (browser interaction)
   - To: Redux store (in-browser)
   - Protocol: In-browser

4. **User submits the form**: User clicks the submit button; redux-form serialises the form state and dispatches a submit action.
   - From: `janusUiShell`
   - To: `juic_janusApiClient`
   - Protocol: HTTPS POST or PUT to `/api/<schema-resource>`

5. **Gateway proxies write request**: The API proxy middleware forwards the POST/PUT with the schema payload to the Janus metadata service.
   - From: `continuumJanusUiCloudGateway`
   - To: `continuumJanusWebCloudService`
   - Protocol: HTTP/HTTPS/JSON

6. **Metadata service persists schema**: The Janus Web Cloud service validates and stores the schema definition; returns a success or error response.
   - From: `continuumJanusWebCloudService`
   - To: `continuumJanusUiCloudGateway`
   - Protocol: HTTP/HTTPS/JSON

7. **Gateway returns response to browser**: The proxy relays the status and body back to the SPA.
   - From: `continuumJanusUiCloudGateway`
   - To: `janusUiShell`
   - Protocol: HTTPS/JSON

8. **SPA updates UI**: On success, the Redux reducer clears the form and the UI shows a success notification (via `noty`). On error, the form remains populated and an error message is displayed.
   - From: Redux dispatch
   - To: React UI (DOM)
   - Protocol: In-browser

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation error from metadata service (4xx) | Proxy forwards 4xx; Redux sets form error state | Error message displayed to user; form fields remain populated |
| Network failure during submit | Axios throws network error; Redux sets error state | User sees error notification; can retry submission |
| Duplicate schema conflict (409) | Proxy forwards 409; Redux processes error | UI notifies user of conflict; user must change schema identifier |

## Sequence Diagram

```
User           -> JanusUiShell: Opens /manage/raw-schema or /manage/canonical-schema
JanusUiShell   -> APIProxy: GET /api/<schema-resource> (fetch existing or blank form)
APIProxy       -> JanusWebCloud: GET /api/<schema-resource>
JanusWebCloud  --> APIProxy: 200 OK + schema data
APIProxy       --> JanusUiShell: 200 OK + schema data
User           -> JanusUiShell: Fills form and clicks Submit
JanusUiShell   -> APIProxy: POST /api/<schema-resource> (new) or PUT /api/<schema-resource>/:id (edit)
APIProxy       -> JanusWebCloud: POST or PUT /api/<schema-resource>
JanusWebCloud  --> APIProxy: 201 Created or 200 OK
APIProxy       --> JanusUiShell: 201 or 200 + persisted schema
JanusUiShell   -> Redux Store: dispatch(schemaUpdated(result))
Redux Store    -> React UI: re-render with success notification
```

## Related

- Architecture dynamic view: `dynamic-janus-ui-request-flow`
- Related flows: [User Request — SPA Load and API Proxy](janus-ui-request-flow.md), [Sandbox Query Flow](sandbox-query-flow.md)
