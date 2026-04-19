---
service: "pricing-control-center-ui"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Pricing Control Center UI.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Authentication and Token Handoff](authentication-token-handoff.md) | synchronous | User accesses any page without a valid `authn_token` cookie | Unauthenticated user is redirected to Doorman SSO, which returns a signed token; the UI writes the token cookie and redirects the user to the home page |
| [Product Search](product-search.md) | synchronous | User submits a product search by `inventory_product_id` | The UI fetches product details and price history from the jtier backend and renders the search result page |
| [Custom Sale Creation](custom-sale-creation.md) | synchronous | User submits the custom sale creation form | The UI accepts sale metadata, calls jtier to create a custom sale, and returns the result |
| [Manual ILS CSV Upload](manual-ils-csv-upload.md) | synchronous | User uploads a CSV file via the manual sale form | The UI proxies the multipart upload to jtier's `/ils_upload` endpoint and returns the processing result |
| [Sale Lifecycle Management](sale-lifecycle-management.md) | synchronous | User triggers a sale action (schedule, unschedule, cancel, retry) from the sale detail view | The UI forwards the action to the appropriate jtier endpoint and re-renders the updated sale state |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The authentication and product search flows involve cross-service interactions with Doorman SSO and `pricing-control-center-jtier`. The architecture dynamic view `pccUiAuthAndSearchFlow` captures the auth and search sequence but is currently disabled in the federated model pending external stub resolution. See [Architecture Context](../architecture-context.md) for details.
