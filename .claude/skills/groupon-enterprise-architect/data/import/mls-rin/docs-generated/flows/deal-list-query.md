---
service: "mls-rin"
title: "Deal List Query"
generated: "2026-03-03"
type: flow
flow_name: "deal-list-query"
flow_type: synchronous
trigger: "HTTP GET or POST to /v1/deals or /v1/dealsv2"
participants:
  - "continuumMlsRinService"
  - "mlsRinDealIndexDb"
  - "continuumMarketingDealService"
  - "continuumDealCatalogService"
  - "continuumBhuvanService"
  - "continuumUgcService"
architecture_ref: "dynamic-continuumMlsRinService"
---

# Deal List Query

## Summary

The Deal List Query flow serves requests for a paginated list of deals associated with one or more merchants. MLS RIN queries its local deal index PostgreSQL database for deal records matching the provided filters, then optionally enriches the response with data from MANA (deal analytics), Deal Catalog (deal templates), Geoplaces (divisions), and UGC (discussion summaries) based on the caller's requested `show` field projection. The caller receives a structured JSON response containing deal metadata, counts, earnings, cap status, and other requested data sections.

## Trigger

- **Type**: api-call
- **Source**: Internal consumer (Merchant Center portal, mx-merchant-analytics, or other internal service) sending an HTTP GET or POST request
- **Frequency**: On-demand (per user/system request)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MLS RIN Service | Orchestrator — receives request, queries DB, fans out to enrichment services, assembles response | `continuumMlsRinService` |
| MLS RIN Deal Index DB | Primary data source for deal index records | `mlsRinDealIndexDb` |
| MANA / Marketing Deal Service | Provides deal analytics data and additional deal-index fields | `continuumMarketingDealService` |
| Deal Catalog Service | Provides deal template and catalog metadata | `continuumDealCatalogService` |
| Geoplaces (Bhuvan) | Resolves division and geographic location data | `continuumBhuvanService` |
| UGC Service | Provides discussion/review summary for deals | `continuumUgcService` |

## Steps

1. **Receive deal list request**: Accepts GET or POST on `/v1/deals`, `/v1/dealsv2`, or `GET /v1/deals/{deal_id}` with query parameters (merchant_id, deal_ids, deal_status, inventory_service, order, order_by, page, per_page, locale, show).
   - From: `caller`
   - To: `continuumMlsRinService`
   - Protocol: REST / HTTP

2. **Authenticate caller**: JTier auth bundle validates client-ID credentials against the configured role map. Requests must carry the `ROLE_READ` role.
   - From: `continuumMlsRinService`
   - To: `mlsRin_apiLayer` (internal)
   - Protocol: direct

3. **Query deal index database**: Deal Domain Services issue JDBI SQL queries against `mlsRinDealIndexDb` using the provided filter criteria (merchant_id, deal_ids, status, inventory_service, sorting, pagination).
   - From: `continuumMlsRinService`
   - To: `mlsRinDealIndexDb`
   - Protocol: JDBI/PostgreSQL

4. **Enrich with MANA deal analytics** (conditional — when `counts`, `earnings`, `stats`, or `cap` show-fields are requested): Issues HTTP call to MANA to fetch analytics and deal-index supplemental data.
   - From: `continuumMlsRinService`
   - To: `continuumMarketingDealService`
   - Protocol: REST / HTTP (Retrofit)

5. **Enrich with Deal Catalog** (conditional — when `deal`, `products`, or `fineprint` show-fields are requested): Fetches deal template and catalog metadata from the Deal Catalog service.
   - From: `continuumMlsRinService`
   - To: `continuumDealCatalogService`
   - Protocol: REST / HTTP (Retrofit)

6. **Resolve divisions / geoplaces** (conditional — when `divisions` or `redemptionLocationIds` show-fields are requested): Calls Geoplaces to resolve geographic division data.
   - From: `continuumMlsRinService`
   - To: `continuumBhuvanService`
   - Protocol: REST / HTTP (Retrofit)

7. **Fetch UGC summaries** (conditional — when `discussion` show-field is requested): Calls UGC service to retrieve discussion/review count summaries per deal.
   - From: `continuumMlsRinService`
   - To: `continuumUgcService`
   - Protocol: REST / HTTP (Retrofit)

8. **Assemble and return response**: Merges deal index records with enrichment data, applies locale formatting, and returns paginated JSON response.
   - From: `continuumMlsRinService`
   - To: `caller`
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal index DB unavailable | JDBI connection failure propagates | HTTP 500 returned to caller |
| MANA enrichment call fails | RxJava error handling; partial enrichment | Deal list returned with missing analytics fields |
| Deal Catalog call fails | RxJava error handling; partial enrichment | Deal list returned without catalog metadata |
| Geoplaces call fails | RxJava error handling | Deal list returned without division data |
| Invalid filter parameters | JAX-RS parameter validation | HTTP 400 returned |
| Authentication failure | JTier auth bundle rejects | HTTP 401 / 403 returned |

## Sequence Diagram

```
Caller -> continuumMlsRinService: GET/POST /v1/deals?merchant_id=...&show=deal,counts
continuumMlsRinService -> mlsRin_apiLayer: validate auth (client-id)
continuumMlsRinService -> mlsRinDealIndexDb: SELECT deals WHERE merchant_id=... AND status=...
mlsRinDealIndexDb --> continuumMlsRinService: deal records (paginated)
continuumMlsRinService -> continuumMarketingDealService: GET analytics for deal_ids (if counts requested)
continuumMarketingDealService --> continuumMlsRinService: analytics data
continuumMlsRinService -> continuumDealCatalogService: GET catalog for deal_ids (if deal fields requested)
continuumDealCatalogService --> continuumMlsRinService: catalog metadata
continuumMlsRinService --> Caller: JSON deal list response
```

## Related

- Architecture dynamic view: `dynamic-continuumMlsRinService`
- Related flows: [Unit Search](unit-search.md), [Metrics Retrieval](metrics-retrieval.md)
