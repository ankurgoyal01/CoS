---
service: "online_booking_3rd_party"
title: "Authorization Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "authorization-flow"
flow_type: synchronous
trigger: "API call from merchant operator to initiate or revoke provider authorization"
participants:
  - "continuumOnlineBooking3rdPartyApi"
  - "continuumOnlineBooking3rdPartyMysql"
  - "emeaBtos"
architecture_ref: "dynamic-merchant-mapping-request-flow"
---

# Authorization Flow

## Summary

The authorization flow manages the OAuth/API key authorization lifecycle between a Groupon merchant place and a third-party provider system. A merchant operator calls the V3 authorization endpoint to initiate, update, or revoke authorization. The service stores access tokens in MySQL and may need to redirect through the provider's OAuth consent flow before a token is issued. Once authorized, the access token enables all subsequent provider API calls for that merchant place.

## Trigger

- **Type**: api-call
- **Source**: Merchant operator via `POST/GET/DELETE /v3/authorization`
- **Frequency**: On-demand (triggered at merchant onboarding or when credentials expire/are revoked)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Public API Endpoints | Receives authorization request | `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints` |
| Mapping Domain | Validates merchant place and manages token state transitions | `continuumOnlineBooking3rdPartyApi` / `apiMappingDomain` |
| External Client Adapters | Communicates with provider OAuth/auth endpoint | `continuumOnlineBooking3rdPartyApi` / `apiExternalClients` |
| MySQL | Persists access tokens and authorization state | `continuumOnlineBooking3rdPartyMysql` |
| Provider APIs | Issues and validates provider access tokens | `emeaBtos` |

## Steps

1. **Receive Authorization Request**: API receives `POST /v3/authorization` from merchant operator
   - From: Merchant operator
   - To: `continuumOnlineBooking3rdPartyApi` / `apiPublicEndpoints`
   - Protocol: REST / HTTP/JSON

2. **Validate Merchant Place**: Mapping domain verifies the merchant place exists and is eligible for authorization
   - From: `apiPublicEndpoints`
   - To: `apiMappingDomain` -> `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

3. **Initiate Provider Auth**: External client adapter calls the provider's authorization endpoint to initiate the OAuth flow or exchange credentials
   - From: `apiExternalClients`
   - To: `emeaBtos`
   - Protocol: HTTP/JSON (OAuth2 or provider-specific)

4. **Persist Access Token**: Stores issued token (or pending auth state) in the `access_tokens` table in MySQL
   - From: `apiMappingDomain`
   - To: `continuumOnlineBooking3rdPartyMysql`
   - Protocol: ActiveRecord/MySQL

5. **Return Authorization State**: API returns the current authorization status (authorized, pending, or error) to the caller
   - From: `continuumOnlineBooking3rdPartyApi`
   - To: Merchant operator
   - Protocol: REST / HTTP/JSON

6. **Revocation** (DELETE path): On `DELETE /v3/authorization`, mapping domain marks the token as revoked in MySQL and may notify the provider
   - From: `apiMappingDomain`
   - To: `continuumOnlineBooking3rdPartyMysql` + `emeaBtos`
   - Protocol: ActiveRecord/MySQL + HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Provider auth endpoint unavailable | Return HTTP 503 | Operator must retry |
| Provider rejects credentials | Return HTTP 422 with provider error | Operator must re-enter credentials |
| Token already exists | Update existing token record | No duplicate created |
| MySQL write failure | Return HTTP 500 | Token not persisted; operator retries |

## Sequence Diagram

```
Operator -> apiPublicEndpoints: POST /v3/authorization
apiPublicEndpoints -> apiMappingDomain: Validate merchant place
apiMappingDomain -> continuumOnlineBooking3rdPartyMysql: Check existing authorization state
apiExternalClients -> emeaBtos: Initiate provider OAuth/auth
emeaBtos --> apiExternalClients: Return access token or auth redirect
apiMappingDomain -> continuumOnlineBooking3rdPartyMysql: Persist access token
apiPublicEndpoints --> Operator: Return authorization status
```

## Related

- Architecture dynamic view: `dynamic-merchant-mapping-request-flow`
- Related flows: [Service Mapping Lifecycle](service-mapping-lifecycle.md), [Merchant Place Polling](merchant-place-polling.md)
