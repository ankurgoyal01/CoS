---
service: "merchant-booking-tool"
title: "Proxy Write Flow"
generated: "2026-03-03"
type: flow
flow_name: "proxy-write-flow"
flow_type: synchronous
trigger: "Merchant submits a write or update operation from a booking management page"
participants:
  - "merchant"
  - "mbtWebRoutes"
  - "mbtProxyController"
  - "mbtMerchantApiClient"
  - "continuumUniversalMerchantApi"
architecture_ref: "dynamic-merchant-booking-primary-flow"
---

# Proxy Write Flow

## Summary

When a merchant performs a write or update action on a booking management page (for example, updating a reservation, modifying a calendar slot, or saving a staff profile), the Routing and Page Composition component routes the request to the Proxy Controller. The Proxy Controller normalizes the request and forwards it to the upstream booking service via the Merchant API Client Adapter, then returns the normalized response to the merchant.

## Trigger

- **Type**: user-action
- **Source**: Merchant browser submits a write or update operation to a `/reservations/mbt/proxy/*` passthrough route
- **Frequency**: On demand, per merchant write action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Initiates write/update action | `merchant` |
| Routing and Page Composition | Receives request; dispatches to Proxy Controller for proxy-mode operations | `mbtWebRoutes` |
| Proxy Controller | Normalizes and forwards request to upstream booking service | `mbtProxyController` |
| Merchant API Client Adapter | Executes the actual HTTP/JSON call to the upstream booking service base URL | `mbtMerchantApiClient` |
| Universal Merchant API | Receives and processes the write/update booking operation | `continuumUniversalMerchantApi` |

## Steps

1. **Receive write request**: Merchant browser sends an HTTPS request (POST, PUT, or DELETE) to a `/reservations/mbt/proxy/*` passthrough route.
   - From: `merchant`
   - To: `mbtWebRoutes`
   - Protocol: HTTPS

2. **Dispatch to Proxy Controller**: `mbtWebRoutes` identifies the request as a proxy-mode operation and makes an in-process call to `mbtProxyController`.
   - From: `mbtWebRoutes`
   - To: `mbtProxyController`
   - Protocol: In-process call

3. **Normalize and forward request**: `mbtProxyController` normalizes the request (headers, payload) and invokes `mbtMerchantApiClient` to execute the upstream booking service call.
   - From: `mbtProxyController`
   - To: `mbtMerchantApiClient`
   - Protocol: HTTP/JSON (in-process)

4. **Call upstream booking service**: `mbtMerchantApiClient` sends the proxied request to the `continuumUniversalMerchantApi` booking service base URL.
   - From: `mbtMerchantApiClient`
   - To: `continuumUniversalMerchantApi`
   - Protocol: HTTPS/JSON

5. **Receive upstream response**: `continuumUniversalMerchantApi` returns the write/update result as a JSON response.
   - From: `continuumUniversalMerchantApi`
   - To: `mbtMerchantApiClient` / `mbtProxyController`
   - Protocol: HTTPS/JSON

6. **Return normalized response**: `mbtProxyController` normalizes the response and `mbtWebRoutes` returns it to the merchant browser.
   - From: `mbtProxyController` / `mbtWebRoutes`
   - To: `merchant`
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `continuumUniversalMerchantApi` returns 4xx | Error propagated through proxy normalization | Merchant receives error response; booking write not applied |
| `continuumUniversalMerchantApi` returns 5xx | Error propagated through proxy normalization | Merchant receives server error; write operation failed |
| Network timeout to upstream booking service | Request fails; timeout propagated | Merchant receives timeout/error response |
| Request normalization failure | Proxy controller error handling | Merchant receives error; upstream call not made |

## Sequence Diagram

```
Merchant -> mbtWebRoutes: POST/PUT/DELETE /reservations/mbt/proxy/* (HTTPS)
mbtWebRoutes -> mbtProxyController: Dispatch proxy-mode request (in-process)
mbtProxyController -> mbtMerchantApiClient: Normalized HTTP/JSON upstream call
mbtMerchantApiClient -> continuumUniversalMerchantApi: Proxied booking service request (HTTPS/JSON)
continuumUniversalMerchantApi --> mbtMerchantApiClient: Write/update result (JSON)
mbtMerchantApiClient --> mbtProxyController: Response
mbtProxyController --> mbtWebRoutes: Normalized response
mbtWebRoutes --> Merchant: JSON response (HTTPS)
```

## Related

- Architecture dynamic view: `dynamic-merchant-booking-primary-flow`
- Related flows: [Primary Booking Data Flow](primary-booking-data-flow.md)
- See [Architecture Context](../architecture-context.md) for component relationships
