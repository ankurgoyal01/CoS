---
service: "clo-inventory-service"
title: "CLO Offer Claim"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "clo-offer-claim"
flow_type: synchronous
trigger: "HTTP POST request to create a reservation or claim a CLO offer"
participants:
  - "continuumCloInventoryService_httpApiInventory"
  - "continuumCloInventoryService_facades"
  - "continuumCloInventoryService_coreUnitAndReservationServices"
  - "continuumCloInventoryService_coreUserService"
  - "continuumCloInventoryService_persistenceRepositories"
  - "continuumCloInventoryService_dataAccessPostgres"
  - "continuumCloInventoryService_externalIntegrations"
  - "continuumCloInventoryDb"
  - "continuumCloCoreService"
architecture_ref: "components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService"
---

# CLO Offer Claim

## Summary

The CLO Offer Claim flow processes a user's request to claim a card-linked offer. When a claim request arrives, the service creates a reservation against the inventory, allocates a unit, records the user's claim interaction, and forwards the claim to the CLO Core Service for offer activation on the card network. The flow enforces purchase controls to prevent over-claiming and ensures inventory consistency via transactional persistence.

## Trigger

- **Type**: api-call
- **Source**: HTTP POST to reservation or claim endpoint via `CloProductResource` or `UserResource`
- **Frequency**: On-demand, triggered by consumer-facing applications when a user activates a CLO offer

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API - Inventory | Receives the claim/reservation HTTP request | `continuumCloInventoryService_httpApiInventory` |
| Domain Facades | Routes the operation to Unit & Reservation Services and User Service | `continuumCloInventoryService_facades` |
| Unit & Reservation Services | Creates reservation, allocates unit, enforces purchase controls | `continuumCloInventoryService_coreUnitAndReservationServices` |
| User Service | Records the user's claim interaction and reward state | `continuumCloInventoryService_coreUserService` |
| Domain Repositories | Persists reservation, unit allocation, and user interaction records | `continuumCloInventoryService_persistenceRepositories` |
| Postgres Data Access | Executes SQL operations for reservations, units, and user records | `continuumCloInventoryService_dataAccessPostgres` |
| External Service Integrations | Forwards the claim to CLO Core Service | `continuumCloInventoryService_externalIntegrations` |
| CLO Inventory Database | Stores reservation, unit, and user claim records | `continuumCloInventoryDb` |
| CLO Core Service | Activates the CLO offer claim on the card network | `continuumCloCoreService` |

## Steps

1. **Receive claim request**: HTTP API - Inventory receives a POST request from a consumer-facing application with the user's claim details (user ID, product/offer ID)
   - From: External caller (consumer application)
   - To: `continuumCloInventoryService_httpApiInventory`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to facade**: The API resource invokes `ReservationFacade` or `UnitFacade` for the claim operation
   - From: `continuumCloInventoryService_httpApiInventory`
   - To: `continuumCloInventoryService_facades`
   - Protocol: In-process call

3. **Check purchase controls**: Unit & Reservation Services (`CloPurchaseControlService`) validates that the user is eligible to claim and that inventory is available
   - From: `continuumCloInventoryService_facades`
   - To: `continuumCloInventoryService_coreUnitAndReservationServices`
   - Protocol: In-process call

4. **Create reservation**: `CloReservationService` creates a reservation record against the inventory product, locking a unit for the user
   - From: `continuumCloInventoryService_coreUnitAndReservationServices`
   - To: `continuumCloInventoryService_persistenceRepositories` -> `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

5. **Allocate unit**: `CloUnitService` allocates an inventory unit to the reservation, marking it as claimed
   - From: `continuumCloInventoryService_coreUnitAndReservationServices`
   - To: `continuumCloInventoryService_persistenceRepositories` -> `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

6. **Record user interaction**: User Service (`CloUserService`) records the claim event against the user's reward and interaction state
   - From: `continuumCloInventoryService_facades`
   - To: `continuumCloInventoryService_coreUserService` -> `continuumCloInventoryService_persistenceRepositories` -> `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: In-process call / JDBI over JDBC

7. **Forward claim to CLO Core**: External Service Integrations forwards the claim to CLO Core Service for offer activation on the card network
   - From: `continuumCloInventoryService_externalIntegrations`
   - To: `continuumCloCoreService`
   - Protocol: HTTP/JSON via `CloClient`

8. **Return response**: Claim confirmation flows back through the facade and API layer to the caller
   - From: `continuumCloInventoryService_httpApiInventory`
   - To: External caller
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Inventory exhausted | Purchase control check rejects the claim; HTTP 409 returned | User informed that offer is no longer available; no state changes |
| User already claimed | Purchase control check detects duplicate claim; HTTP 409 returned | Idempotent rejection; user informed they have already claimed this offer |
| Reservation/unit persistence failure | Database transaction rolled back; HTTP 500 returned | No partial state; caller must retry |
| CLO Core Service unavailable | Reservation and unit allocated locally; claim forwarding fails | Reservation exists in inventory; CLO Core activation may need reconciliation |
| Concurrent claim race condition | Database-level constraints prevent double allocation | One claim succeeds, concurrent claim receives 409 |

## Sequence Diagram

```
Consumer App -> HTTP API - Inventory: POST /clo/reservations (userId, productId)
HTTP API - Inventory -> Domain Facades: claimOffer(userId, productId)
Domain Facades -> Unit & Reservation Services: checkPurchaseControls(userId, productId)
Unit & Reservation Services -> Domain Repositories: lookupExistingClaims(userId, productId)
Domain Repositories -> Postgres Data Access: SELECT reservations (SQL)
Postgres Data Access -> CLO Inventory DB: Query
CLO Inventory DB --> Postgres Data Access: Existing claims (if any)
Unit & Reservation Services -> Domain Repositories: createReservation(reservation)
Domain Repositories -> Postgres Data Access: INSERT reservation (SQL)
Postgres Data Access -> CLO Inventory DB: INSERT
Unit & Reservation Services -> Domain Repositories: allocateUnit(unitId, reservationId)
Domain Repositories -> Postgres Data Access: UPDATE unit status (SQL)
Postgres Data Access -> CLO Inventory DB: UPDATE
Domain Facades -> User Service: recordClaimInteraction(userId, productId)
User Service -> Domain Repositories: saveUserInteraction(interaction)
Domain Repositories -> Postgres Data Access: INSERT/UPDATE user record (SQL)
Unit & Reservation Services -> External Integrations: forwardClaim(claimData)
External Integrations -> CLO Core Service: POST /claims (HTTP/JSON)
CLO Core Service --> External Integrations: Claim activated
External Integrations --> Unit & Reservation Services: Confirmation
Domain Facades --> HTTP API - Inventory: Claim result
HTTP API - Inventory --> Consumer App: 201 Created (claim confirmation)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService`
- Related flows: [Inventory Product Creation](inventory-product-creation.md), [Card Enrollment](card-enrollment.md), [Consent Management](consent-management.md)
- See [Integrations](../integrations.md) for CLO Core Service details
- See [Data Stores](../data-stores.md) for PostgreSQL reservation and unit tables
