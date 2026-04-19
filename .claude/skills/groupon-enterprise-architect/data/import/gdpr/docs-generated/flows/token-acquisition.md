---
service: "gdpr"
title: "Token Acquisition"
generated: "2026-03-03"
type: flow
flow_name: "token-acquisition"
flow_type: synchronous
trigger: "Data collector requires an authenticated token before calling a Lazlo API endpoint"
participants:
  - "continuumGdprService.tokenClient"
  - "cs-token-service"
architecture_ref: "dynamic-GdprManualExport"
---

# Token Acquisition

## Summary

Before each Lazlo API call that requires authentication, the GDPR service requests a scoped access token from `cs-token-service`. The token is tied to a specific resource type (e.g., `get_orders`, `users_show`, `get_bucks`, `get_scs_consents`), the consumer being exported, and the requesting agent's identity. The returned token is then passed as an `X-CS-Auth-Token` bearer token in the `Authorization` header of the corresponding Lazlo API call.

## Trigger

- **Type**: api-call (internal sub-step)
- **Source**: Called by each data collector that requires Lazlo authentication before fetching its data category
- **Frequency**: Once per authenticated data category per export request (multiple times per export: orders, user profile, Groupon Bucks, SMS consent)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Token Client | Constructs and sends the token request; returns the parsed token to the calling collector | `continuumGdprService` (tokenClient component) |
| `cs-token-service` | Validates the agent credentials and issues a scoped access token | `tokenService_9f1c2a` (stub) |

## Steps

1. **Build token request**: Token Client constructs form-encoded POST body with `method` (resource scope), `consumer_id`, `customer_email`, `agent_email`, and `agent_id`
   - From: `continuumGdprService.tokenClient`
   - To: `continuumGdprService.tokenClient` (internal)
   - Protocol: direct

2. **Set authentication headers**: Token Client sets `Content-Type: application/x-www-form-urlencoded` and `X-API-KEY: {token_service.api_key}` headers on the outbound request
   - From: `continuumGdprService.tokenClient`
   - To: `continuumGdprService.tokenClient` (internal)
   - Protocol: direct

3. **POST to token service**: Token Client sends `POST http://{token_service.host}/api/v1/{country}/token` with the form body
   - From: `continuumGdprService.tokenClient`
   - To: `cs-token-service`
   - Protocol: HTTP POST

4. **Validate HTTP status**: Token Client checks that the response status is `200 OK`. Any non-200 status is returned as an error, aborting the export
   - From: `continuumGdprService.tokenClient`
   - To: `continuumGdprService.tokenClient` (internal)
   - Protocol: direct

5. **Parse token response**: Token Client unmarshals the JSON response body into a `Token` struct containing `token` (string), `http_code`, `status`, and `tokenExpiration`
   - From: `continuumGdprService.tokenClient`
   - To: `continuumGdprService.tokenClient` (internal)
   - Protocol: direct

6. **Return token to caller**: The `Token` struct is returned to the requesting data collector, which uses `token.Token` as the value in the `Authorization: X-CS-Auth-Token {token}` header for its subsequent Lazlo API call
   - From: `continuumGdprService.tokenClient`
   - To: calling data collector
   - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Network error reaching `cs-token-service` | Error returned from `Request()` | Calling collector returns error; export aborts |
| Non-200 HTTP response from token service | `errors.New(fmt.Sprintf("%v", resp.Body))` returned | Calling collector returns error; export aborts with HTTP 500 |
| JSON unmarshal failure on token response | Error logged and returned | Calling collector returns error; export aborts |

## Sequence Diagram

```
Collector -> TokenClient: getToken(resource)
TokenClient -> TokenService: POST /api/v1/{country}/token
  body: method={resource}&consumer_id={uuid}&customer_email={email}&agent_email={agentEmail}&agent_id={agentId}
  headers: X-API-KEY:{api_key}, Content-Type:application/x-www-form-urlencoded
TokenService --> TokenClient: {"token": "...", "http_code": 200, ...}
TokenClient --> Collector: Token{Token: "..."}
Collector -> Lazlo: GET /api/mobile/... (Authorization: X-CS-Auth-Token {token})
```

## Related

- Architecture dynamic view: `dynamic-GdprManualExport`
- Related flows: [Web Export Request](web-export-request.md), [Data Collection Pipeline](data-collection-pipeline.md)
