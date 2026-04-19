---
service: "hybrid-boundary-ui"
title: "Service Configuration Change Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "service-config-change"
flow_type: synchronous
trigger: "Operator navigates to Hybrid Boundary UI and submits a service configuration change"
participants:
  - "continuumHybridBoundaryUi"
  - "hbUiAngularSpa"
  - "hbUiAuthModule"
  - "hbUiApiClient"
  - "hbUiParAutomationClient"
  - "Groupon Okta"
  - "Hybrid Boundary API (/release/v1)"
  - "PAR Automation API (/release/par)"
architecture_ref: "dynamic-hybridBoundaryUiChangeFlow"
---

# Service Configuration Change Flow

## Summary

This flow describes how an operator uses the Hybrid Boundary UI to authenticate, retrieve current service mesh configuration, and submit a configuration change or PAR request. The user authenticates via Groupon Okta OIDC before the Angular application makes authorized HTTPS calls to the Hybrid Boundary API to read or update service definitions, endpoints, policies, or permissions. If a PAR-gated change is required, the flow additionally submits a request to the PAR Automation API. All network calls are made from the browser.

> Note: The Structurizr dynamic view `hybridBoundaryUiChangeFlow` is currently commented out in the architecture model because all external participants (`unknownGrouponOktaOauth_u3ab7`, `unknownHybridBoundaryApiReleaseV1_u6f4c`, `unknownParAutomationApiReleasePar_u9d21`) are stub-only. This flow is documented from the component-level DSL evidence.

## Trigger

- **Type**: user-action
- **Source**: Operator opens the Hybrid Boundary UI in a browser
- **Frequency**: On-demand, per operator session

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hybrid Boundary UI App (`hbUiAngularSpa`) | Renders UI, orchestrates navigation and API calls | `continuumHybridBoundaryUi` |
| Auth Module (`hbUiAuthModule`) | Performs OIDC login and attaches tokens to requests | `continuumHybridBoundaryUi` |
| Config and User Services (`hbUiApiClient`) | Issues requests to `/release/v1` for service configuration | `continuumHybridBoundaryUi` |
| PAR Client (`hbUiParAutomationClient`) | Issues requests to `/release/par` for PAR submission | `continuumHybridBoundaryUi` |
| Groupon Okta | Authenticates the operator and issues OIDC identity token | Stub-only |
| Hybrid Boundary API (`/release/v1`) | Provides and accepts service configuration data | Stub-only |
| PAR Automation API (`/release/par`) | Receives and processes PAR requests | Stub-only |

## Steps

1. **Loads and refreshes access token**: `hbUiAngularSpa` initializes the Angular application; `hbUiAuthModule` checks for a valid OIDC session token.
   - From: `hbUiAngularSpa`
   - To: `hbUiAuthModule`
   - Protocol: Direct (Angular dependency injection, in-browser)

2. **Authenticates via Okta OIDC**: If no valid token exists, `hbUiAuthModule` performs OIDC discovery and redirects the operator to Groupon Okta login. Okta returns an authorization code; `hbUiAuthModule` exchanges it for an access token.
   - From: `hbUiAuthModule`
   - To: Groupon Okta
   - Protocol: HTTPS/OIDC

3. **Reads service configuration**: The operator navigates to a service view; `hbUiAngularSpa` calls `hbUiApiClient` which issues a GET request to `/release/v1` with the Bearer token attached by the auth interceptor.
   - From: `hbUiApiClient`
   - To: Hybrid Boundary API (`/release/v1`)
   - Protocol: HTTPS/JSON

4. **Submits configuration change**: The operator edits configuration and submits; `hbUiAngularSpa` calls `hbUiApiClient` which issues a PUT or POST request to `/release/v1` with the updated service definition.
   - From: `hbUiApiClient`
   - To: Hybrid Boundary API (`/release/v1`)
   - Protocol: HTTPS/JSON

5. **Submits PAR request (conditional)**: If the change requires a PAR approval, `hbUiAngularSpa` calls `hbUiParAutomationClient` which POSTs a PAR request to `/release/par`.
   - From: `hbUiParAutomationClient`
   - To: PAR Automation API (`/release/par`)
   - Protocol: HTTPS/JSON

6. **Displays confirmation**: `hbUiAngularSpa` renders the API response — success confirmation or error message — to the operator.
   - From: `hbUiAngularSpa`
   - To: Browser (operator)
   - Protocol: DOM rendering

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Okta login failure | `angular-oauth2-oidc` surfaces error; redirect to login retry | Operator cannot access the UI |
| Expired OIDC token | Auth interceptor detects 401; triggers token refresh or re-login | Operator is re-authenticated transparently or redirected to login |
| Hybrid Boundary API 4xx | Angular HTTP error handler surfaces message to UI | Operator sees error notification; no state change |
| Hybrid Boundary API 5xx | Angular HTTP error handler surfaces message to UI | Operator sees error notification; may retry |
| PAR submission failure | Angular HTTP error handler surfaces message to UI | PAR request not submitted; operator may retry |

## Sequence Diagram

```
Operator           -> hbUiAngularSpa              : Open Hybrid Boundary UI in browser
hbUiAngularSpa     -> hbUiAuthModule              : Check/load OIDC session token
hbUiAuthModule     -> Groupon Okta                : OIDC discovery / login redirect / token exchange
Groupon Okta       --> hbUiAuthModule             : Access token issued

hbUiAngularSpa     -> hbUiApiClient               : Load service configuration
hbUiApiClient      -> Hybrid Boundary API /release/v1 : GET /release/v1/services/:id
Hybrid Boundary API --> hbUiApiClient             : Service config data (JSON)
hbUiApiClient      --> hbUiAngularSpa             : Configuration payload
hbUiAngularSpa     --> Operator                   : Render service configuration view

Operator           -> hbUiAngularSpa              : Submit configuration change
hbUiAngularSpa     -> hbUiApiClient               : Apply change
hbUiApiClient      -> Hybrid Boundary API /release/v1 : PUT /release/v1/services/:id
Hybrid Boundary API --> hbUiApiClient             : 200 OK
hbUiApiClient      --> hbUiAngularSpa             : Success
hbUiAngularSpa     --> Operator                   : Render confirmation

[If PAR required]
hbUiAngularSpa     -> hbUiParAutomationClient     : Submit PAR request
hbUiParAutomationClient -> PAR Automation API /release/par : POST /release/par
PAR Automation API --> hbUiParAutomationClient    : PAR request created
hbUiParAutomationClient --> hbUiAngularSpa        : PAR confirmation
hbUiAngularSpa     --> Operator                   : Render PAR submission confirmation
```

## Related

- Architecture dynamic view: `dynamic-hybridBoundaryUiChangeFlow` (stub-only — view commented out in DSL)
- Related flows: No additional flows documented for this service
- See [Architecture Context](../architecture-context.md) for component details
- See [Integrations](../integrations.md) for external dependency details
