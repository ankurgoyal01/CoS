---
service: "deal_centre_api"
title: "Product Catalog Management"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "product-catalog-management"
flow_type: synchronous
trigger: "Admin submits a product catalog create or update via Deal Centre UI"
participants:
  - "dealCentreUi"
  - "continuumDealCentreApi"
  - "dca_apiControllers"
  - "dca_domainServices"
  - "dca_persistenceLayer"
  - "dca_messageBusIntegration"
  - "continuumDealCentrePostgres"
  - "messageBus"
architecture_ref: "dynamic-product-catalog-management"
---

# Product Catalog Management

## Summary

An admin creates or updates a product catalog entry through Deal Centre UI. Deal Centre API receives the request, applies catalog business logic, persists the catalog record to PostgreSQL, and publishes a deal catalog updated event to the Message Bus so that downstream Continuum services (including Deal Catalog Service) can synchronize their catalog state.

## Trigger

- **Type**: api-call
- **Source**: Deal Centre UI (`dealCentreUi`) submits a `POST /catalog/products` or `PUT /catalog/products/{productId}` request
- **Frequency**: On demand — triggered by admin action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Centre UI | Initiates the catalog create or update request | `dealCentreUi` |
| API Controllers | Receives and routes the HTTP request | `dca_apiControllers` |
| Domain Services | Applies catalog business logic | `dca_domainServices` |
| Persistence Layer | Persists catalog record to PostgreSQL | `dca_persistenceLayer` |
| Deal Centre Postgres | Stores the catalog product record | `continuumDealCentrePostgres` |
| Message Bus Integration | Publishes deal catalog updated event | `dca_messageBusIntegration` |
| Message Bus | Receives and routes the catalog updated event to downstream consumers | `messageBus` |

## Steps

1. **Receives catalog request**: Admin submits a create or update request for a product catalog entry.
   - From: `dealCentreUi`
   - To: `dca_apiControllers`
   - Protocol: REST/JSON over HTTPS

2. **Routes to domain services**: API Controllers validates the request and invokes Domain Services.
   - From: `dca_apiControllers`
   - To: `dca_domainServices`
   - Protocol: Spring MVC (direct)

3. **Applies catalog business logic**: Domain Services validates the catalog entry, applies any enrichment or business rules, and prepares the record for persistence.
   - From: `dca_domainServices`
   - To: `dca_domainServices`
   - Protocol: internal

4. **Persists catalog record**: Domain Services instructs Persistence Layer to insert or update the product catalog record in PostgreSQL.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

5. **Publishes deal catalog updated event**: Domain Services triggers Message Bus Integration to publish a catalog updated event to the Message Bus.
   - From: `dca_messageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus

6. **Returns catalog response**: API Controllers returns the created or updated catalog product to the admin.
   - From: `dca_apiControllers`
   - To: `dealCentreUi`
   - Protocol: REST/JSON over HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid catalog payload | `dca_apiControllers` rejects before domain invocation | 400 Bad Request returned to admin UI |
| PostgreSQL write failure | JPA exception; no event published | 500 Internal Server Error; catalog record not persisted |
| MBus publish failure | Event publish fails after successful DB write | Catalog record persisted; downstream catalog sync delayed; manual reconciliation may be needed |

## Sequence Diagram

```
dealCentreUi -> dca_apiControllers: POST /catalog/products (product payload)
dca_apiControllers -> dca_domainServices: createOrUpdateProduct(request)
dca_domainServices -> dca_persistenceLayer: saveProduct(productRecord)
dca_persistenceLayer -> continuumDealCentrePostgres: INSERT/UPDATE product (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: OK
dca_persistenceLayer --> dca_domainServices: saved product
dca_domainServices -> dca_messageBusIntegration: publishCatalogUpdated(productId, changeType)
dca_messageBusIntegration -> messageBus: deal catalog updated event (MBus)
messageBus --> dca_messageBusIntegration: ACK
dca_domainServices --> dca_apiControllers: catalog product
dca_apiControllers --> dealCentreUi: 201 Created / 200 OK (product payload)
```

## Related

- Architecture dynamic view: `dynamic-product-catalog-management`
- Related flows: [Merchant Deal Creation](merchant-deal-creation.md), [Deal Catalog Sync](deal-catalog-sync.md)
