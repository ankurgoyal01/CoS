---
service: "mx-merchant-access"
title: "Set Primary Contact"
generated: "2026-03-03"
type: flow
flow_name: "set-primary-contact"
flow_type: synchronous
trigger: "PUT /v1/merchant/{merchant_identifier}/primary_contact API call"
participants:
  - "accessSvc_apiControllers"
  - "accessSvc_domainServices"
  - "accessSvc_persistence"
  - "continuumAccessPostgres"
architecture_ref: "components-continuumAccessService"
---

# Set Primary Contact

## Summary

This flow designates one of a merchant's active contacts as the primary contact. The primary contact holds a special designation within MAS that is used by other MX platform services as the main point of contact for the merchant. A prerequisite is that the nominated user must already be an active merchant contact before they can be set as primary.

## Trigger

- **Type**: api-call
- **Source**: Internal MX platform service authenticated with `X_API_KEY`
- **Frequency**: On-demand (during merchant onboarding or contact management workflows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calling service | Initiates the primary contact assignment | External caller |
| API Controllers | Receives and validates the PUT request | `accessSvc_apiControllers` |
| Domain Services | Validates that the target user is an active contact; deactivates previous primary contact record; creates new primary contact record | `accessSvc_domainServices` |
| Persistence Layer | Reads and writes `primary_contact` and `audit` records | `accessSvc_persistence` |
| PostgreSQL | Stores updated primary contact and audit data | `continuumAccessPostgres` |

## Steps

1. **Receive request**: Caller sends `PUT /v1/merchant/{merchant_identifier}/primary_contact` with `X_API_KEY` header, `audit_user_id` and `audit_user_type` query params, and a JSON body containing the `account_uuid` (identity UUID) of the new primary contact.
   - From: `calling service`
   - To: `accessSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Validate and dispatch**: API controller validates the `merchant_identifier` UUID and delegates to the primary contact domain service.
   - From: `accessSvc_apiControllers`
   - To: `accessSvc_domainServices`
   - Protocol: Direct (Spring bean)

3. **Validate candidate is an active contact**: Domain service verifies that the specified account UUID is an active `merchant_contact` for the given merchant. If not found, the request is rejected.
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

4. **Deactivate existing primary contact**: If a `primary_contact` record already exists for this merchant with `active = true`, domain service sets it to `active = false`.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

5. **Insert new primary contact**: Domain service inserts a new `primary_contact` row with `identity_uuid`, `merchant_uuid`, and `active = true`.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

6. **Write audit record**: An `audit` row is inserted with the old and new `primary_contact` entity IDs.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

7. **Return response**: On success, the API returns an empty HTTP 200 body.
   - From: `accessSvc_apiControllers`
   - To: `calling service`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Nominated account is not an active contact for the merchant | Business validation | HTTP 4xx client error |
| Invalid merchant UUID format | Spring MVC binding | HTTP 400 Bad Request |
| Database write failure | Transaction rollback | HTTP 500 Internal Server Error |

## Sequence Diagram

```
CallingService -> accessSvc_apiControllers: PUT /v1/merchant/{merchant_uuid}/primary_contact (body: account_uuid)
accessSvc_apiControllers -> accessSvc_domainServices: setPrimaryContact(merchantUuid, identityUuid, auditData)
accessSvc_domainServices -> accessSvc_persistence: findActiveContact(merchantUuid, identityUuid)
accessSvc_persistence -> continuumAccessPostgres: SELECT merchant_contact WHERE merchant_uuid AND account_uuid AND active=true
continuumAccessPostgres --> accessSvc_persistence: contact entity
accessSvc_domainServices -> accessSvc_persistence: deactivatePreviousPrimary(merchantUuid)
accessSvc_persistence -> continuumAccessPostgres: UPDATE primary_contact SET active=false WHERE merchant_uuid AND active=true
accessSvc_domainServices -> accessSvc_persistence: insertPrimaryContact(merchantUuid, identityUuid, auditData)
accessSvc_persistence -> continuumAccessPostgres: INSERT primary_contact (active=true); INSERT audit
continuumAccessPostgres --> accessSvc_persistence: success
accessSvc_domainServices --> accessSvc_apiControllers: success
accessSvc_apiControllers --> CallingService: HTTP 200 (empty body)
```

## Related

- Architecture dynamic view: `components-continuumAccessService`
- Related flows: [Create Merchant Contact](create-merchant-contact.md), [Delete Merchant Contact](delete-merchant-contact.md), [Account Lifecycle Cleanup](account-lifecycle-cleanup.md)
