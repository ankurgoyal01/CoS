---
service: "third-party-mailmonger"
title: "Masked Email Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "masked-email-provisioning"
flow_type: synchronous
trigger: "API call from TPIS (Third-Party Inventory Service) during deal reservation"
participants:
  - "TPIS (Spaceman)"
  - "continuumThirdPartyMailmongerService"
  - "continuumUsersService"
  - "daasPostgres"
architecture_ref: "dynamic-third-party-mailmonger"
---

# Masked Email Provisioning

## Summary

When a consumer reserves a deal with a third-party partner, the Third-Party Inventory Service (TPIS/Spaceman) calls Mailmonger to obtain a masked email address that is unique to the consumer/partner pair. Mailmonger either retrieves an existing masked address from PostgreSQL or generates a new one, stores the consumer-to-partner mapping, and returns the masked email. TPIS then provides this masked email to the partner in the reservation payload, preventing the partner from ever seeing the consumer's real email address.

## Trigger

- **Type**: api-call
- **Source**: TPIS / Spaceman calls `GET /v1/masked/consumer/{consumerId}/{partnerId}` during deal checkout reservation
- **Frequency**: On-demand (once per unique consumer/partner pair during reservation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| TPIS / Spaceman | Initiator — calls Mailmonger API during deal reservation | External to this service |
| Third Party Mailmonger | Orchestrator — provisions or retrieves masked email address | `continuumThirdPartyMailmongerService` |
| users-service | Provides consumer and partner metadata validation | `continuumUsersService` |
| PostgreSQL (DaaS) | Stores masked email mappings and consumer-partner relationships | `daasPostgres` |

## Steps

1. **Receives masked email request**: TPIS sends `GET /v1/masked/consumer/{consumerId}/{partnerId}` with optional `transactionId` and `customEmail` query parameters.
   - From: `TPIS`
   - To: `continuumThirdPartyMailmongerService` (`thirdPartyMailmonger_apiResources`)
   - Protocol: REST / HTTP

2. **Queries existing mapping**: API Resource delegates to Email Services, which queries `MaskedEmailDAO` and `ConsumerPartnerEmailDAO` to check if a masked email already exists for this consumer/partner pair.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

3. **Fetches partner/consumer metadata (if needed)**: If no existing mapping is found, users-service is called to validate consumer and partner identities and retrieve real email addresses needed for mask generation.
   - From: `thirdPartyMailmonger_userServiceClient`
   - To: `continuumUsersService` (`GET /users/v1/accounts`)
   - Protocol: HTTP (Retrofit)

4. **Generates masked email address**: A new unique masked email address is created for the consumer/partner pair. The mapping is stored in `masked_emails` and `consumer_partner_emails` tables.
   - From: `emailServices`
   - To: `emailDaos` → `daasPostgres`
   - Protocol: JDBC

5. **Returns masked email**: The masked email address and its UUID are returned as a `MaskedEmail` object to TPIS.
   - From: `continuumThirdPartyMailmongerService`
   - To: `TPIS`
   - Protocol: REST / HTTP (JSON)

6. **TPIS uses masked email in reservation**: TPIS passes the masked email address to the partner in the reservation request (`create reservation(maskedEmail, unitDetails)`). The partner stores this address for future email communications.
   - From: `TPIS`
   - To: Partner system
   - Protocol: Partner API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| consumerId or partnerId not found | Returns HTTP 400 with `MaskedEmail` error response | TPIS receives error; checkout may fail |
| transactionId not found (if provided) | Returns HTTP 404 with `MaskedEmail` error response | TPIS receives error |
| users-service unavailable | Retrofit timeout/retry per client config | HTTP 5xx returned to TPIS; checkout impact |
| PostgreSQL write failure | Exception propagates; HTTP 5xx returned | No mapping stored; TPIS receives error |

## Sequence Diagram

```
User       -> GAPI        : Create Order
GAPI       -> TPIS        : reserve
TPIS       -> 3PM         : GET /v1/masked/consumer/{consumerId}/{partnerId}
3PM        -> PostgreSQL   : Query existing masked email mapping
PostgreSQL --> 3PM         : (none found)
3PM        -> UsersService : GET /users/v1/accounts (validate consumer/partner)
UsersService --> 3PM       : consumer and partner metadata
3PM        -> PostgreSQL   : INSERT masked_emails + consumer_partner_emails
PostgreSQL --> 3PM         : stored
3PM        --> TPIS        : { id, email: "masked@domain" }
TPIS       -> Partner      : create reservation(maskedEmail, unitDetails)
TPIS       --> GAPI        : reservation confirmed
GAPI       --> User        : order created
```

## Related

- Architecture dynamic view: `dynamic-third-party-mailmonger`
- Related flows: [Inbound Email Relay — Partner to Consumer](inbound-email-partner-to-consumer.md)
- SLA: TP99 100ms, 10 rps, 99.6% uptime (from `sla.yml`)
