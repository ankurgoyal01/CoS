---
service: "merchant-booking-tool"
title: "Inbenta Support Auth Flow"
generated: "2026-03-03"
type: flow
flow_name: "inbenta-support-auth-flow"
flow_type: synchronous
trigger: "Merchant opens the embedded support panel within the booking tool"
participants:
  - "merchant"
  - "mbtWebRoutes"
  - "mbtInbentaClient"
architecture_ref: "dynamic-merchant-booking-primary-flow"
---

# Inbenta Support Auth Flow

## Summary

The Merchant Booking Tool embeds an Inbenta support knowledge base within the merchant experience. When a merchant opens the support panel, the Routing and Page Composition layer makes an in-process call to the Inbenta Support Client (`mbtInbentaClient`). This component builds the appropriate authentication payload and requests a short-lived support token from the Inbenta API, which is then passed to the browser to initialize the embedded support widget.

## Trigger

- **Type**: user-action
- **Source**: Merchant opens or requests the embedded support/help panel within the booking tool UI
- **Frequency**: On demand, per merchant support session initiation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Opens the embedded support panel | `merchant` |
| Routing and Page Composition | Receives support auth bootstrap request; dispatches to Inbenta Support Client | `mbtWebRoutes` |
| Inbenta Support Client | Builds authentication payload; requests Inbenta support token via node-fetch | `mbtInbentaClient` |

> Note: The Inbenta external system is referenced in the architecture DSL as a stub-only dependency — it is not in the federated model. The `mbtInbentaClient` communicates with Inbenta's API over HTTPS.

## Steps

1. **Merchant opens support panel**: Merchant clicks the support/help action within the booking tool UI, triggering an HTTPS request for a support authentication token.
   - From: `merchant`
   - To: `mbtWebRoutes`
   - Protocol: HTTPS

2. **Route to support auth handler**: `mbtWebRoutes` identifies the request as a support authentication bootstrap and makes an in-process call to `mbtInbentaClient`.
   - From: `mbtWebRoutes`
   - To: `mbtInbentaClient`
   - Protocol: In-process call

3. **Build Inbenta authentication payload**: `mbtInbentaClient` constructs the required authentication payload using the configured Inbenta API key and merchant context.
   - From: `mbtInbentaClient`
   - To: (in-process payload construction)
   - Protocol: In-process

4. **Request Inbenta support token**: `mbtInbentaClient` sends an HTTPS request to the Inbenta API using node-fetch, submitting the authentication payload to obtain a short-lived support session token.
   - From: `mbtInbentaClient`
   - To: Inbenta API (external)
   - Protocol: HTTPS

5. **Receive support token**: Inbenta API returns the support authentication token in the response.
   - From: Inbenta API
   - To: `mbtInbentaClient`
   - Protocol: HTTPS

6. **Return token to browser**: `mbtWebRoutes` returns the Inbenta support token to the merchant's browser, which uses it to initialize the embedded support widget.
   - From: `mbtWebRoutes`
   - To: `merchant`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inbenta API unavailable | Request fails in `mbtInbentaClient`; error surfaced to routing layer | Embedded support unavailable; merchant shown error or support panel fails to load |
| Invalid Inbenta API key | Inbenta returns auth error; `mbtInbentaClient` propagates failure | Support token not issued; embedded support unavailable |
| Inbenta API timeout | node-fetch request times out; error propagated | Support panel fails to initialize; core booking functions unaffected |

## Sequence Diagram

```
Merchant -> mbtWebRoutes: Open support panel / request support auth (HTTPS)
mbtWebRoutes -> mbtInbentaClient: Bootstrap support authentication (in-process)
mbtInbentaClient -> Inbenta API: Request support token with auth payload (HTTPS)
Inbenta API --> mbtInbentaClient: Support session token
mbtInbentaClient --> mbtWebRoutes: Token response
mbtWebRoutes --> Merchant: Inbenta support token (HTTPS/JSON)
Merchant -> Inbenta (browser widget): Initialize embedded support with token
```

## Related

- Architecture dynamic view: `dynamic-merchant-booking-primary-flow`
- Related flows: [Primary Booking Data Flow](primary-booking-data-flow.md)
- See [Integrations](../integrations.md) for Inbenta dependency details
