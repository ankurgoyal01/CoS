---
service: "seo-deal-api"
title: "Deal SEO Attribute Read"
generated: "2026-03-03"
type: flow
flow_name: "deal-seo-attribute-read"
flow_type: synchronous
trigger: "GET /seodeals/deals/{dealId} called by seo-admin-ui or other consumers"
participants:
  - "seo-admin-ui"
  - "continuumSeoDealApiService"
  - "seoDealApi_apiResources"
  - "orchestrator"
  - "seoDataDao"
  - "continuumSeoDealPostgres"
  - "continuumDealCatalogService"
  - "continuumTaxonomyService"
  - "continuumInventoryService"
  - "continuumM3PlacesService"
architecture_ref: "components-seoDealApiServiceComponents"
---

# Deal SEO Attribute Read

## Summary

When the `seo-admin-ui` admin console or another consumer needs to display SEO information for a specific deal, it calls `GET /seodeals/deals/{dealId}`. The SEO Deal API retrieves the stored SEO attributes from its own PostgreSQL database and optionally assembles an enriched response by calling multiple downstream Continuum services (Deal Catalog, Taxonomy, Inventory, M3 Places). The enriched response includes canonical URL, redirect URL, noindex flag, brand overrides, and title attributes.

## Trigger

- **Type**: api-call
- **Source**: `seo-admin-ui` DealServerClient (`getDeal(dealId)`) or any HTTP consumer
- **Frequency**: On-demand, per admin console page load or deal lookup

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `seo-admin-ui` | Initiates the request; presents SEO data to admin users | External consumer |
| `continuumSeoDealApiService` | Receives the request and coordinates the response | `continuumSeoDealApiService` |
| API Resources (`seoDealApi_apiResources`) | Handles the inbound HTTP GET request | `seoDealApi_apiResources` |
| Orchestrator (`orchestrator`) | Coordinates data retrieval from the database and downstream services | `orchestrator` |
| SEO Data DAO (`seoDataDao`) | Reads SEO attributes from PostgreSQL | `seoDataDao` |
| SEO Deal Database | Stores SEO deal attributes | `continuumSeoDealPostgres` |
| Deal Catalog Service | Provides deal title, permalink, and UUID data | `continuumDealCatalogService` |
| Taxonomy Service | Provides taxonomy/category data for the deal | `continuumTaxonomyService` |
| Inventory Service | Provides inventory state for the deal | `continuumInventoryService` |
| M3 Places Service | Provides place/location data for the deal | `continuumM3PlacesService` |

## Steps

1. **Receives deal SEO request**: `seo-admin-ui` calls `GET /seodeals/deals/{dealId}` via the Gofer HTTP client
   - From: `seo-admin-ui`
   - To: `continuumSeoDealApiService`
   - Protocol: REST/HTTP

2. **Routes to API Resources**: The Dropwizard/JAX-RS router dispatches the request to the API Resources component
   - From: `continuumSeoDealApiService`
   - To: `seoDealApi_apiResources`
   - Protocol: Direct (in-process)

3. **Delegates to Orchestrator**: API Resources delegates the retrieval and assembly work to the Orchestrator
   - From: `seoDealApi_apiResources`
   - To: `orchestrator`
   - Protocol: Direct (in-process)

4. **Reads SEO attributes from database**: The Orchestrator calls the SEO Data DAO to fetch stored SEO attributes for the deal
   - From: `orchestrator`
   - To: `seoDataDao`
   - Protocol: Direct (in-process)

5. **Queries PostgreSQL**: SEO Data DAO executes a JDBI query against `continuumSeoDealPostgres`
   - From: `seoDataDao`
   - To: `continuumSeoDealPostgres`
   - Protocol: JDBC/SQL

6. **Fetches deal catalog data**: Orchestrator calls the Deal Catalog Client to retrieve deal title and permalink
   - From: `orchestrator`
   - To: `seoDealApi_dealCatalogClient` -> `continuumDealCatalogService`
   - Protocol: REST/HTTP

7. **Fetches taxonomy data**: Orchestrator calls the Taxonomy Client to retrieve category data
   - From: `orchestrator`
   - To: `seoDealApi_taxonomyClient` -> `continuumTaxonomyService`
   - Protocol: REST/HTTP

8. **Fetches inventory data**: Orchestrator calls the Inventory Client to retrieve inventory state
   - From: `orchestrator`
   - To: `seoDealApi_inventoryClient` -> `continuumInventoryService`
   - Protocol: REST/HTTP

9. **Fetches place data**: Orchestrator calls the M3 Client to retrieve location data
   - From: `orchestrator`
   - To: `m3Client` -> `continuumM3PlacesService`
   - Protocol: REST/HTTP

10. **Assembles enriched response**: Orchestrator combines SEO attributes with data from downstream services
    - From: `orchestrator`
    - To: `seoDealApi_apiResources`
    - Protocol: Direct (in-process)

11. **Returns JSON response**: API Resources serializes the assembled deal SEO data and returns HTTP 200
    - From: `continuumSeoDealApiService`
    - To: `seo-admin-ui`
    - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal not found in PostgreSQL | Return HTTP 404 | `seo-admin-ui` handles `seo.err.statusCode === 404` gracefully; continues with empty attributes |
| Downstream service unavailable (Deal Catalog, Taxonomy, etc.) | Not specified in available evidence | Partial enrichment or error propagated |
| Database connection failure | Not specified in available evidence | HTTP 500 returned |

## Sequence Diagram

```
seo-admin-ui -> continuumSeoDealApiService: GET /seodeals/deals/{dealId}
continuumSeoDealApiService -> seoDealApi_apiResources: Route request
seoDealApi_apiResources -> orchestrator: Delegate orchestration
orchestrator -> seoDataDao: Read SEO attributes
seoDataDao -> continuumSeoDealPostgres: SQL SELECT by deal UUID
continuumSeoDealPostgres --> seoDataDao: SEO attribute rows
seoDataDao --> orchestrator: SEO attributes
orchestrator -> continuumDealCatalogService: Fetch deal data
continuumDealCatalogService --> orchestrator: Deal title, permalink
orchestrator -> continuumTaxonomyService: Fetch taxonomy data
continuumTaxonomyService --> orchestrator: Category data
orchestrator -> continuumInventoryService: Fetch inventory data
continuumInventoryService --> orchestrator: Inventory state
orchestrator -> continuumM3PlacesService: Fetch place data
continuumM3PlacesService --> orchestrator: Location data
orchestrator --> seoDealApi_apiResources: Assembled SEO deal response
seoDealApi_apiResources --> seo-admin-ui: HTTP 200 JSON { seoData, attributes, noindex, ... }
```

## Related

- Architecture dynamic view: `components-seoDealApiServiceComponents`
- Related flows: [Deal SEO Attribute Update](deal-seo-attribute-update.md)
