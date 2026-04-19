---
service: "mls-rin"
title: "Unit Search"
generated: "2026-03-03"
type: flow
flow_name: "unit-search"
flow_type: synchronous
trigger: "HTTP POST to /units/v1/search or /units/v2/search or /units/v2/find"
participants:
  - "continuumMlsRinService"
  - "mlsRinUnitIndexDb"
  - "continuumVoucherInventoryService"
  - "continuumGLiveInventoryService"
  - "continuumInventoryService"
  - "continuumOrdersService"
  - "continuumPricingService"
  - "continuumM3MerchantService"
architecture_ref: "dynamic-continuumMlsRinService"
---

# Unit Search

## Summary

The Unit Search flow is the most complex flow in MLS RIN. It accepts a structured search request specifying merchant(s), inventory product criteria, filters, sort order, and a field projection (`show` parameter). MLS RIN's Unit Search Domain Services orchestrate parallel calls to one or more federated inventory services (VIS, GLive, Getaways, TPIS, and others) based on per-inventory-service feature flags. Results are enriched with order data, pricing context, merchant details, and rendered into a unified unit search response. For batch unit fetch (`/units/v2/find`), a list of unit references is resolved directly.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (Merchant Center portal or internal reporting tool) sending an HTTP POST
- **Frequency**: On-demand (per user/system request); can be high-volume during Merchant Center page loads

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MLS RIN Service | Orchestrator — parses request, fans out to inventory services, enriches, renders | `continuumMlsRinService` |
| MLS RIN Unit Index DB | Local cache of unit sold counts for fast aggregation | `mlsRinUnitIndexDb` |
| Voucher Inventory Service (VIS) | Primary inventory service for voucher units | `continuumVoucherInventoryService` |
| GLive Inventory Service | Inventory service for Groupon Live event units | `continuumGLiveInventoryService` |
| Federated Inventory Service (FIS) / Getaways | Inventory service for Getaways and other FIS-backed inventory | `continuumInventoryService` |
| Orders Service | Provides order data for ORDER show-field enrichment | `continuumOrdersService` |
| Pricing Service | Provides pricing context and ILS program resolution | `continuumPricingService` |
| M3 Merchant Service | Provides merchant account details for MERCHANT show-field | `continuumM3MerchantService` |

## Steps

1. **Receive unit search request**: Accepts POST on `/units/v1/search` or `/units/v2/search` with a `UnitSearchRequest` body (merchant criteria, inventory product filters, sort, pagination, show-fields) or `/units/v2/find` with a `UnitBatchRequest` body.
   - From: `caller`
   - To: `continuumMlsRinService`
   - Protocol: REST / HTTP

2. **Authenticate and validate**: JTier auth bundle validates client-ID; elevated client IDs (from `elevatedClientIds` config) are permitted to request PAYLOADS show-field.
   - From: `continuumMlsRinService`
   - To: `mlsRin_apiLayer` (internal)
   - Protocol: direct

3. **Resolve inventory products** (conditional): If per-IS feature flag `needsProductsInQuery` is set, resolve inventory product UUIDs from MANA deal index before querying the inventory service.
   - From: `continuumMlsRinService`
   - To: `continuumMarketingDealService` (if needed)
   - Protocol: REST / HTTP (Retrofit)

4. **Fan out to enabled inventory services**: For each enabled inventory service (controlled by `unitSearch.fisSpecificFeatures.enabled`), issue parallel unit search/fetch requests. VIS and GLive use Retrofit clients; Getaways and others use the FIS Client API. Services configured with `singleMerchantQueries` receive split per-merchant requests.
   - From: `continuumMlsRinService`
   - To: `continuumVoucherInventoryService`, `continuumGLiveInventoryService`, `continuumInventoryService` (in parallel)
   - Protocol: REST / HTTP (Retrofit / FIS Client)

5. **Query local unit index for sold counts** (conditional — `CountStyle.aggregateViaLocalCache`): For inventory services configured to use local count cache, query `mlsRinUnitIndexDb` for pre-aggregated sold counts instead of calling the inventory service.
   - From: `continuumMlsRinService`
   - To: `mlsRinUnitIndexDb`
   - Protocol: JDBI/PostgreSQL

6. **Fetch order data** (conditional — ORDER show-field requested): Calls Orders Service to retrieve order and billing records for matched units.
   - From: `continuumMlsRinService`
   - To: `continuumOrdersService`
   - Protocol: REST / HTTP (Retrofit)

7. **Resolve pricing context** (conditional — pricing/ILS-related show-fields): Calls Pricing Service to resolve ILS program pricing for applicable units.
   - From: `continuumMlsRinService`
   - To: `continuumPricingService`
   - Protocol: REST / HTTP (Retrofit)

8. **Fetch merchant details** (conditional — MERCHANT show-field requested): Calls M3 Merchant Service for merchant account details.
   - From: `continuumMlsRinService`
   - To: `continuumM3MerchantService`
   - Protocol: REST / HTTP (Retrofit)

9. **Enrich and render units**: Unit Search Domain Services apply post-expiration grace period logic (country-specific), retained value rules, redeemability flags, price formatting, and service remapping. Results are merged and sorted.
   - From/To: `continuumMlsRinService` (internal)
   - Protocol: direct

10. **Return paginated unit search response**: Returns JSON with matched units and requested show-field data.
    - From: `continuumMlsRinService`
    - To: `caller`
    - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory service unavailable | Optional clients fail gracefully; required clients propagate error | Units from failed service omitted; others returned |
| Unit index DB unavailable | Falls back to FIS-based count strategies if configured | Degraded count accuracy but response continues |
| Orders Service unavailable | RxJava error; ORDER fields omitted | Units returned without order data |
| Pricing Service unavailable | RxJava error; pricing fields omitted | Units returned without pricing data |
| Invalid request body | JAX-RS validation | HTTP 400 returned |
| Unsupported ISID in request | Controlled by `enabledIsid` feature flag | Unsupported ISIDs excluded from results |

## Sequence Diagram

```
Caller -> continuumMlsRinService: POST /units/v1/search {merchantId, filters, show=[VOUCHER,ORDER]}
continuumMlsRinService -> mlsRin_apiLayer: validate auth (client-id)
continuumMlsRinService -> continuumVoucherInventoryService: search units (parallel)
continuumMlsRinService -> continuumGLiveInventoryService: search units (parallel, if enabled)
continuumVoucherInventoryService --> continuumMlsRinService: unit list
continuumGLiveInventoryService --> continuumMlsRinService: unit list
continuumMlsRinService -> mlsRinUnitIndexDb: get sold counts (if aggregateViaLocalCache)
mlsRinUnitIndexDb --> continuumMlsRinService: sold counts
continuumMlsRinService -> continuumOrdersService: fetch orders for unit_ids (if ORDER requested)
continuumOrdersService --> continuumMlsRinService: order records
continuumMlsRinService -> mlsRin_unitSearchDomain: enrich + render units
continuumMlsRinService --> Caller: JSON unit search response
```

## Related

- Architecture dynamic view: `dynamic-continuumMlsRinService`
- Related flows: [Deal List Query](deal-list-query.md)
