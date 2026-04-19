---
service: "cases-service"
title: "Knowledge Management Search"
generated: "2026-03-03"
type: flow
flow_name: "knowledge-management-search"
flow_type: synchronous
trigger: "Merchant searches for self-service help articles before or instead of submitting a support case"
participants:
  - "merchantSupportClient"
  - "continuumMerchantCaseService"
  - "cases_apiResources"
  - "cases_domainServices"
  - "cases_knowledgeAndCache"
  - "cases_integrationClients"
  - "inbentaKnowledgeApi"
  - "continuumMerchantCaseRedis"
architecture_ref: "dynamic-cases-case-flow"
---

# Knowledge Management Search

## Summary

MCS provides a knowledge management (KM) layer that allows merchants to browse and search help articles before submitting a support case. Article content is served from Inbenta, a third-party AI-powered knowledge management platform. MCS selects the correct Inbenta endpoint and authenticates using per-locale API keys and JWT secrets. Session bootstrapping (`POST /v1/km/bootstrap`) establishes an Inbenta session. The service supports full-text search, topic browsing, popular articles, and suggested articles based on issue sub-category. Results may be cached in Redis for performance.

## Trigger

- **Type**: api-call
- **Source**: Merchant Center frontend (`merchantSupportClient`) via `GET /v1/merchants/{merchantuuid}/km/search` or other `/km/*` endpoints
- **Frequency**: On-demand per merchant help search or topic browse action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant Center frontend | Initiator — searches for help content | `merchantSupportClient` |
| API Resources | Receives HTTP request, validates auth | `cases_apiResources` |
| Knowledge and Cache Management | Orchestrates Inbenta queries, Redis caching, and session management | `cases_knowledgeAndCache` |
| Integration Clients | Makes authenticated HTTP calls to Inbenta per-locale endpoints | `cases_integrationClients` |
| Inbenta Knowledge API | Provides locale-specific knowledge articles and search results | `inbentaKnowledgeApi` |
| Merchant Cases Redis | Caches knowledge session tokens and frequently accessed content | `continuumMerchantCaseRedis` |

## Steps

### Session Bootstrap (`POST /v1/km/bootstrap`)

1. **Receive bootstrap request**: Merchant Center sends `POST /v1/km/bootstrap` with optional `query` parameters and `X-Auth-ID` header.
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Authenticate with Inbenta**: Knowledge and Cache Management calls the Inbenta Auth API (`https://api.inbenta.io`) with the per-locale `apiKey` and `secret` to obtain a session token.
   - From: `cases_integrationClients`
   - To: `inbentaKnowledgeApi` (auth endpoint)
   - Protocol: HTTPS/REST

3. **Cache session token**: The session token is stored in Redis keyed by locale/merchant context.
   - From: `cases_knowledgeAndCache`
   - To: `continuumMerchantCaseRedis`
   - Protocol: Redis

4. **Return bootstrap response**: Session details returned to Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200)

### Full-Text Search (`GET /v1/merchants/{merchantuuid}/km/search`)

1. **Receive search request**: Merchant Center sends request with `search_query`, optional `locale`, `page`, `per_page`, `include_meta`, `addArticleDescription` parameters and `X-User-ID` / `user-agent` headers.
   - From: `merchantSupportClient`
   - To: `cases_apiResources`
   - Protocol: REST

2. **Determine locale and Inbenta endpoint**: Knowledge and Cache Management maps the `locale` parameter to the appropriate Inbenta cluster URL (e.g., `api-gcu1.inbenta.io` for EN, `api-gce3.inbenta.io` for DE/ES/FR/IT).
   - From: `cases_knowledgeAndCache`
   - To: internal config
   - Protocol: direct

3. **Query Inbenta**: Integration Clients sends the search query to Inbenta with the per-locale `x-inbenta-key` API key header.
   - From: `cases_integrationClients`
   - To: `inbentaKnowledgeApi`
   - Protocol: HTTPS/REST (`connectTimeout: 2s`, `readTimeout: 5s`)

4. **Return search results**: API Resources returns the article list with titles, descriptions, and metadata to Merchant Center.
   - From: `cases_apiResources`
   - To: `merchantSupportClient`
   - Protocol: REST (HTTP 200)

### Topic Browsing and Article Retrieval

The same locale resolution and Inbenta call pattern applies for:
- `GET /km/topics` — list all topics
- `GET /km/topics/{topicId}` — single topic details
- `GET /km/topics/{topicId}/articles` — articles in topic
- `GET /km/topics/{topicId}/articles/{articleId}` — single article
- `GET /km/topics/{topicId}/articles/{articleId}/related` — related articles
- `GET /km/articles/popular` — most viewed articles
- `GET /km/articles/suggested` — articles suggested by `issueSubCategoryId`

## Supported Locales

| Locale Key | Inbenta Cluster |
|-----------|----------------|
| EN | api-gcu1.inbenta.io |
| JA | api-gcu1.inbenta.io |
| UK_EN, IE_EN | api-gcu1.inbenta.io |
| BE_NL | api-gcu1.inbenta.io |
| DE, ES, FR, IT, NL, PL, BE_FR | api-gce3.inbenta.io |
| AE_EN, AU_EN, QC_FR | api-gcu3.inbenta.io |
| NZ_EN | api-gcu2.inbenta.io |

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inbenta API unavailable | Non-blocking — knowledge endpoints return error | Merchant cannot browse articles; case creation still works |
| Expired session token | Re-authenticate via Inbenta Auth API and retry | Transparent to the merchant |
| Unsupported locale | Returns empty results or default locale fallback | Graceful degradation |
| Redis unavailable | Cache miss — re-fetch from Inbenta directly | Slightly higher latency; functional |

## Sequence Diagram

```
MerchantCenter -> cases_apiResources: GET /v1/merchants/{uuid}/km/search?search_query=refund&locale=en
cases_apiResources -> cases_knowledgeAndCache: search knowledge
cases_knowledgeAndCache -> cases_integrationClients: call Inbenta (EN locale)
cases_integrationClients -> InbentaAPI: GET /km/search?query=refund [x-inbenta-key: ${EN_APIKEY}]
InbentaAPI --> cases_integrationClients: articles [{title, body, url}...]
cases_knowledgeAndCache -> Redis: SET km:search:en:refund {results} (optional cache)
cases_apiResources --> MerchantCenter: HTTP 200 {articles: [...]}
```

## Related

- Architecture dynamic view: `dynamic-cases-case-flow`
- Related flows: [Case Creation](case-creation.md)
