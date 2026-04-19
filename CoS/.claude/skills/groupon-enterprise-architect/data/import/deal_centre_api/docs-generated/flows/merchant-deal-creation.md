---
service: "deal_centre_api"
title: "Merchant Deal Creation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "merchant-deal-creation"
flow_type: synchronous
trigger: "Merchant submits a new deal via Deal Centre UI"
participants:
  - "dealCentreUi"
  - "continuumDealCentreApi"
  - "dca_apiControllers"
  - "dca_domainServices"
  - "dca_persistenceLayer"
  - "dca_externalClients"
  - "continuumDealManagementApi"
  - "continuumDealCentrePostgres"
architecture_ref: "dynamic-merchant-deal-creation"
---

# Merchant Deal Creation

## Summary

A merchant submits a new deal through the Deal Centre UI. Deal Centre API receives the request, validates it, delegates the authoritative deal and option creation to Deal Management API, and persists the resulting deal record to the Deal Centre PostgreSQL database. On success the API returns the created deal to the UI.

## Trigger

- **Type**: api-call
- **Source**: Deal Centre UI (`dealCentreUi`) submits a `POST /deals` request
- **Frequency**: On demand — triggered by merchant action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Centre UI | Initiates the deal creation request | `dealCentreUi` |
| API Controllers | Receives and routes the HTTP request | `dca_apiControllers` |
| Domain Services | Orchestrates business logic for deal creation | `dca_domainServices` |
| External Service Clients | Calls Deal Management API | `dca_externalClients` |
| Deal Management API | Authoritative deal and option creation | `continuumDealManagementApi` |
| Persistence Layer | Persists deal record to PostgreSQL | `dca_persistenceLayer` |
| Deal Centre Postgres | Stores the created deal and option records | `continuumDealCentrePostgres` |

## Steps

1. **Receives deal creation request**: Deal Centre UI submits `POST /deals` with deal details (title, dates, options, merchant ID).
   - From: `dealCentreUi`
   - To: `dca_apiControllers`
   - Protocol: REST/JSON over HTTPS

2. **Routes request to domain services**: API Controllers validates the incoming payload and invokes Domain Services.
   - From: `dca_apiControllers`
   - To: `dca_domainServices`
   - Protocol: Spring MVC (direct)

3. **Delegates deal creation to Deal Management API**: Domain Services calls DMAPI to create the authoritative deal record and its options/products.
   - From: `dca_externalClients`
   - To: `continuumDealManagementApi`
   - Protocol: HTTP

4. **Persists deal reference to PostgreSQL**: Domain Services instructs Persistence Layer to write the deal record (including the DMAPI-issued deal ID) to the Deal Centre database.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

5. **Returns created deal response**: API Controllers serializes the created deal and returns `201 Created` with the deal payload to the UI.
   - From: `dca_apiControllers`
   - To: `dealCentreUi`
   - Protocol: REST/JSON over HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DMAPI unreachable | HTTP error propagated by `dca_externalClients`; no DB write | 502 Bad Gateway or 503 to merchant UI |
| DMAPI validation error | DMAPI returns 4xx; Domain Services surfaces error | 400/422 returned to merchant UI with error detail |
| PostgreSQL write failure | JPA exception caught by Domain Services | 500 Internal Server Error; deal record not created |
| Invalid request payload | `dca_apiControllers` rejects before invoking domain logic | 400 Bad Request returned immediately |

## Sequence Diagram

```
dealCentreUi -> dca_apiControllers: POST /deals (deal payload)
dca_apiControllers -> dca_domainServices: createDeal(request)
dca_domainServices -> dca_externalClients: callDmapi(dealPayload)
dca_externalClients -> continuumDealManagementApi: POST /deals (HTTP)
continuumDealManagementApi --> dca_externalClients: 201 Created (dealId)
dca_externalClients --> dca_domainServices: dealId
dca_domainServices -> dca_persistenceLayer: saveDeal(dealRecord)
dca_persistenceLayer -> continuumDealCentrePostgres: INSERT deal (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: OK
dca_persistenceLayer --> dca_domainServices: saved deal
dca_domainServices --> dca_apiControllers: created deal
dca_apiControllers --> dealCentreUi: 201 Created (deal payload)
```

## Related

- Architecture dynamic view: `dynamic-merchant-deal-creation`
- Related flows: [Buyer Deal Purchase](buyer-deal-purchase.md), [Product Catalog Management](product-catalog-management.md)
