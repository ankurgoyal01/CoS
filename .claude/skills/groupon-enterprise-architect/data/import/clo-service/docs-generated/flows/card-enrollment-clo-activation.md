---
service: "clo-service"
title: "Card Enrollment and CLO Activation"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "card-enrollment-clo-activation"
flow_type: synchronous
trigger: "API call to POST /clo/api/v2/users/{id}/card_enrollments"
participants:
  - "continuumCloServiceApi"
  - "cloApiControllers"
  - "cloApiClaimDomain"
  - "cloApiPartnerClients"
  - "cloApiEventPublisher"
  - "continuumCloServicePostgres"
  - "continuumCloServiceRedis"
  - "messageBus"
  - "continuumUsersService"
architecture_ref: "components-clo-service-api"
---

# Card Enrollment and CLO Activation

## Summary

This flow describes how a user's payment card is enrolled in a Card-Linked Offer. An API request is received by CLO Service, the user's eligibility is verified, the card token is registered with the appropriate card network (Visa, Mastercard, or Amex), and the enrollment is persisted. A `clo.enrollments` event is published to notify downstream services of the new enrollment state.

## Trigger

- **Type**: api-call
- **Source**: Internal Continuum service or consumer-facing application calling `POST /clo/api/v2/users/{id}/card_enrollments`
- **Frequency**: On demand (per user card enrollment action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CLO Service API | Receives and processes enrollment request | `continuumCloServiceApi` |
| API Controllers | Routes and validates inbound enrollment request | `cloApiControllers` |
| Claim Domain Services | Orchestrates enrollment business logic and state transitions | `cloApiClaimDomain` |
| Partner Client Adapters | Calls card network API to register card token | `cloApiPartnerClients` |
| Event Publisher | Publishes enrollment event to Message Bus | `cloApiEventPublisher` |
| CLO Service PostgreSQL | Persists enrollment record | `continuumCloServicePostgres` |
| CLO Service Redis | Caches enrollment state; used for idempotency locking | `continuumCloServiceRedis` |
| Message Bus | Receives published enrollment event | `messageBus` |
| Users Service | Provides user account state and eligibility data | `continuumUsersService` |

## Steps

1. **Receives enrollment request**: `cloApiControllers` receives `POST /clo/api/v2/users/{id}/card_enrollments` with card token and offer id.
   - From: `caller`
   - To: `cloApiControllers`
   - Protocol: REST

2. **Validates user eligibility**: `cloApiClaimDomain` calls Users Service to confirm the account is active and eligible for CLO enrollment.
   - From: `cloApiClaimDomain`
   - To: `continuumUsersService`
   - Protocol: REST

3. **Checks for duplicate enrollment**: `cloApiClaimDomain` queries `continuumCloServicePostgres` to ensure the card/offer combination is not already enrolled. Acquires a Redis lock to prevent race conditions.
   - From: `cloApiClaimDomain`
   - To: `continuumCloServicePostgres`, `continuumCloServiceRedis`
   - Protocol: ActiveRecord / SQL, Redis

4. **Registers card with card network**: `cloApiPartnerClients` calls the appropriate network API (Visa, Mastercard, or Amex) to register the card token against the offer.
   - From: `cloApiPartnerClients`
   - To: External card network API
   - Protocol: REST (Faraday) or SOAP (Savon for Amex)

5. **Persists enrollment record**: `cloApiClaimDomain` writes the enrollment record to `continuumCloServicePostgres` with status `enrolled`, using AASM state machine transitions.
   - From: `cloApiClaimDomain`
   - To: `continuumCloServicePostgres`
   - Protocol: ActiveRecord / SQL

6. **Publishes enrollment event**: `cloApiEventPublisher` publishes a `clo.enrollments` event to Message Bus with enrollment details.
   - From: `cloApiEventPublisher`
   - To: `messageBus`
   - Protocol: Message Bus

7. **Returns enrollment response**: `cloApiControllers` returns the created enrollment record to the caller.
   - From: `cloApiControllers`
   - To: caller
   - Protocol: REST (HTTP 201 Created)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User account inactive or ineligible | Return 422 Unprocessable Entity | Enrollment rejected; no network call made |
| Card already enrolled in offer | Idempotent check in database; Redis lock | Return existing enrollment or 409 Conflict |
| Card network API error | Faraday error handling; no enrollment persisted | Return 502 Bad Gateway; caller should retry |
| Database write failure | Transaction rollback | No partial state; return 500; caller should retry |
| Message Bus publish failure | Enrollment persisted but event not delivered | Async retry or worker reconciliation expected |

## Sequence Diagram

```
Caller -> cloApiControllers: POST /clo/api/v2/users/{id}/card_enrollments
cloApiControllers -> cloApiClaimDomain: invoke enrollment workflow
cloApiClaimDomain -> continuumUsersService: GET user account state
continuumUsersService --> cloApiClaimDomain: user eligible
cloApiClaimDomain -> continuumCloServicePostgres: check existing enrollment
cloApiClaimDomain -> continuumCloServiceRedis: acquire idempotency lock
cloApiPartnerClients -> CardNetworkAPI: register card token for offer
CardNetworkAPI --> cloApiPartnerClients: enrollment confirmed
cloApiClaimDomain -> continuumCloServicePostgres: persist enrollment record
cloApiEventPublisher -> messageBus: publish clo.enrollments event
cloApiControllers --> Caller: 201 Created (enrollment record)
```

## Related

- Architecture dynamic view: `components-clo-service-api`
- Related flows: [Claim Processing and Statement Credit](claim-processing-statement-credit.md), [User Account Lifecycle](user-account-lifecycle.md)
