---
service: "dynamic_pricing"
title: "Bulk Program Price Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bulk-program-price-creation"
flow_type: synchronous
trigger: "POST /pricing_service/v2.0/program_price"
participants:
  - "continuumDynamicPricingNginx"
  - "continuumPricingService_programPriceController"
  - "continuumPricingService_programPriceService"
  - "continuumPricingService_visHttpClient"
  - "continuumPricingService_dealCatalogClient"
  - "continuumPricingService_pricingDbRepository"
  - "continuumPricingService_priceUpdateWorkflow"
  - "continuumPricingService_mbusPublishers"
  - "continuumVoucherInventoryService"
  - "continuumDealCatalogService"
  - "continuumPricingDb"
  - "continuumMbusBroker"
architecture_ref: "dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow"
---

# Bulk Program Price Creation

## Summary

This flow handles a synchronous bulk request to create or update program prices for one or more products. Before writing, the service validates each request against live inventory data from the Voucher Inventory Service and deal metadata from the Deal Catalog Service. Validated entries are written transactionally to the pricing database, then the price update pipeline is triggered to invalidate caches and publish program price events.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum services submitting program price batches via `apiProxy` and `continuumDynamicPricingNginx`
- **Frequency**: On-demand, triggered by deal creation or pricing campaigns

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dynamic Pricing NGINX | Receives and proxies inbound request | `continuumDynamicPricingNginx` |
| Program Price Bulk Controller | Accepts bulk program price payload | `continuumPricingService_programPriceController` |
| Program Price Service | Orchestrates validation, deal lookups, and transactional writes | `continuumPricingService_programPriceService` |
| VIS HTTP Client | Fetches product capacity from Voucher Inventory Service | `continuumPricingService_visHttpClient` |
| Deal Catalog Client | Fetches deal metadata for validation | `continuumPricingService_dealCatalogClient` |
| Pricing DB Repository | Stores program price schedules and reference data | `continuumPricingService_pricingDbRepository` |
| Price Update Workflow | Triggers update pipeline post-validation | `continuumPricingService_priceUpdateWorkflow` |
| MBus Producers | Publishes `dynamic.pricing.update` and `program_price_events` | `continuumPricingService_mbusPublishers` |
| Voucher Inventory Service | Provides product inventory capacity data | `continuumVoucherInventoryService` |
| Deal Catalog Service | Provides deal metadata for validation | `continuumDealCatalogService` |
| Pricing Service DB | Persists program price records | `continuumPricingDb` |
| MBus Broker | Receives and distributes program price events | `continuumMbusBroker` |

## Steps

1. **Receive bulk request**: Caller sends POST to `/pricing_service/v2.0/program_price` with a batch of program price entries.
   - From: `apiProxy`
   - To: `continuumDynamicPricingNginx`
   - Protocol: HTTPS

2. **Proxy to service**: NGINX routes the request to a pricing write pod.
   - From: `continuumDynamicPricingNginx`
   - To: `continuumPricingService_programPriceController`
   - Protocol: HTTP

3. **Submit payload to service**: Controller delegates the parsed payload to the Program Price Service.
   - From: `continuumPricingService_programPriceController`
   - To: `continuumPricingService_programPriceService`
   - Protocol: direct

4. **Fetch VIS product capacity**: Service calls VIS to retrieve inventory capacity data for each product in the batch.
   - From: `continuumPricingService_visHttpClient`
   - To: `continuumVoucherInventoryService`
   - Protocol: HTTP

5. **Fetch deal metadata**: Service calls Deal Catalog to retrieve deal details required for program price validation.
   - From: `continuumPricingService_dealCatalogClient`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP

6. **Store program price schedules**: Validated entries are written to `continuumPricingDb` including schedule and reference data.
   - From: `continuumPricingService_pricingDbRepository`
   - To: `continuumPricingDb`
   - Protocol: JDBC

7. **Trigger price update pipeline**: Program Price Service invokes the Price Update Workflow for each committed entry.
   - From: `continuumPricingService_programPriceService`
   - To: `continuumPricingService_priceUpdateWorkflow`
   - Protocol: direct

8. **Publish program price events**: Workflow publishes `dynamic.pricing.update` and `program_price_events` to MBus.
   - From: `continuumPricingService_mbusPublishers`
   - To: `continuumMbusBroker`
   - Protocol: JMS

9. **Return bulk result**: Service returns success/failure status per entry to the caller.
   - From: `continuumPricingService_programPriceController`
   - To: `apiProxy` (via `continuumDynamicPricingNginx`)
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VIS unavailable | Validation fails; no writes performed | Caller receives error; entire batch rejected |
| Deal Catalog unavailable | Validation fails; no writes performed | Caller receives error; entire batch rejected |
| Partial DB write failure | Transaction rolled back per entry | Failed entries reported in response; successful entries committed |
| MBus publish failure | Program prices written but events not sent | Downstream consumers receive no notification |

## Sequence Diagram

```
apiProxy -> continuumDynamicPricingNginx: POST /pricing_service/v2.0/program_price
continuumDynamicPricingNginx -> continuumPricingService_programPriceController: Proxy bulk request (HTTP)
continuumPricingService_programPriceController -> continuumPricingService_programPriceService: Submit bulk program price payload
continuumPricingService_programPriceService -> continuumVoucherInventoryService: Fetch product capacity (HTTP)
continuumVoucherInventoryService --> continuumPricingService_programPriceService: Inventory capacity data
continuumPricingService_programPriceService -> continuumDealCatalogService: Fetch deal metadata (HTTP)
continuumDealCatalogService --> continuumPricingService_programPriceService: Deal metadata
continuumPricingService_programPriceService -> continuumPricingDb: Store program price schedules (JDBC)
continuumPricingService_programPriceService -> continuumPricingService_priceUpdateWorkflow: Trigger price update pipeline
continuumPricingService_priceUpdateWorkflow -> continuumMbusBroker: Publish dynamic.pricing.update + program_price_events (JMS)
continuumPricingService_programPriceController --> continuumDynamicPricingNginx: Bulk result response
continuumDynamicPricingNginx --> apiProxy: Bulk result response
```

## Related

- Architecture dynamic view: `dynamic-pricing-update-continuumPricingService_priceUpdateWorkflow`
- Related flows: [Create Retail Price](create-retail-price.md), [Inventory Event Processing](inventory-event-processing.md)
