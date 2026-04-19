---
service: "etorch"
title: "Hotel Data Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "hotel-data-management"
flow_type: synchronous
trigger: "Merchant HTTP request to the Getaways Extranet API"
participants:
  - "continuumEtorchApp"
  - "etorchAppControllers"
  - "getawaysInventoryExternal_b51b"
  - "getawaysContentExternal_1467"
  - "notificationServiceExternal_5b7e"
  - "mxMerchantApiExternal_b545"
architecture_ref: "dynamic-etorchHotelDataManagement"
---

# Hotel Data Management

## Summary

A hotel operator or channel manager sends an authenticated REST request to the eTorch extranet API to manage hotel contacts or retrieve recent automatic inventory updates. `continuumEtorchApp` receives the request, validates identity via MX Merchant API, coordinates reads and writes across Getaways Inventory and Getaways Content, and optionally dispatches notifications through Notification Service. The flow covers the `POST /getaways/v2/extranet/contacts`, `GET /getaways/v2/extranet/contacts`, and `GET /getaways/v2/extranet/recent_auto_updates` endpoints.

## Trigger

- **Type**: api-call
- **Source**: Hotel operator or channel manager system via the Getaways Extranet portal
- **Frequency**: On-demand, per merchant request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| eTorch App | Receives request, orchestrates downstream calls, returns response | `continuumEtorchApp` |
| Extranet Controllers | Validates inbound HTTP request; routes to orchestration | `etorchAppControllers` |
| MX Merchant API | Provides merchant identity and account validation | `mxMerchantApiExternal_b545` |
| Getaways Inventory | Source of truth for recent auto-update records | `getawaysInventoryExternal_b51b` |
| Getaways Content | Provides hotel metadata referenced in extranet views | `getawaysContentExternal_1467` |
| Notification Service | Delivers transactional emails triggered by contact changes | `notificationServiceExternal_5b7e` |

## Steps

1. **Receives merchant request**: Hotel operator sends an authenticated HTTP request to eTorch.
   - From: `Merchant / Extranet portal`
   - To: `etorchAppControllers`
   - Protocol: REST (HTTPS)

2. **Validates API key and routes request**: Extranet Controllers inspect the API key header, validate input, and forward to the orchestration layer.
   - From: `etorchAppControllers`
   - To: `etorchAppOrchestration`
   - Protocol: Direct (in-process)

3. **Resolves merchant identity**: Orchestration calls MX Merchant API to verify the merchant account associated with the hotel UUID.
   - From: `continuumEtorchApp`
   - To: `mxMerchantApiExternal_b545`
   - Protocol: REST (HTTP)

4. **Reads hotel metadata** (contact listing and recent auto-update flows): Orchestration fetches hotel content and metadata from Getaways Content.
   - From: `continuumEtorchApp`
   - To: `getawaysContentExternal_1467`
   - Protocol: REST (HTTP)

5. **Reads inventory updates** (`GET /recent_auto_updates` only): Orchestration queries Getaways Inventory for recent automatic inventory changes for the hotel.
   - From: `continuumEtorchApp`
   - To: `getawaysInventoryExternal_b51b`
   - Protocol: REST (HTTP)

6. **Persists new contact** (`POST /contacts` only): Orchestration writes the new contact record to the eTorch relational database.
   - From: `etorchAppOrchestration`
   - To: `eTorch DB`
   - Protocol: JDBC (direct)

7. **Sends notification email** (`POST /contacts` only): On successful contact creation, orchestration calls Notification Service to dispatch a confirmation email to the hotel operator.
   - From: `continuumEtorchApp`
   - To: `notificationServiceExternal_5b7e`
   - Protocol: REST (HTTP)

8. **Returns response to merchant**: eTorch assembles the response payload and returns it to the caller.
   - From: `etorchAppControllers`
   - To: `Merchant / Extranet portal`
   - Protocol: REST (HTTPS)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid or missing API key | Request rejected at `etorchAppControllers` | HTTP 401 returned to merchant |
| Unknown hotel UUID | 404 response from orchestration | HTTP 404 returned to merchant |
| MX Merchant API unavailable | HTTP error propagated by `etorchAppClients` | Certain extranet views cannot be rendered; HTTP 500 |
| Getaways Inventory unavailable | HTTP error propagated by `etorchAppClients` | `recent_auto_updates` endpoint returns HTTP 500 |
| Getaways Content unavailable | HTTP error propagated by `etorchAppClients` | Hotel metadata unavailable; response degraded or HTTP 500 |
| Database write failure (`POST /contacts`) | JDBC exception caught by orchestration | Contact not persisted; HTTP 500; check `ETORCH_DB_URL` |
| Notification Service unavailable | Non-critical; error logged but not propagated | Contact saved; confirmation email not delivered |

## Sequence Diagram

```
Merchant -> etorchAppControllers: POST /getaways/v2/extranet/contacts (API key)
etorchAppControllers -> etorchAppOrchestration: route request
etorchAppOrchestration -> mxMerchantApiExternal_b545: GET merchant identity
mxMerchantApiExternal_b545 --> etorchAppOrchestration: merchant account
etorchAppOrchestration -> getawaysContentExternal_1467: GET hotel metadata
getawaysContentExternal_1467 --> etorchAppOrchestration: hotel content
etorchAppOrchestration -> eTorch DB: INSERT contact record
eTorch DB --> etorchAppOrchestration: write confirmed
etorchAppOrchestration -> notificationServiceExternal_5b7e: POST send confirmation email
notificationServiceExternal_5b7e --> etorchAppOrchestration: 200 OK
etorchAppOrchestration --> etorchAppControllers: assembled response
etorchAppControllers --> Merchant: HTTP 201 Created
```

## Related

- Architecture dynamic view: `dynamic-etorchHotelDataManagement`
- Related flows: [Deal Update Batch Job](deal-update-batch-job.md), [Accounting Report Generation](accounting-report-generation.md)
- [API Surface](../api-surface.md) — endpoint definitions for `/contacts` and `/recent_auto_updates`
- [Integrations](../integrations.md) — Getaways Inventory, Getaways Content, Notification Service details
