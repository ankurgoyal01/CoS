---
service: "deal-catalog-service"
title: "Deal Browsing and Retrieval"
generated: "2026-03-03"
type: flow
flow_name: "deal-browsing-retrieval"
flow_type: synchronous
trigger: "Consumer API request via Lazlo"
participants:
  - "consumer"
  - "apiProxy"
  - "continuumApiLazloService"
  - "continuumDealCatalogService"
  - "dealCatalog_api"
  - "dealCatalog_repository"
  - "continuumDealCatalogDb"
  - "continuumRelevanceApi"
architecture_ref: "dynamic-continuum-deal-catalog"
---

# Deal Browsing and Retrieval

## Summary

This flow describes how consumers browse and retrieve deal information through Groupon's consumer-facing applications. The request flows from the consumer through the API Proxy and Lazlo API gateway, which fetches deal metadata from the Deal Catalog Service and personalized ranking from the Relevance API. The Catalog API queries deal data from the MySQL database via the Catalog Repository.

## Trigger

- **Type**: User action (consumer browses or searches for deals)
- **Source**: Consumer application (web, mobile) via API Proxy and Lazlo
- **Frequency**: Per request -- high volume, latency-sensitive

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer | End user browsing deals | `consumer` |
| API Proxy | Routes consumer requests to Lazlo | `apiProxy` |
| API Lazlo | API gateway that orchestrates deal retrieval | `continuumApiLazloService` |
| Deal Catalog Service | Returns deal metadata | `continuumDealCatalogService` |
| Catalog API | Handles deal metadata queries | `dealCatalog_api` |
| Catalog Repository | Queries deal data from database | `dealCatalog_repository` |
| Deal Catalog DB | Stores deal metadata | `continuumDealCatalogDb` |
| Relevance API | Provides personalized ranking and search results | `continuumRelevanceApi` |

## Steps

1. **Consumer initiates browse/search**: The consumer opens the Groupon app or website and browses or searches for deals.
   - From: `consumer`
   - To: `apiProxy`
   - Protocol: HTTPS

2. **API Proxy routes to Lazlo**: The API Proxy forwards the request to the Lazlo API gateway.
   - From: `apiProxy`
   - To: `continuumApiLazloService`
   - Protocol: HTTP/JSON

3. **Lazlo fetches deal metadata**: Lazlo calls the Deal Catalog Service to retrieve deal metadata (titles, categories, availability, merchandising attributes).
   - From: `continuumApiLazloService`
   - To: `continuumDealCatalogService` / `dealCatalog_api`
   - Protocol: HTTP/JSON over internal network

4. **Catalog API queries repository**: The Catalog API delegates to the Catalog Repository to fetch deal data.
   - From: `dealCatalog_api`
   - To: `dealCatalog_repository`
   - Protocol: SQL (JPA)

5. **Repository queries database**: The Catalog Repository executes SQL queries against the Deal Catalog DB.
   - From: `dealCatalog_repository`
   - To: `continuumDealCatalogDb`
   - Protocol: JDBC

6. **Deal metadata returned to Lazlo**: The Catalog API returns deal metadata to Lazlo.
   - From: `dealCatalog_api`
   - To: `continuumApiLazloService`
   - Protocol: HTTP/JSON

7. **Lazlo fetches personalized ranking**: In parallel (or sequentially), Lazlo calls the Relevance API for personalized deal ranking and search results.
   - From: `continuumApiLazloService`
   - To: `continuumRelevanceApi`
   - Protocol: HTTP/JSON

8. **Lazlo assembles response**: Lazlo combines deal metadata with personalized ranking to build the final consumer response.
   - From: `continuumApiLazloService`
   - To: `consumer` (via `apiProxy`)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unavailable | Lazlo returns degraded response or cached data | Consumer may see stale or reduced deal listings |
| Database query timeout | Catalog API returns error; Lazlo handles gracefully | Partial or empty deal results for the consumer |
| Relevance API unavailable | Lazlo falls back to default ranking | Deals displayed without personalization |

## Sequence Diagram

```
Consumer -> API Proxy: Browse/search deals (HTTPS)
API Proxy -> Lazlo: Route request (HTTP/JSON)
Lazlo -> Deal Catalog Service: Fetch deal metadata (HTTP/JSON)
Deal Catalog Service -> Catalog Repository: Query deals (JPA)
Catalog Repository -> Deal Catalog DB: SQL query (JDBC)
Deal Catalog DB --> Catalog Repository: Deal records
Catalog Repository --> Deal Catalog Service: Deal entities
Deal Catalog Service --> Lazlo: Deal metadata (JSON)
Lazlo -> Relevance API: Get personalized ranking (HTTP/JSON)
Relevance API --> Lazlo: Ranked deal IDs
Lazlo --> API Proxy: Assembled deal response
API Proxy --> Consumer: Deal listings (HTTPS)
```

## Related

- Architecture dynamic view: `dynamic-continuum-deal-catalog`
- Related flows: [Deal Metadata Ingestion](deal-metadata-ingestion.md)
