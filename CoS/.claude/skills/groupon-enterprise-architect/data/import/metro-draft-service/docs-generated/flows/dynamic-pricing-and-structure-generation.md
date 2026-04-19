---
service: "metro-draft-service"
title: "Dynamic Pricing and Structure Generation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "dynamic-pricing-and-structure-generation"
flow_type: synchronous
trigger: "Internal call from Deal Service or Products Resource during deal creation or product update"
participants:
  - "continuumMetroDraftService_dynamicPdsService"
  - "continuumMetroDraftService_dealService"
  - "continuumMetroDraftService_productsResource"
  - "continuumMetroDraftService_recommendationService"
  - "continuumMetroDraftService_recommendationResource"
  - "continuumMetroDraftService_pdsConfigDao"
  - "continuumMetroDraftService_inferPdsClient"
  - "continuumMetroDraftService_geoTaxonomyClients"
  - "continuumMetroDraftService_dealCatalogClient"
  - "continuumInferPdsService"
  - "continuumTaxonomyService"
  - "continuumGeoPlacesService"
  - "continuumGeoDetailsService"
  - "continuumDealCatalogService"
  - "continuumMetroDraftDb"
architecture_ref: "dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation"
---

# Dynamic Pricing and Structure Generation

## Summary

When a deal is created or a product is updated, Metro Draft Service generates dynamic pricing structure (PDS) defaults, fine print text, and deal structure recommendations. Dynamic PDS Service orchestrates this by combining stored PDS configuration, geo and taxonomy metadata, and AI-powered pricing recommendations from Infer PDS Service. The Recommendation Service separately provides deal structure suggestions using Deal Catalog data and Infer PDS signals. The output — enriched pricing defaults, fine print, and structure options — is returned to the caller for deal population.

## Trigger

- **Type**: internal (called within deal creation and product update flows)
- **Source**: Deal Service (during `POST /api/deals` and `PUT /api/deals/{id}`); Products Resource (during product fine print and pricing step updates); Recommendation Resource (for explicit structure recommendation requests)
- **Frequency**: Per deal creation and product update

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service | Triggers Dynamic PDS Service during deal creation/update | `continuumMetroDraftService_dealService` |
| Products Resource | Triggers Dynamic PDS Service during product pricing step updates | `continuumMetroDraftService_productsResource` |
| Recommendation Resource | Triggers Recommendation Service for structure recommendations | `continuumMetroDraftService_recommendationResource` |
| Dynamic PDS Service | Orchestrates pricing defaults, fine print generation, and structure | `continuumMetroDraftService_dynamicPdsService` |
| Recommendation Service | Orchestrates deal structure recommendation generation | `continuumMetroDraftService_recommendationService` |
| PDS Config DAO | Supplies stored PDS defaults and configuration | `continuumMetroDraftService_pdsConfigDao` |
| Infer PDS Client | Calls Infer PDS Service for AI pricing suggestions | `continuumMetroDraftService_inferPdsClient` |
| Geo & Taxonomy Clients | Supplies taxonomy and geo metadata for validation and defaults | `continuumMetroDraftService_geoTaxonomyClients` |
| Deal Catalog Client | Supplies catalog context for structure recommendations | `continuumMetroDraftService_dealCatalogClient` |
| Infer PDS Service | Returns AI-generated pricing recommendations | `continuumInferPdsService` |
| Taxonomy Service | Returns taxonomy classification for the deal category | `continuumTaxonomyService` |
| GeoPlaces Service | Returns geo metadata for the merchant's location | `continuumGeoPlacesService` |
| GeoDetails Service | Returns detailed geo information for merchants | `continuumGeoDetailsService` |
| Deal Catalog Service | Returns catalog context for structure recommendations | `continuumDealCatalogService` |
| Metro Draft DB | Stores and retrieves PDS configuration | `continuumMetroDraftDb` |

## Steps

1. **Request pricing defaults**: Deal Service or Products Resource calls Dynamic PDS Service with deal type, merchant context, and country.
   - From: `continuumMetroDraftService_dealService` or `continuumMetroDraftService_productsResource`
   - To: `continuumMetroDraftService_dynamicPdsService`
   - Protocol: Internal call

2. **Load PDS configuration**: Dynamic PDS Service reads stored pricing defaults and templates from PDS Config DAO.
   - From: `continuumMetroDraftService_dynamicPdsService`
   - To: `continuumMetroDraftService_pdsConfigDao` -> `continuumMetroDraftDb`
   - Protocol: JDBI

3. **Resolve taxonomy metadata**: Dynamic PDS Service calls Geo & Taxonomy Clients to validate the deal's taxonomy classification.
   - From: `continuumMetroDraftService_dynamicPdsService` -> `continuumMetroDraftService_geoTaxonomyClients`
   - To: `continuumTaxonomyService`
   - Protocol: HTTP/Retrofit

4. **Resolve geo metadata**: Dynamic PDS Service calls Geo & Taxonomy Clients to enrich the merchant location with geo data.
   - From: `continuumMetroDraftService_dynamicPdsService` -> `continuumMetroDraftService_geoTaxonomyClients`
   - To: `continuumGeoPlacesService`, `continuumGeoDetailsService`
   - Protocol: HTTP/Retrofit

5. **Request AI pricing suggestions**: Dynamic PDS Service calls Infer PDS Client to get AI-generated price recommendations for the deal type and market.
   - From: `continuumMetroDraftService_dynamicPdsService` -> `continuumMetroDraftService_inferPdsClient`
   - To: `continuumInferPdsService`
   - Protocol: HTTP/Retrofit

6. **Generate fine print and pricing defaults**: Dynamic PDS Service combines PDS config, taxonomy, geo, and Infer PDS output to produce a structured set of pricing defaults and Freemarker-rendered fine print.
   - From: `continuumMetroDraftService_dynamicPdsService` (internal computation)
   - To: (no external call; Freemarker template rendering)
   - Protocol: Internal

7. **Return enriched defaults**: Dynamic PDS Service returns pricing defaults and fine print to the calling service (Deal Service or Products Resource).
   - From: `continuumMetroDraftService_dynamicPdsService`
   - To: `continuumMetroDraftService_dealService` or `continuumMetroDraftService_productsResource`
   - Protocol: Internal call return

8. **Request structure recommendations (parallel path)**: Recommendation Resource calls Recommendation Service for deal structure suggestions.
   - From: `continuumMetroDraftService_recommendationResource`
   - To: `continuumMetroDraftService_recommendationService`
   - Protocol: Internal call (JAX-RS)

9. **Fetch catalog context for recommendations**: Recommendation Service calls Deal Catalog Client to retrieve comparable deals and catalog context.
   - From: `continuumMetroDraftService_recommendationService` -> `continuumMetroDraftService_dealCatalogClient`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP/Retrofit

10. **Fetch recommendation data from Infer PDS**: Recommendation Service calls Infer PDS Client for recommendation signals.
    - From: `continuumMetroDraftService_recommendationService` -> `continuumMetroDraftService_inferPdsClient`
    - To: `continuumInferPdsService`
    - Protocol: HTTP/Retrofit

11. **Return structure recommendations**: Recommendation Service returns deal structure options to Recommendation Resource for API response.
    - From: `continuumMetroDraftService_recommendationService`
    - To: `continuumMetroDraftService_recommendationResource`
    - Protocol: Internal call return

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Infer PDS Service unavailable | Dynamic PDS Service falls back to stored PDS config defaults | Deal created with default pricing; no AI recommendations |
| Taxonomy Service unavailable | Dynamic PDS Service proceeds with partial defaults (no taxonomy validation) | Deal may have unvalidated taxonomy; downstream validation catches issues |
| GeoPlaces / GeoDetails unavailable | Dynamic PDS Service proceeds without geo enrichment | Deal created without geo-enriched defaults |
| PDS Config DAO read failure | Database exception propagates; deal creation fails | 500 returned; no deal created |
| Deal Catalog Service unavailable (recommendations) | Recommendation Service returns empty/default structure options | Recommendations not available; merchant must manually configure structure |

## Sequence Diagram

```
DealService -> DynamicPdsService: generateDefaults(dealType, merchant, country)
DynamicPdsService -> PdsConfigDao: loadPdsConfig(dealType, country)
PdsConfigDao --> DynamicPdsService: PDS config templates
DynamicPdsService -> GeoTaxonomyClients: getTaxonomy(categoryId)
GeoTaxonomyClients -> TaxonomyService: fetch taxonomy
TaxonomyService --> GeoTaxonomyClients: taxonomy metadata
DynamicPdsService -> GeoTaxonomyClients: getGeoData(merchantPlaceId)
GeoTaxonomyClients -> GeoPlacesService: geo places
GeoPlacesService --> GeoTaxonomyClients: geo data
DynamicPdsService -> InferPdsClient: getPriceSuggestions(dealType, geo, taxonomy)
InferPdsClient -> InferPdsService: price suggestions request
InferPdsService --> InferPdsClient: pricing recommendations
DynamicPdsService --> DealService: enriched pricing defaults + fine print

RecommendationResource -> RecommendationService: getStructureRecommendations(dealId)
RecommendationService -> DealCatalogClient: fetchCatalogContext(dealId)
DealCatalogClient -> DealCatalogService: catalog data
DealCatalogService --> DealCatalogClient: catalog context
RecommendationService -> InferPdsClient: getRecommendationData(dealId)
InferPdsClient -> InferPdsService: recommendation signals
InferPdsService --> InferPdsClient: signals
RecommendationService --> RecommendationResource: structure recommendations
```

## Related

- Architecture dynamic view: `dynamic-continuum-metro-draft-continuumMetroDraftService_dealService-deal-creation`
- Related flows: [Merchant Deal Draft Creation](merchant-deal-draft-creation.md), [Deal Publishing Orchestration](deal-publishing-orchestration.md)
