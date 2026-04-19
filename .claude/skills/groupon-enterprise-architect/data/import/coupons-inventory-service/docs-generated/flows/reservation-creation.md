---
service: "coupons-inventory-service"
title: "Reservation Creation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "reservation-creation"
flow_type: synchronous
trigger: "API request to create a reservation (POST /reservations)"
participants:
  - "continuumCouponsInventoryService_reservationApi"
  - "continuumCouponsInventoryService_reservationDomain"
  - "continuumCouponsInventoryService_validation"
  - "continuumCouponsInventoryService_productRepository"
  - "continuumCouponsInventoryService_reservationRepository"
  - "continuumCouponsInventoryService_jdbiInfrastructure"
  - "continuumCouponsInventoryService_voucherCloudClient"
architecture_ref: "dynamic-reservation-creation"
---

# Reservation Creation

## Summary

This flow handles the creation of a reservation against coupon inventory. The Reservation API receives the request, the Reservation Domain validates the request and checks inventory state, loads the associated product, optionally fetches unique redemption codes from VoucherCloud for deals that require them, and persists the reservation to Postgres. The product record may also be updated as part of the reservation flow.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service calling POST /reservations
- **Frequency**: on-demand, per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Reservation API | Receives the HTTP reservation request | `continuumCouponsInventoryService_reservationApi` |
| Reservation Domain | Orchestrates validation, product loading, VoucherCloud call, and persistence | `continuumCouponsInventoryService_reservationDomain` |
| Validation & DTO Factories | Validates reservation requests and inventory state | `continuumCouponsInventoryService_validation` |
| Product Repository | Loads and updates the associated product record | `continuumCouponsInventoryService_productRepository` |
| Reservation Repository | Persists the reservation record | `continuumCouponsInventoryService_reservationRepository` |
| Jdbi Persistence Infrastructure | Provides DAO and mapper layer for database operations | `continuumCouponsInventoryService_jdbiInfrastructure` |
| VoucherCloud Client | Fetches unique redemption codes for eligible reservations | `continuumCouponsInventoryService_voucherCloudClient` |

## Steps

1. **Receive reservation request**: The Reservation API receives a POST request with reservation data.
   - From: `External caller`
   - To: `continuumCouponsInventoryService_reservationApi`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Reservation Domain**: The API resource delegates to the Reservation Domain facade.
   - From: `continuumCouponsInventoryService_reservationApi`
   - To: `continuumCouponsInventoryService_reservationDomain`
   - Protocol: JAX-RS call

3. **Validate reservation request**: The Reservation Domain validates the reservation request and checks inventory state constraints.
   - From: `continuumCouponsInventoryService_reservationDomain`
   - To: `continuumCouponsInventoryService_validation`
   - Protocol: In-process call

4. **Load associated product**: The Reservation Domain loads the product record to verify inventory availability and product state.
   - From: `continuumCouponsInventoryService_reservationDomain`
   - To: `continuumCouponsInventoryService_productRepository`
   - Protocol: Jdbi, Postgres

5. **Fetch redemption codes (conditional)**: If the deal requires unique redemption codes, the Reservation Domain calls VoucherCloud to fetch them.
   - From: `continuumCouponsInventoryService_reservationDomain`
   - To: `continuumCouponsInventoryService_voucherCloudClient`
   - Protocol: HTTP/JSON

6. **Persist reservation**: The Reservation Domain saves the reservation record to Postgres via the Reservation Repository.
   - From: `continuumCouponsInventoryService_reservationDomain`
   - To: `continuumCouponsInventoryService_reservationRepository`
   - Protocol: Jdbi, Postgres

7. **Update product state**: The Reservation Domain updates the product record as part of the reservation flow (e.g., decrement available inventory).
   - From: `continuumCouponsInventoryService_reservationDomain`
   - To: `continuumCouponsInventoryService_productRepository`
   - Protocol: Jdbi, Postgres

8. **Return response**: The Reservation API returns the created reservation to the caller.
   - From: `continuumCouponsInventoryService_reservationApi`
   - To: `External caller`
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Validation failure | Validation rejects request; HTTP 400 returned | Client receives 400 Bad Request with error details |
| Product not found | Product Repository returns null; domain rejects reservation | Client receives 404 or 400 depending on error mapping |
| Insufficient inventory | Validation detects insufficient available units | Client receives 409 Conflict or 400 Bad Request |
| VoucherCloud unavailable | HTTP client timeout or error | Client receives 500 or 503; reservation not created |
| VoucherCloud returns insufficient codes | Not enough redemption codes available | Client receives error; reservation not created |
| Database write failure | Jdbi throws exception; transaction rolls back | Client receives 500 Internal Server Error; no reservation created |

## Sequence Diagram

```
Caller -> Reservation API: POST /reservations (JSON body)
Reservation API -> Reservation Domain: createReservation(request)
Reservation Domain -> Validation: validateReservation(request)
Validation --> Reservation Domain: validated
Reservation Domain -> Product Repository: loadProduct(productId)
Product Repository -> Jdbi Infrastructure: SELECT product
Jdbi Infrastructure --> Product Repository: product record
Product Repository --> Reservation Domain: product
opt requires unique redemption codes
    Reservation Domain -> VoucherCloud Client: fetchRedemptionCodes(params)
    VoucherCloud Client --> Reservation Domain: redemption codes
end
Reservation Domain -> Reservation Repository: saveReservation(reservation)
Reservation Repository -> Jdbi Infrastructure: INSERT reservation
Reservation Domain -> Product Repository: updateProduct(product)
Product Repository -> Jdbi Infrastructure: UPDATE product
Reservation Domain --> Reservation API: reservation created
Reservation API --> Caller: 201 Created (reservation JSON)
```

## Related

- Architecture component view: `components-continuum-coupons-inventory-service`
- Related flows: [Product Creation](product-creation.md)
