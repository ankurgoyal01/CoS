---
service: "goods-stores-api"
title: "Authorization Token Validation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "authorization-token-validation"
flow_type: synchronous
trigger: "Every authenticated API request across v1, v2, and v3 endpoints"
participants:
  - "continuumGoodsStoresApi"
  - "continuumGoodsStoresApi_grapeApp"
  - "continuumGoodsStoresApi_v1Api"
  - "continuumGoodsStoresApi_v2Api"
  - "continuumGoodsStoresApi_v3Api"
  - "continuumGoodsStoresApi_auth"
  - "continuumUsersService"
architecture_ref: "dynamic-goods-stores-authorization-token-validation"
---

# Authorization Token Validation

## Summary

Every authenticated request to the Goods Stores API passes through the `continuumGoodsStoresApi_auth` Authorization & Token Helper before the endpoint handler executes. The helper parses the GPAPI token from the `Authorization` header, validates it against the `continuumUsersService`, resolves the caller's role and feature flags, and either permits or rejects the request. This flow applies uniformly across all v1, v2, and v3 API endpoints.

## Trigger

- **Type**: api-call (pre-execution hook on every authenticated endpoint)
- **Source**: GPAPI client, merchant tooling, or internal service making any authenticated call to `continuumGoodsStoresApi`
- **Frequency**: Per request — every authenticated API call

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Grape API Router | Routes incoming request to the appropriate versioned API module | `continuumGoodsStoresApi_grapeApp` |
| V1 / V2 / V3 API modules | Invoke auth helper as a pre-execution step for each endpoint | `continuumGoodsStoresApi_v1Api`, `continuumGoodsStoresApi_v2Api`, `continuumGoodsStoresApi_v3Api` |
| Authorization & Token Helper | Parses token; validates with Users service; resolves role and feature flags | `continuumGoodsStoresApi_auth` |
| Users Service | Provides user account data and token validation | `continuumUsersService` |

## Steps

1. **Receive Incoming Request**: Client sends HTTP request with `Authorization: Token <token>` header to any versioned endpoint.
   - From: `GPAPI client / calling service`
   - To: `continuumGoodsStoresApi_grapeApp`
   - Protocol: REST/HTTP

2. **Route to Versioned API**: Grape router dispatches the request to the appropriate versioned API module (v1, v2, or v3) based on URL path prefix.
   - From: `continuumGoodsStoresApi_grapeApp`
   - To: `continuumGoodsStoresApi_v1Api` / `continuumGoodsStoresApi_v2Api` / `continuumGoodsStoresApi_v3Api`
   - Protocol: Grape mount (in-process)

3. **Invoke Authorization Helper**: Before executing the endpoint handler, the API module invokes `continuumGoodsStoresApi_auth` as a before-filter.
   - From: API module
   - To: `continuumGoodsStoresApi_auth`
   - Protocol: direct (in-process)

4. **Parse Token**: Auth helper extracts the token value from the `Authorization` header.
   - From: `continuumGoodsStoresApi_auth`
   - To: in-process
   - Protocol: direct

5. **Validate Token with Users Service**: Auth helper calls `continuumUsersService` to validate the token and retrieve the associated user account.
   - From: `continuumGoodsStoresApi_auth`
   - To: `continuumUsersService`
   - Protocol: HTTP/JSON

6. **Resolve Role and Feature Flags**: Auth helper evaluates the user's role and checks applicable feature flags to determine endpoint-level access.
   - From: `continuumGoodsStoresApi_auth`
   - To: in-process (role/flag resolution from user data)
   - Protocol: direct

7. **Permit or Reject**: If token is valid and role/flags permit access, the request proceeds to the endpoint handler. If not, the helper halts processing and returns an error response.
   - From: `continuumGoodsStoresApi_auth`
   - To: API module endpoint handler (permit) or HTTP response (reject)
   - Protocol: direct (in-process) or REST/HTTP (error response)

8. **Continue to Endpoint Handler**: Authorized request proceeds to the target endpoint handler (product, contract, merchant, search, attachment, etc.).
   - From: API module
   - To: endpoint handler logic
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing Authorization header | Auth helper returns 401 immediately | HTTP 401 Unauthorized; request halted |
| Invalid or expired token | Users service returns invalid; auth helper halts | HTTP 401 Unauthorized; request halted |
| Users service unavailable | Auth helper raises connection error | HTTP 500 or 503; all authenticated requests fail |
| Insufficient role for endpoint | Auth helper halts with 403 | HTTP 403 Forbidden; request halted |
| Feature flag check denies access | Auth helper halts with 403 | HTTP 403 Forbidden; feature not accessible to caller |

## Sequence Diagram

```
GPAPI Client -> continuumGoodsStoresApi_grapeApp: HTTP request with Authorization header
continuumGoodsStoresApi_grapeApp -> continuumGoodsStoresApi_v2Api: Route to versioned module
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_auth: Invoke before-filter (token validation)
continuumGoodsStoresApi_auth -> continuumUsersService: Validate token (HTTP/JSON)
continuumUsersService --> continuumGoodsStoresApi_auth: User account + validity
continuumGoodsStoresApi_auth -> continuumGoodsStoresApi_auth: Resolve role and feature flags
continuumGoodsStoresApi_auth --> continuumGoodsStoresApi_v2Api: Authorized (or 401/403 halted)
continuumGoodsStoresApi_v2Api -> continuumGoodsStoresApi_v2Api: Execute endpoint handler
continuumGoodsStoresApi_v2Api --> GPAPI Client: Endpoint response
```

## Related

- Architecture dynamic view: `dynamic-goods-stores-authorization-token-validation`
- Related flows: [Product Create/Update & Sync](product-create-update-sync.md), [Search Query Execution](search-query-execution.md), [Attachment Upload](attachment-upload.md), [Contract Lifecycle](contract-lifecycle.md)
