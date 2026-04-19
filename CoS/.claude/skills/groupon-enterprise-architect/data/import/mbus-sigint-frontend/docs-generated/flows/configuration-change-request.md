---
service: "mbus-sigint-frontend"
title: "Configuration Change Request"
generated: "2026-03-03"
type: flow
flow_name: "configuration-change-request"
flow_type: synchronous
trigger: "User submits a new MessageBus configuration change request form"
participants:
  - "sigintReactUi"
  - "sigintBackendApiProxy"
  - "continuumMbusSigintConfigurationService"
architecture_ref: "dynamic-configuration-change-flow"
---

# Configuration Change Request

## Summary

An engineer who needs a new JMS destination (topic or queue), or access to an existing one, fills out the change request form in the Configuration module. The SPA collects the request data — including destination name, service name, producer/consumer flags, credentials, DLQ settings, redelivery configuration, and divert rules — and posts it to `mbus-sigint-config` via the API proxy. The resulting change request enters a pending state awaiting admin approval. This is the primary self-service workflow the portal exists to support.

## Trigger

- **Type**: user-action
- **Source**: Engineer clicks "Submit" on the new change request form in the `/configuration` section of the SPA
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser (Groupon engineer) | Fills and submits the configuration change request form | — |
| `sigintReactUi` | Manages form state via Redux; issues POST request with CSRF token | `sigintReactUi` |
| `sigintBackendApiProxy` | Strips `x-csrf-token` header, strips `/api/mbus-sigint-config` prefix, forwards to upstream | `sigintBackendApiProxy` |
| `continuumMbusSigintConfigurationService` | Receives and persists the change request; returns the created request object | `continuumMbusSigintConfigurationService` |

## Steps

1. **Open change request form**: Engineer navigates to the Configuration module and selects "New Request".
   - From: Browser
   - To: `sigintReactUi`
   - Protocol: Client-side routing (no network call)

2. **Select service name**: Engineer types a service name in the autocomplete field; `sigintReactUi` filters the pre-loaded service names list from the Redux store.
   - From: `sigintReactUi`
   - To: Redux store (local)
   - Protocol: Direct

3. **Configure destination details**: Engineer fills destination name, selects producer/consumer roles, sets credentials (prod/test), configures DLQ, redelivery settings, and optionally adds divert rules. Redux actions are dispatched as each field changes (e.g., `SET_DESTINATION`, `SET_IS_PRODUCER`, `SET_DLQ`, `SET_CUSTOM_REDELIVERY_SETTINGS`).
   - From: Browser
   - To: `sigintReactUi` → Redux store
   - Protocol: Direct

4. **Submit change request**: Engineer clicks Submit. `sigintReactUi` calls `api.postChangeRequest(changeRequest, csrfToken)` — a POST to `/api/mbus-sigint-config/change-request` with `x-csrf-token` header.
   - From: `sigintReactUi`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

5. **Proxy to upstream**: `sigintBackendApiProxy` strips the `x-csrf-token` header and rewrites the URL (removes `/api/mbus-sigint-config` prefix), then forwards the request using the `MbusSigintConfigClient` Gofer client.
   - From: `sigintBackendApiProxy`
   - To: `continuumMbusSigintConfigurationService`
   - Protocol: HTTPS/JSON

6. **Persist change request**: `continuumMbusSigintConfigurationService` validates and persists the change request, returning the created request object with a `requestId` and `PENDING` status.
   - From: `continuumMbusSigintConfigurationService`
   - To: `sigintBackendApiProxy`
   - Protocol: HTTPS/JSON

7. **Return result to SPA**: The proxy passes the response back to the browser; `sigintReactUi` displays the new request summary with its ID and pending status.
   - From: `sigintBackendApiProxy`
   - To: `sigintReactUi`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid CSRF token | `mbus-sigint-config` returns 403; proxy forwards error to SPA | User sees error; form remains populated for retry |
| Upstream `mbus-sigint-config` unavailable | Gofer timeout; proxy returns 5xx | User sees submission error; request not created |
| Validation failure (upstream) | `mbus-sigint-config` returns 400 with error details | User sees validation error from upstream |
| Session expired | Subsequent requests return 401 from Hybrid Boundary | User sees error; must re-authenticate |

## Sequence Diagram

```
Browser -> sigintReactUi: Fill and submit change request form
sigintReactUi -> sigintBackendApiProxy: POST /api/mbus-sigint-config/change-request
  (body: changeRequest, headers: x-csrf-token)
sigintBackendApiProxy -> continuumMbusSigintConfigurationService: POST /change-request
  (x-csrf-token stripped, URL prefix stripped)
continuumMbusSigintConfigurationService --> sigintBackendApiProxy: 201 { requestId, status: "PENDING", ... }
sigintBackendApiProxy --> sigintReactUi: 201 { requestId, status: "PENDING", ... }
sigintReactUi --> Browser: Display request summary with requestId
```

## Related

- Architecture dynamic view: `dynamic-configuration-change-flow`
- Related flows: [Change Request Approval](change-request-approval.md), [SPA Bootstrap](spa-bootstrap.md)
