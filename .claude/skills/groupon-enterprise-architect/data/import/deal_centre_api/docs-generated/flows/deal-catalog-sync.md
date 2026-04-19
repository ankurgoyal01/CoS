---
service: "deal_centre_api"
title: "Deal Catalog Sync"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "deal-catalog-sync"
flow_type: event-driven
trigger: "Deal catalog event delivered by Message Bus"
participants:
  - "messageBus"
  - "continuumDealCentreApi"
  - "dca_messageBusIntegration"
  - "dca_domainServices"
  - "dca_externalClients"
  - "dca_persistenceLayer"
  - "continuumDealCatalogService"
  - "continuumDealCentrePostgres"
architecture_ref: "dynamic-deal-catalog-sync"
---

# Deal Catalog Sync

## Summary

The Message Bus delivers an inbound deal catalog event to Deal Centre API. The `dca_messageBusIntegration` component receives the event and triggers Domain Services to synchronize the local deal catalog state. Domain Services may look up additional catalog data from Deal Catalog Service via `dca_externalClients` before persisting the updated catalog records to `continuumDealCentrePostgres`.

## Trigger

- **Type**: event
- **Source**: `messageBus` — deal catalog channel; event published by Deal Catalog Service or other Continuum services when catalog data changes
- **Frequency**: On demand — triggered whenever a deal catalog event is published to the Message Bus

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Message Bus | Delivers the catalog event to the consumer | `messageBus` |
| Message Bus Integration | Receives the event and triggers domain processing | `dca_messageBusIntegration` |
| Domain Services | Applies catalog sync business logic | `dca_domainServices` |
| External Service Clients | Fetches additional catalog detail from Deal Catalog Service | `dca_externalClients` |
| Deal Catalog Service | Provides authoritative catalog data on lookup | `continuumDealCatalogService` |
| Persistence Layer | Writes synchronized catalog state to PostgreSQL | `dca_persistenceLayer` |
| Deal Centre Postgres | Stores the synchronized catalog records | `continuumDealCentrePostgres` |

## Steps

1. **Delivers catalog event**: Message Bus routes the deal catalog event to Deal Centre API's consumer.
   - From: `messageBus`
   - To: `dca_messageBusIntegration`
   - Protocol: MBus

2. **Triggers domain processing**: Message Bus Integration deserializes the event and invokes Domain Services.
   - From: `dca_messageBusIntegration`
   - To: `dca_domainServices`
   - Protocol: Spring (direct internal call)

3. **Looks up catalog data** (if enrichment is needed): Domain Services calls Deal Catalog Service via External Service Clients to retrieve the latest authoritative catalog record for the affected deal ID.
   - From: `dca_externalClients`
   - To: `continuumDealCatalogService`
   - Protocol: HTTP

4. **Persists synchronized catalog state**: Domain Services instructs Persistence Layer to upsert the catalog record in PostgreSQL.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

5. **Acknowledges event**: Message Bus Integration acknowledges the event on successful processing.
   - From: `dca_messageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus ACK

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Deal Catalog Service unreachable | `dca_externalClients` HTTP error; event not acknowledged | MBus redelivers event; catalog state not updated until service recovers |
| Malformed event payload | Deserialization error in `dca_messageBusIntegration` | Event retried or sent to DLQ by MBus infrastructure |
| PostgreSQL write failure | JPA exception; message not acknowledged | MBus redelivers event; potential duplicate processing on retry |

## Sequence Diagram

```
messageBus -> dca_messageBusIntegration: catalog event (MBus)
dca_messageBusIntegration -> dca_domainServices: processCatalogEvent(payload)
dca_domainServices -> dca_externalClients: fetchCatalogData(dealId)
dca_externalClients -> continuumDealCatalogService: GET /catalog/deals/{dealId} (HTTP)
continuumDealCatalogService --> dca_externalClients: catalog record
dca_externalClients --> dca_domainServices: catalog data
dca_domainServices -> dca_persistenceLayer: upsertCatalogRecord(catalogData)
dca_persistenceLayer -> continuumDealCentrePostgres: UPSERT product/catalog (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: OK
dca_domainServices --> dca_messageBusIntegration: processing complete
dca_messageBusIntegration -> messageBus: ACK
```

## Related

- Architecture dynamic view: `dynamic-deal-catalog-sync`
- Related flows: [Inventory Event Processing](inventory-event-processing.md), [Product Catalog Management](product-catalog-management.md)
