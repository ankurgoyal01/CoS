---
service: "clo-inventory-service"
title: "Consent Management"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "consent-management"
flow_type: synchronous
trigger: "HTTP POST or DELETE request to create, update, or revoke consent"
participants:
  - "continuumCloInventoryService_httpApiConsent"
  - "continuumCloInventoryService_consentDomain"
  - "continuumCloInventoryService_dataAccessPostgres"
  - "continuumCloInventoryDb"
architecture_ref: "components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService"
---

# Consent Management

## Summary

The Consent Management flow handles the full lifecycle of user consent for card-linked offers: granting, updating, and revoking consent. When a consent action arrives via the Consent API, the service persists the consent record to PostgreSQL and writes a consent history entry for audit purposes. Consent is a prerequisite for card enrollment -- a user must have active consent before their cards can be enrolled for CLO. Consent revocation triggers downstream cleanup, including potential card unenrollment.

## Trigger

- **Type**: api-call
- **Source**: HTTP POST to `/clo/consent` (grant/update) or HTTP DELETE to `/clo/consent/{userId}` (revoke) via `ConsentResource`; HTTP GET to `/clo/consent/{userId}/history` via `ConsentHistoryResource`
- **Frequency**: On-demand, triggered by consumer applications when a user opts in or out of CLO participation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API - Consent | Receives consent management HTTP requests (grant, update, revoke, query history) | `continuumCloInventoryService_httpApiConsent` |
| Consent Domain & Services | Processes consent logic: validation, persistence, history tracking, and downstream effects | `continuumCloInventoryService_consentDomain` |
| Postgres Data Access | Executes SQL operations for consent records and consent history | `continuumCloInventoryService_dataAccessPostgres` |
| CLO Inventory Database | Stores consent records and consent history | `continuumCloInventoryDb` |

## Steps

### Grant Consent

1. **Receive consent grant request**: HTTP API - Consent (`ConsentResource`) receives a POST request with user consent details
   - From: External caller (consumer application)
   - To: `continuumCloInventoryService_httpApiConsent`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Consent Domain**: The API resource invokes `ConsentApi` within the Consent Domain & Services component
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: `continuumCloInventoryService_consentDomain`
   - Protocol: In-process call

3. **Validate consent request**: Consent Domain validates the request (user ID, consent type, required fields)
   - From: `continuumCloInventoryService_consentDomain`
   - To: Internal validation logic
   - Protocol: In-process

4. **Persist consent record**: Consent Domain writes the consent record to PostgreSQL via Postgres Data Access
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

5. **Write consent history**: Consent Domain creates a history entry recording the consent grant action with timestamp
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

6. **Return response**: Consent grant confirmation flows back to the caller
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: External caller
   - Protocol: REST (HTTP/JSON)

### Revoke Consent

1. **Receive consent revocation request**: HTTP API - Consent receives a DELETE request for the user's consent
   - From: External caller (consumer application)
   - To: `continuumCloInventoryService_httpApiConsent`
   - Protocol: REST (HTTP/JSON)

2. **Delegate to Consent Domain**: The API resource invokes `ConsentApi` for the revocation operation
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: `continuumCloInventoryService_consentDomain`
   - Protocol: In-process call

3. **Revoke consent record**: Consent Domain updates the consent status to revoked in PostgreSQL
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

4. **Write consent history**: Consent Domain creates a history entry recording the revocation action
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

5. **Trigger downstream cleanup**: If cards are enrolled, the Consent Domain may initiate card unenrollment via External Service Integrations to CLO Core Service
   - From: `continuumCloInventoryService_consentDomain` -> `continuumCloInventoryService_externalIntegrations`
   - To: `continuumCloCoreService`
   - Protocol: HTTP/JSON via Retrofit

6. **Return response**: Revocation confirmation flows back to the caller
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: External caller
   - Protocol: REST (HTTP/JSON)

### Query Consent History

1. **Receive history request**: HTTP API - Consent (`ConsentHistoryResource`) receives a GET request for the user's consent history
   - From: External caller
   - To: `continuumCloInventoryService_httpApiConsent`
   - Protocol: REST (HTTP/JSON)

2. **Query history records**: Consent Domain queries consent history entries from PostgreSQL, ordered by timestamp
   - From: `continuumCloInventoryService_consentDomain`
   - To: `continuumCloInventoryService_dataAccessPostgres` -> `continuumCloInventoryDb`
   - Protocol: JDBI over JDBC / PostgreSQL

3. **Return history**: History records returned to the caller
   - From: `continuumCloInventoryService_httpApiConsent`
   - To: External caller
   - Protocol: REST (HTTP/JSON)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Consent already granted | Idempotent upsert; existing consent updated | HTTP 200 with current consent state; no duplicate |
| Consent not found for revocation | HTTP 404 returned | User informed no active consent exists |
| PostgreSQL write failure | Transaction rolled back; HTTP 500 returned | No consent state changed; caller must retry |
| Invalid consent request | Validation error; HTTP 400 returned | Caller informed of missing or invalid fields |
| Card unenrollment fails on revocation | Consent revoked locally; card unenrollment may be retried | Consent is revoked; card enrollment state may need reconciliation with CLO Core |

## Sequence Diagram

### Grant Consent

```
Consumer App -> HTTP API - Consent: POST /clo/consent (userId, consent details)
HTTP API - Consent -> Consent Domain: grantConsent(userId, consentData)
Consent Domain -> Postgres Data Access: upsertConsent(consentRecord)
Postgres Data Access -> CLO Inventory DB: INSERT/UPDATE consent_records (SQL)
CLO Inventory DB --> Postgres Data Access: Confirmation
Consent Domain -> Postgres Data Access: insertHistory(historyRecord)
Postgres Data Access -> CLO Inventory DB: INSERT consent_history (SQL)
Consent Domain --> HTTP API - Consent: Consent granted
HTTP API - Consent --> Consumer App: 200 OK (consent record)
```

### Revoke Consent

```
Consumer App -> HTTP API - Consent: DELETE /clo/consent/{userId}
HTTP API - Consent -> Consent Domain: revokeConsent(userId)
Consent Domain -> Postgres Data Access: updateConsentStatus(userId, REVOKED)
Postgres Data Access -> CLO Inventory DB: UPDATE consent_records (SQL)
Consent Domain -> Postgres Data Access: insertHistory(revocationRecord)
Postgres Data Access -> CLO Inventory DB: INSERT consent_history (SQL)
Consent Domain -> External Integrations: unenrollCards(userId)
External Integrations -> CLO Core Service: DELETE /enrollments/{userId} (HTTP/JSON)
CLO Core Service --> External Integrations: Enrollment removed
Consent Domain --> HTTP API - Consent: Consent revoked
HTTP API - Consent --> Consumer App: 200 OK (revocation confirmation)
```

## Related

- Architecture dynamic view: not yet defined -- see `components-continuum-clo-continuumCloInventoryService_httpApiInventory-continuumCloInventoryService_coreProductService`
- Related flows: [Card Enrollment](card-enrollment.md) (depends on active consent), [CLO Offer Claim](clo-offer-claim.md) (requires consent and enrollment)
- See [Data Stores](../data-stores.md) for consent records and consent history tables
- See [API Surface](../api-surface.md) for consent REST endpoints
