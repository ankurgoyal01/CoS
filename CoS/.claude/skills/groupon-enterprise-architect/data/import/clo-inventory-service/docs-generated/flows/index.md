---
service: "clo-inventory-service"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for CLO Inventory Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Inventory Product Creation](inventory-product-creation.md) | synchronous | HTTP POST to create a CLO inventory product | Creates a new CLO inventory product by aggregating deal catalog data, pricing, and merchant metadata, then synchronizes the offer to CLO Core Service |
| [CLO Offer Claim](clo-offer-claim.md) | synchronous | HTTP POST to create a reservation or claim | Processes a user's claim on a CLO offer by creating a reservation, allocating a unit, and forwarding the claim to CLO Core Service |
| [Card Enrollment](card-enrollment.md) | synchronous | HTTP POST to enroll a user's card | Enrolls a user's card for card-linked offers by verifying network status, persisting enrollment state, and synchronizing with CLO Core Service |
| [Consent Management](consent-management.md) | synchronous | HTTP POST/DELETE to create, update, or revoke consent | Manages user consent records for CLO participation, including consent creation, updates, revocation, and history tracking |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- The [Inventory Product Creation](inventory-product-creation.md) flow spans `continuumCloInventoryService`, `continuumDealCatalogService`, `continuumM3MerchantService`, and `continuumCloCoreService`
- The [CLO Offer Claim](clo-offer-claim.md) flow spans `continuumCloInventoryService` and `continuumCloCoreService`
- The [Card Enrollment](card-enrollment.md) flow spans `continuumCloInventoryService`, `continuumCloCardInteractionService`, and `continuumCloCoreService`
- The [Consent Management](consent-management.md) flow is primarily internal to `continuumCloInventoryService` with persistence to `continuumCloInventoryDb`

> Dynamic views for these flows are not yet defined in Structurizr. See the `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService` component diagram for static component relationships.
