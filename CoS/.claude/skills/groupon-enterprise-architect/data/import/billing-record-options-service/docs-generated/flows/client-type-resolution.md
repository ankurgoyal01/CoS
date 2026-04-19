---
service: "billing-record-options-service"
title: "Client Type Resolution"
generated: "2026-03-03"
type: flow
flow_name: "client-type-resolution"
flow_type: synchronous
trigger: "Embedded sub-flow invoked during every payment methods request"
participants:
  - "brosPaymentMethodsService"
  - "brosClientTypeService"
  - "brosJdbiDataAccessor"
  - "daasPostgresPrimary"
architecture_ref: "components-continuumBillingRecordOptionsService"
---

# Client Type Resolution

## Summary

Client type resolution is an embedded sub-flow that runs as part of every payment methods query. Its purpose is to determine which "client type" (e.g., `touch` for mobile, `desktop` for web) the requesting caller represents, so that BROS can apply the correct provider importance rankings. The resolution is driven by matching the `userAgent` query parameter (or `X-REMOTE-USER-AGENT` / `X-CLIENT-ROLES` headers) against regex patterns stored in the `client_types` database table. The resolved client type is then used by the Payment Provider Service to retrieve importance scores.

## Trigger

- **Type**: api-call (embedded sub-flow)
- **Source**: Payment Methods Service, called during `GET /paymentmethods` and `GET /paymentmethods/{countryCode}` processing
- **Frequency**: Once per incoming request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Payment Methods Service | Invokes client type resolution with user-agent string or role header | `brosPaymentMethodsService` |
| Client Type Service | Matches user-agent or role against stored patterns to resolve client type | `brosClientTypeService` |
| JDBI Data Accessor | Queries the `client_types` and `applications_client_types` tables | `brosJdbiDataAccessor` |
| DaaS PostgreSQL | Stores client type definitions and their regex patterns | `daasPostgresPrimary` |

## Steps

1. **Extract User-Agent / Role**: Payment Methods Service extracts the `userAgent` query parameter from the incoming request. If the caller has set `X-CLIENT-ROLES: touch`, the constant `CLIENT_ROLE_TOUCH = "touch"` is matched directly.
   - From: `brosPaymentMethodsService`
   - To: `brosClientTypeService`
   - Protocol: Direct (in-process)

2. **Load Client Type Definitions**: Client Type Service retrieves all rows from the `client_types` table, ordered by `rank`. Each row contains a `type` identifier and a `user_agent_regex` pattern.
   - From: `brosClientTypeService`
   - To: `brosJdbiDataAccessor`
   - Protocol: Direct

3. **Query Database**: JDBI Data Accessor executes `SELECT type, user_agent_regex, rank FROM client_types ORDER BY rank`.
   - From: `brosJdbiDataAccessor`
   - To: `daasPostgresPrimary`
   - Protocol: PostgreSQL

4. **Match User-Agent Against Patterns**: Client Type Service iterates through the ranked client type definitions and tests the provided user-agent string against each `user_agent_regex`. The first match (by rank) determines the client type.
   - From: `brosClientTypeService`
   - To: internal logic (in-process)
   - Protocol: Direct

5. **Return Resolved Client Type**: Client Type Service returns the matched client type string (e.g., `"touch"` for the constant `USER_AGENT_MOBILE = "Touch"`, or default desktop type) to Payment Methods Service.
   - From: `brosClientTypeService`
   - To: `brosPaymentMethodsService`
   - Protocol: Direct

6. **Apply Importance Rankings**: Payment Methods Service passes the resolved client type to Payment Provider Service to look up `payment_provider_importance` records for that client type, enabling ranked ordering of payment providers in the response.
   - From: `brosPaymentMethodsService`
   - To: `brosPaymentProviderService`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No user-agent provided | No regex match; default client type applied | Providers returned without importance-based ranking or with a default ranking |
| No client type patterns match | Falls through all patterns without match | Default client type returned; providers ranked by base importance |
| Database unavailable | JDBI exception propagates | Request fails with `500 Internal Server Error` |

## Sequence Diagram

```
brosPaymentMethodsService -> brosClientTypeService: resolveClientType(userAgent="Mozilla/5.0 (iPhone...)")
brosClientTypeService -> brosJdbiDataAccessor: findAllClientTypes()
brosJdbiDataAccessor -> daasPostgresPrimary: SELECT type, user_agent_regex, rank FROM client_types ORDER BY rank
daasPostgresPrimary --> brosJdbiDataAccessor: [{type: "touch", regex: "Touch", rank: 1}, ...]
brosJdbiDataAccessor --> brosClientTypeService: clientTypeDefinitions
brosClientTypeService -> brosClientTypeService: match("Touch" in userAgent) -> "touch"
brosClientTypeService --> brosPaymentMethodsService: clientType = "touch"
brosPaymentMethodsService -> brosPaymentProviderService: getProviders(countryCode, clientType="touch", filters)
```

## Related

- Architecture dynamic view: `components-continuumBillingRecordOptionsService`
- Related flows: [Payment Methods by Country Query](payment-methods-by-country.md), [Payment Methods by Provider Query](payment-methods-by-provider.md)
