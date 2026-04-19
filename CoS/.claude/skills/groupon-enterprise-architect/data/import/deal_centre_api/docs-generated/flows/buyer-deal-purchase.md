---
service: "deal_centre_api"
title: "Buyer Deal Purchase"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "buyer-deal-purchase"
flow_type: synchronous
trigger: "Buyer selects and purchases a deal option via Deal Centre UI"
participants:
  - "dealCentreUi"
  - "continuumDealCentreApi"
  - "dca_apiControllers"
  - "dca_domainServices"
  - "dca_persistenceLayer"
  - "dca_messageBusIntegration"
  - "continuumDealCentrePostgres"
  - "messageBus"
architecture_ref: "dynamic-buyer-deal-purchase"
---

# Buyer Deal Purchase

## Summary

A buyer selects a deal option and initiates a purchase through the Deal Centre UI. Deal Centre API validates inventory availability, records the buyer workflow state in PostgreSQL, decrements the inventory count, and publishes an inventory updated event to the Message Bus. The buyer receives a purchase confirmation response.

## Trigger

- **Type**: api-call
- **Source**: Deal Centre UI (`dealCentreUi`) submits a buyer purchase request
- **Frequency**: On demand — triggered by buyer action

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Centre UI | Initiates the buyer purchase request | `dealCentreUi` |
| API Controllers | Receives and routes the HTTP request | `dca_apiControllers` |
| Domain Services | Orchestrates inventory validation and purchase logic | `dca_domainServices` |
| Persistence Layer | Reads inventory and writes buyer workflow state | `dca_persistenceLayer` |
| Deal Centre Postgres | Stores inventory and buyer workflow records | `continuumDealCentrePostgres` |
| Message Bus Integration | Publishes inventory updated event | `dca_messageBusIntegration` |
| Message Bus | Receives and routes the inventory updated event | `messageBus` |

## Steps

1. **Receives purchase request**: Buyer submits a request to purchase a specific deal option.
   - From: `dealCentreUi`
   - To: `dca_apiControllers`
   - Protocol: REST/JSON over HTTPS

2. **Routes to domain services**: API Controllers validates the request and invokes Domain Services.
   - From: `dca_apiControllers`
   - To: `dca_domainServices`
   - Protocol: Spring MVC (direct)

3. **Validates inventory availability**: Domain Services reads current inventory for the requested option from PostgreSQL.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

4. **Persists buyer workflow state**: Domain Services creates a buyer workflow record and decrements inventory in PostgreSQL.
   - From: `dca_persistenceLayer`
   - To: `continuumDealCentrePostgres`
   - Protocol: JPA/JDBC

5. **Publishes inventory updated event**: Domain Services triggers Message Bus Integration to publish an inventory updated event.
   - From: `dca_messageBusIntegration`
   - To: `messageBus`
   - Protocol: MBus

6. **Returns purchase confirmation**: API Controllers returns a purchase confirmation response to the buyer.
   - From: `dca_apiControllers`
   - To: `dealCentreUi`
   - Protocol: REST/JSON over HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory unavailable (sold out) | Domain Services detects zero inventory; rejects the purchase | 409 Conflict returned to buyer UI |
| PostgreSQL write failure | JPA exception; transaction rolled back | 500 Internal Server Error; purchase not recorded |
| MBus publish failure | Event publish fails; purchase still recorded (best-effort publish) | Inventory event may be delayed or lost; core purchase succeeds |
| Concurrent purchase (race condition) | Optimistic locking via JPA; retry or reject | 409 Conflict if inventory decremented by concurrent request |

## Sequence Diagram

```
dealCentreUi -> dca_apiControllers: POST /buyer/deals/{dealId}/purchase (optionId)
dca_apiControllers -> dca_domainServices: purchaseDeal(dealId, optionId, buyerId)
dca_domainServices -> dca_persistenceLayer: readInventory(optionId)
dca_persistenceLayer -> continuumDealCentrePostgres: SELECT inventory (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: inventory record
dca_persistenceLayer --> dca_domainServices: inventory count
dca_domainServices -> dca_persistenceLayer: saveBuyerWorkflow + decrementInventory
dca_persistenceLayer -> continuumDealCentrePostgres: INSERT workflow, UPDATE inventory (JPA/JDBC)
continuumDealCentrePostgres --> dca_persistenceLayer: OK
dca_domainServices -> dca_messageBusIntegration: publishInventoryUpdated(optionId, delta)
dca_messageBusIntegration -> messageBus: inventory updated event (MBus)
messageBus --> dca_messageBusIntegration: ACK
dca_domainServices --> dca_apiControllers: purchase confirmation
dca_apiControllers --> dealCentreUi: 200 OK (confirmation payload)
```

## Related

- Architecture dynamic view: `dynamic-buyer-deal-purchase`
- Related flows: [Inventory Event Processing](inventory-event-processing.md), [Merchant Deal Creation](merchant-deal-creation.md)
