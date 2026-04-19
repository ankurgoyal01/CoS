---
service: "mx-merchant-access"
title: "Create Merchant Contact"
generated: "2026-03-03"
type: flow
flow_name: "create-merchant-contact"
flow_type: synchronous
trigger: "POST /v1/contact API call"
participants:
  - "accessSvc_apiControllers"
  - "accessSvc_domainServices"
  - "accessSvc_persistence"
  - "continuumAccessPostgres"
architecture_ref: "components-continuumAccessService"
---

# Create Merchant Contact

## Summary

This flow establishes a new user-to-merchant relationship (merchant contact) in MAS. The caller provides account and merchant UUIDs along with role information; MAS persists the binding, writes an audit record, and returns an empty 200 response. The operation is the entry point for granting a user any access to a merchant.

## Trigger

- **Type**: api-call
- **Source**: Internal MX platform service (e.g., merchant portal backend) authenticated with `X_API_KEY`
- **Frequency**: On-demand (per user-onboarding or access grant action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calling service | Initiates the contact creation request | External caller |
| API Controllers | Receives and validates the HTTP request, extracts audit parameters | `accessSvc_apiControllers` |
| Domain Services | Executes business logic: validates that the contact does not already exist, constructs the contact and access entities | `accessSvc_domainServices` |
| Persistence Layer | Writes `merchant_contact`, `merchant_access`, and `audit` records | `accessSvc_persistence` |
| PostgreSQL | Stores all written entities durably | `continuumAccessPostgres` |

## Steps

1. **Receive request**: Caller sends `POST /v1/contact` with `X_API_KEY` header, `audit_user_id` and `audit_user_type` query params, and a JSON body containing `account_uuid`, `merchant_uuid`, and role/application details.
   - From: `calling service`
   - To: `accessSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Validate and dispatch**: API controller validates required fields and delegates to the domain contact service.
   - From: `accessSvc_apiControllers`
   - To: `accessSvc_domainServices`
   - Protocol: Direct (Spring bean)

3. **Business logic**: Domain service checks for duplicate contacts, constructs a `merchant_contact` entity (with a generated `contact_uuid`) and a `merchant_access` entity linking the contact to the requested role.
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

4. **Persist contact and access**: Persistence layer writes the `merchant_contact` row and the associated `merchant_access` row to the database in a single transaction.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

5. **Write audit record**: Within the same transaction, an `audit` record is inserted with the `user_type`, `user_id`, `entity_type`, and the new entity ID.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

6. **Return response**: On success, the API returns an empty HTTP 200 body.
   - From: `accessSvc_apiControllers`
   - To: `calling service`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Contact already exists | Business validation in domain service | HTTP 4xx client error returned (specific code documented in service wiki) |
| Invalid UUID format | Spring MVC validation | HTTP 400 Bad Request |
| Database write failure | Transaction rollback | HTTP 500 Internal Server Error |
| Missing required fields | Validated by API controller | HTTP 400 Bad Request |

## Sequence Diagram

```
CallingService -> accessSvc_apiControllers: POST /v1/contact (X_API_KEY, audit params, body)
accessSvc_apiControllers -> accessSvc_domainServices: createContact(accountUuid, merchantUuid, roleInfo, auditData)
accessSvc_domainServices -> accessSvc_persistence: checkDuplicate(accountUuid, merchantUuid)
accessSvc_persistence -> continuumAccessPostgres: SELECT merchant_contact WHERE account_uuid AND merchant_uuid
continuumAccessPostgres --> accessSvc_persistence: empty result (no duplicate)
accessSvc_domainServices -> accessSvc_persistence: saveContact(merchantContact, merchantAccess, audit)
accessSvc_persistence -> continuumAccessPostgres: INSERT merchant_contact, merchant_access, audit
continuumAccessPostgres --> accessSvc_persistence: success
accessSvc_persistence --> accessSvc_domainServices: saved entities
accessSvc_domainServices --> accessSvc_apiControllers: success
accessSvc_apiControllers --> CallingService: HTTP 200 (empty body)
```

## Related

- Architecture dynamic view: `components-continuumAccessService`
- Related flows: [Assign Application Access](assign-application-access.md), [Delete Merchant Contact](delete-merchant-contact.md)
