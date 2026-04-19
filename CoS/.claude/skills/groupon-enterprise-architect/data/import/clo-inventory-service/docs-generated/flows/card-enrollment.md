---
service: "clo-inventory-service"
title: "Card Enrollment"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "card-enrollment"
flow_type: synchronous
trigger: "HTTP POST request to enroll a user's card for CLO"
participants:
  - "continuumCloInventoryService_httpApiConsent"
  - "continuumCloInventoryService_consentDomain"
  - "continuumCloInventoryService_dataAccessPostgres"
  - "continuumCloInventoryService_externalIntegrations"
  - "continuumCloInventoryDb"
  - "continuumCloCardInteractionService"
  - "continuumCloCoreService"
architecture_ref: "components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService"
---

# Card Enrollment

## Summary

The Card Enrollment flow handles enrolling a user's payment card for card-linked offers. When an enrollment request arrives via the Consent API, the service verifies the card's network onboarding status with the CLO Card Interaction Service, persists the enrollment record and billing data to PostgreSQL, and synchronizes the card enrollment state with the CLO Core Service. This flow is a prerequisite for a user to receive CLO rewards -- their card must be enrolled before offer claims can be activated on the card network.

## Trigger

- **Type**: api-call
- **Source**: HTTP POST to `/clo/consent/{userId}/enroll` via `ConsentResource`
- **Frequency**: On-demand, triggered when a user opts to enroll a card for CLO in a consumer application

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API - Consent | Receives the card enrollment HTTP request | `continuumCloInventoryService_httpApiConsent` |
| Consent Domain & Services | Orchestrates enrollment: validates card, persists enrollment, syncs to CLO Core | `continuumCloInventoryService_consentDomain` |
| Postgres Data Access | Executes SQL operations for card enrollment and billing records | `continuumCloInventoryService_dataAccessPostgres` |
| External Service Integrations | Calls CLO Card Interaction Service and CLO Core Service | `continuumCloInventoryService_externalIntegrations` |
| CLO Inventory Database | Stores card enrollment and billing records | `continuumCloInventoryDb` |
| CLO Card Interaction Service | Provides onboarded network identifiers for card verification | `continuumCloCardInteractionService` |
| CLO Core Service | Receives card enrollment state for offer activation | `continuumCloCoreService` |

## Steps

1. **Receive enrollment request**: HTTP API - Consent (`ConsentResource`) receives a POST request with user ID and card details
   - From: External caller (consumer application)
   - To: `continuumCloInventoryService_httpApiConsent`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Consent Domain**: The API resource invokes `CloCardEnrollmentService` within the Consent Domain & Services component
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: `continuumCloInventoryService_consentDomain`
   - Protocol: In-process call

3. **Verify card network status**: Consent Domain calls External Service Integrations to check onboarded network identifiers for the card with the CLO Card Interaction Service
   - From: `continuumCloInventoryService_consentDomain` -> `continuumCloInventoryService_externalIntegrations`
   - To: `continuumCloCardInteractionService`
   - Protocol: HTTP/JSON

4. **Validate consent**: Consent Domain verifies that the user has an active consent record (prerequisite for enrollment)
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

5. **Persist enrollment record**: `CardEnrollmentDao` writes the enrollment record to PostgreSQL, recording card ID, network, and enrollment status
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

6. **Persist billing record**: `BillingRecordService` creates or updates the billing record associated with the enrollment
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

7. **Synchronize enrollment to CLO Core**: Consent Domain calls External Service Integrations to send the card enrollment update to CLO Core Service
   - From: `continuumCloInventoryService_consentDomain` -> `continuumCloInventoryService_externalIntegrations`
   - To: `continuumCloCoreService`
   - Protocol: HTTP/JSON via Retrofit

8. **Return response**: Enrollment confirmation flows back through the API layer to the caller
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: External caller
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Card not onboarded on any network | Card Interaction Service returns no network identifiers; enrollment rejected | HTTP 422 returned; user informed their card is not eligible for CLO |
| No active consent record | Consent validation fails; enrollment rejected | HTTP 409 returned; user must grant consent before enrolling a card |
| CLO Card Interaction Service unavailable | Enrollment cannot verify network status; request fails | HTTP 502/503 returned; caller must retry |
| PostgreSQL write failure | Transaction rolled back; HTTP 500 returned | No enrollment persisted; caller must retry |
| CLO Core Service unavailable (sync) | Enrollment persisted locally but sync to CLO Core fails | Enrollment exists in database; CLO Core activation may need reconciliation |
| Duplicate enrollment attempt | Existing enrollment detected; idempotent response returned | HTTP 200 with existing enrollment data; no duplicate record created |

## Sequence Diagram

```
Consumer App -> HTTP API - Consent: POST /clo/consent/{userId}/enroll (card details)
HTTP API - Consent -> Consent Domain: enrollCard(userId, cardDetails)
Consent Domain -> External Integrations: getOnboardedNetworkIds(cardId)
External Integrations -> CLO Card Interaction Service: GET /cards/{id}/networks (HTTP/JSON)
CLO Card Interaction Service --> External Integrations: Network identifiers
External Integrations --> Consent Domain: Network identifiers
Consent Domain -> Postgres Data Access: lookupConsent(userId)
Postgres Data Access -> CLO Inventory DB: SELECT consent_records (SQL)
CLO Inventory DB --> Postgres Data Access: Consent record
Consent Domain -> Postgres Data Access: insertEnrollment(enrollment)
Postgres Data Access -> CLO Inventory DB: INSERT card_enrollments (SQL)
Consent Domain -> Postgres Data Access: upsertBillingRecord(billingRecord)
Postgres Data Access -> CLO Inventory DB: INSERT/UPDATE billing_records (SQL)
Consent Domain -> External Integrations: syncEnrollment(enrollmentData)
External Integrations -> CLO Core Service: POST /enrollments (HTTP/JSON)
CLO Core Service --> External Integrations: Enrollment synced
Consent Domain --> HTTP API - Consent: Enrollment result
HTTP API - Consent --> Consumer App: 201 Created (enrollment confirmation)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService`
- Related flows: [Consent Management](consent-management.md), [CLO Offer Claim](clo-offer-claim.md)
- See [Integrations](../integrations.md) for CLO Card Interaction Service and CLO Core Service details
- See [Data Stores](../data-stores.md) for card enrollment and billing record tables
