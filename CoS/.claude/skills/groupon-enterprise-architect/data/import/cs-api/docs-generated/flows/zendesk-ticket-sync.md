---
service: "cs-api"
title: "Zendesk Ticket Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "zendesk-ticket-sync"
flow_type: synchronous
trigger: "Agent creates or retrieves a Zendesk support ticket from Cyclops"
participants:
  - "customerSupportAgent"
  - "continuumCsApiService"
  - "csApi_apiResources"
  - "authModule"
  - "serviceClients"
  - "zendesk"
architecture_ref: "dynamic-cs-api"
---

# Zendesk Ticket Sync

## Summary

This flow proxies Zendesk ticket operations for CS agents working within Cyclops. Rather than agents accessing Zendesk directly, all ticket creation and retrieval passes through CS API, which applies agent authentication and formats requests to the Zendesk REST API. CS API acts as a thin authenticated proxy for these operations, translating Cyclops requests to Zendesk API calls and returning structured responses.

## Trigger

- **Type**: user-action
- **Source**: Cyclops CS agent web application; agent creates a support ticket or views existing ticket details
- **Frequency**: On-demand; per ticket action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Cyclops CS Agent App | Initiates ticket create or lookup | `customerSupportAgent` |
| CS API Service | Proxies request to Zendesk | `continuumCsApiService` |
| API Resources | Validates agent request | `csApi_apiResources` |
| Auth/JWT Module | Verifies agent identity | `authModule` |
| Service Clients | Issues authenticated HTTP call to Zendesk | `serviceClients` |
| Zendesk | External ticketing platform; creates/reads tickets | `zendesk` |

## Steps

1. **Receive ticket request**: Cyclops sends a request to create or retrieve a ticket (e.g., POST or GET against a ticket endpoint routed through CS API).
   - From: `customerSupportAgent`
   - To: `csApi_apiResources`
   - Protocol: REST / HTTPS

2. **Authenticate agent**: `authModule` validates the agent JWT.
   - From: `csApi_apiResources`
   - To: `authModule`
   - Protocol: Internal

3. **Forward to Zendesk**: `serviceClients` constructs and sends the Zendesk API request with appropriate authentication headers.
   - From: `serviceClients`
   - To: `zendesk`
   - Protocol: HTTP / Zendesk REST API

4. **Receive Zendesk response**: Zendesk returns the created or retrieved ticket payload.
   - From: `zendesk`
   - To: `serviceClients`
   - Protocol: HTTP / JSON

5. **Return ticket data to agent**: `csApi_apiResources` forwards the Zendesk response back to Cyclops.
   - From: `csApi_apiResources`
   - To: `customerSupportAgent`
   - Protocol: REST / HTTPS / JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Zendesk API unavailable | HTTP call fails or times out | 503 returned to Cyclops; agent cannot create/view tickets |
| Zendesk authentication failure | 401 from Zendesk | 502 returned; Zendesk credentials need rotation |
| Ticket not found | 404 from Zendesk | 404 propagated to Cyclops |
| Zendesk rate limit exceeded | 429 from Zendesk | 429 or 503 returned; agent advised to retry |

## Sequence Diagram

```
CyclopsUI      -> csApi_apiResources  : POST /zendesk/tickets { subject, body, customerId }
csApi_apiResources -> authModule      : Validate JWT
authModule --> csApi_apiResources     : Agent confirmed
csApi_apiResources -> serviceClients  : Forward create ticket
serviceClients -> zendesk             : POST /api/v2/tickets (HTTP + Zendesk auth)
zendesk --> serviceClients            : { ticketId, status }
serviceClients --> csApi_apiResources : Ticket created
csApi_apiResources --> CyclopsUI      : 201 { ticketId }
```

## Related

- Architecture dynamic view: `dynamic-cs-api` (not yet defined in DSL)
- Related flows: [Customer Info Aggregation](customer-info-aggregation.md), [Case Memo Management](case-memo-management.md)
