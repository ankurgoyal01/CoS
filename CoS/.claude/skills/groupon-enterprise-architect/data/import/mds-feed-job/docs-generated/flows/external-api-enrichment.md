---
service: "mds-feed-job"
title: "External API Enrichment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "external-api-enrichment"
flow_type: batch
trigger: "Internal — invoked by transformerPipeline during enrichment transformer steps"
participants:
  - "transformerPipeline"
  - "externalApiAdapters"
  - "continuumTaxonomyService"
  - "continuumDealCatalogService"
  - "continuumM3MerchantService"
  - "continuumPricingService"
  - "continuumTravelInventoryService"
  - "continuumVoucherInventoryService"
  - "continuumThirdPartyInventoryService"
  - "bigQuery"
  - "salesForce"
architecture_ref: "dynamic-mds-feed-job-feed-generation"
---

# External API Enrichment

## Summary

External API Enrichment is the set of outbound calls made by `externalApiAdapters` on behalf of `transformerPipeline` to fetch enrichment data from upstream Continuum services and external data platforms. Each enrichment call provides a specific data dimension (pricing, taxonomy, merchant, inventory, gift-booster, VAT) that is applied to feed deal records. All calls are HTTPS/JSON over Retrofit2/OkHttp with Failsafe retry.

## Trigger

- **Type**: internal (programmatic)
- **Source**: `transformerPipeline` during enrichment transformer step execution
- **Frequency**: Per transformer step that requires external data; called once per feed run (bulk/batch fetch patterns where possible)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Transformer Pipeline | Requests enrichment data and applies it to dataset | `transformerPipeline` |
| External API Adapters | HTTP client layer; handles retry and error handling | `externalApiAdapters` |
| Taxonomy Service | Provides taxonomy/category mappings | `continuumTaxonomyService` |
| Deal Catalog Service | Provides localized deal catalog data | `continuumDealCatalogService` |
| M3 Merchant Service | Provides merchant and place metadata | `continuumM3MerchantService` |
| Pricing Service | Provides dynamic and localized prices | `continuumPricingService` |
| Travel Inventory Service | Provides dated travel inventory details | `continuumTravelInventoryService` |
| Voucher Inventory Service | Provides voucher inventory details | `continuumVoucherInventoryService` |
| Third-Party Inventory Service | Provides TPIS availability data for TTD feeds | `continuumThirdPartyInventoryService` |
| BigQuery | Provides gift-booster enrichment signals | `bigQuery` |
| Salesforce | Provides VAT metadata | `salesForce` |

## Steps

1. **Request taxonomy mappings**: `externalApiAdapters` fetches category/taxonomy tree from Taxonomy Service for use in category field mapping transformers.
   - From: `externalApiAdapters`
   - To: `continuumTaxonomyService`
   - Protocol: HTTPS/JSON

2. **Request localized deal catalog**: `externalApiAdapters` fetches localized deal content (titles, descriptions, images) from Deal Catalog Service.
   - From: `externalApiAdapters`
   - To: `continuumDealCatalogService`
   - Protocol: HTTPS/JSON

3. **Request merchant and place metadata**: `externalApiAdapters` fetches merchant name, address, place type, and appointment metadata from M3 Merchant Service.
   - From: `externalApiAdapters`
   - To: `continuumM3MerchantService`
   - Protocol: HTTPS/JSON

4. **Request dynamic and localized prices**: `externalApiAdapters` calls Pricing Service for current prices per deal and locale.
   - From: `externalApiAdapters`
   - To: `continuumPricingService`
   - Protocol: HTTPS/JSON

5. **Request travel inventory details**: For travel deal types, `externalApiAdapters` fetches dated inventory availability from Travel Inventory Service.
   - From: `externalApiAdapters`
   - To: `continuumTravelInventoryService`
   - Protocol: HTTPS/JSON

6. **Request voucher inventory details**: For voucher deal types, `externalApiAdapters` fetches inventory counts and availability from Voucher Inventory Service.
   - From: `externalApiAdapters`
   - To: `continuumVoucherInventoryService`
   - Protocol: HTTPS/JSON

7. **Request third-party availability**: For TTD feeds, `externalApiAdapters` fetches TPIS availability data from Third-Party Inventory Service.
   - From: `externalApiAdapters`
   - To: `continuumThirdPartyInventoryService`
   - Protocol: HTTPS/JSON

8. **Read gift-booster signals**: `externalApiAdapters` queries BigQuery for gift-booster enrichment scores or signals per deal.
   - From: `externalApiAdapters`
   - To: `bigQuery`
   - Protocol: BigQuery API

9. **Query VAT metadata**: `externalApiAdapters` calls Salesforce REST API to retrieve VAT metadata for deals requiring VAT transformer application.
   - From: `externalApiAdapters`
   - To: `salesForce`
   - Protocol: HTTPS/REST

10. **Return enrichment data to pipeline**: All fetched enrichment datasets are returned to `transformerPipeline` for join/UDF application against the Spark dataset.
    - From: `externalApiAdapters`
    - To: `transformerPipeline`
    - Protocol: direct (in-process)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| HTTPS call returns 5xx or times out | Failsafe retry with backoff (Failsafe 3.3.2) | Retried up to configured max; exception thrown on exhaustion |
| HTTPS call returns 4xx (client error) | No retry (non-retriable); exception propagated | Transformer step fails; batch fails |
| BigQuery quota exceeded or API error | Failsafe retry | Retried; if exhausted, gift-booster enrichment step fails |
| Salesforce unavailable | Failsafe retry | Retried; if exhausted, VAT transformer step fails |
| Partial enrichment data returned | Transformer applies available data; missing records handled per transformer logic | Feed records may be missing enrichment fields |

## Sequence Diagram

```
transformerPipeline -> externalApiAdapters  : Fetch taxonomy mappings
externalApiAdapters -> continuumTaxonomyService : GET /taxonomy/categories
continuumTaxonomyService --> externalApiAdapters : Category tree
externalApiAdapters -> continuumDealCatalogService : GET /catalog/deals (localized)
continuumDealCatalogService --> externalApiAdapters : Localized deal data
externalApiAdapters -> continuumM3MerchantService : GET /merchants (batch)
continuumM3MerchantService --> externalApiAdapters : Merchant/place metadata
externalApiAdapters -> continuumPricingService : GET /prices (deals, locale)
continuumPricingService --> externalApiAdapters : Localized prices
externalApiAdapters -> continuumTravelInventoryService : GET /inventory/travel
continuumTravelInventoryService --> externalApiAdapters : Dated travel inventory
externalApiAdapters -> continuumVoucherInventoryService : GET /inventory/vouchers
continuumVoucherInventoryService --> externalApiAdapters : Voucher inventory
externalApiAdapters -> continuumThirdPartyInventoryService : GET /tpis/availability
continuumThirdPartyInventoryService --> externalApiAdapters : TPIS availability
externalApiAdapters -> bigQuery             : Query gift-booster signals
bigQuery --> externalApiAdapters            : Gift-booster enrichment data
externalApiAdapters -> salesForce           : GET /vat-metadata
salesForce --> externalApiAdapters          : VAT metadata
externalApiAdapters --> transformerPipeline : All enrichment datasets
```

## Related

- Architecture dynamic view: `dynamic-mds-feed-job-feed-generation`
- Related flows: [Transformer Pipeline Execution](transformer-pipeline-execution.md), [Feed Job Orchestration](feed-job-orchestration.md)
