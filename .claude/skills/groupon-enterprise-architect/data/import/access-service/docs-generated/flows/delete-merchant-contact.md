---
service: "mx-merchant-access"
title: "Delete Merchant Contact"
generated: "2026-03-03"
type: flow
flow_name: "delete-merchant-contact"
flow_type: synchronous
trigger: "DELETE /v1/contact/{account_uuid}/{merchant_uuid} API call"
participants:
  - "accessSvc_apiControllers"
  - "accessSvc_domainServices"
  - "accessSvc_persistence"
  - "continuumAccessPostgres"
architecture_ref: "components-continuumAccessService"
---

# Delete Merchant Contact

## Summary

This flow removes a user-to-merchant binding from MAS, revoking all of the user's rights to the merchant. The operation is guarded by a business rule that prevents deletion of a contact who is also the designated primary contact for the merchant — that primary contact designation must first be reassigned to another contact before deletion can proceed.

## Trigger

- **Type**: api-call
- **Source**: Internal MX platform service authenticated with `X_API_KEY`
- **Frequency**: On-demand (per access revocation action)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calling service | Initiates the deletion request | External caller |
| API Controllers | Receives and validates the HTTP DELETE request | `accessSvc_apiControllers` |
| Domain Services | Enforces primary contact guard, deactivates contact and all associated access records | `accessSvc_domainServices` |
| Persistence Layer | Soft-deletes `merchant_contact` and `merchant_access` rows; writes audit record | `accessSvc_persistence` |
| PostgreSQL | Stores all updated records | `continuumAccessPostgres` |

## Steps

1. **Receive request**: Caller sends `DELETE /v1/contact/{account_uuid}/{merchant_uuid}` with `X_API_KEY` header and `audit_user_id`, `audit_user_type` query parameters.
   - From: `calling service`
   - To: `accessSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Validate and dispatch**: API controller validates UUID path parameters and required audit query params; delegates to the contact domain service.
   - From: `accessSvc_apiControllers`
   - To: `accessSvc_domainServices`
   - Protocol: Direct (Spring bean)

3. **Check primary contact guard**: Domain service fetches the primary contact for the merchant and checks whether the contact to be deleted is that primary contact. If yes, the operation is rejected.
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

4. **Deactivate access records**: Domain service sets `active = false` on all `merchant_access` rows linked to this contact.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

5. **Deactivate contact record**: Domain service sets `active = false` on the `merchant_contact` row for the given `account_uuid` / `merchant_uuid` pair.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

6. **Write audit record**: An `audit` row is written recording the deletion action with the old contact entity ID.
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
| Contact is the primary contact for the merchant | Business rule check in domain service | HTTP 4xx client error (deletion rejected) |
| Contact not found | Lookup failure | HTTP 4xx client error |
| Invalid UUID format | Spring MVC binding | HTTP 400 Bad Request |
| Database write failure | Transaction rollback | HTTP 500 Internal Server Error |

## Sequence Diagram

```
CallingService -> accessSvc_apiControllers: DELETE /v1/contact/{account_uuid}/{merchant_uuid}
accessSvc_apiControllers -> accessSvc_domainServices: deleteContact(accountUuid, merchantUuid, auditData)
accessSvc_domainServices -> accessSvc_persistence: getPrimaryContact(merchantUuid)
accessSvc_persistence -> continuumAccessPostgres: SELECT primary_contact WHERE merchant_uuid AND active=true
continuumAccessPostgres --> accessSvc_persistence: primaryContact (or null)
accessSvc_domainServices -> accessSvc_domainServices: guard: is contact the primary contact?
accessSvc_domainServices -> accessSvc_persistence: deactivateAccess(contactId)
accessSvc_persistence -> continuumAccessPostgres: UPDATE merchant_access SET active=false WHERE contact_id
accessSvc_domainServices -> accessSvc_persistence: deactivateContact(accountUuid, merchantUuid, auditData)
accessSvc_persistence -> continuumAccessPostgres: UPDATE merchant_contact SET active=false; INSERT audit
continuumAccessPostgres --> accessSvc_persistence: success
accessSvc_domainServices --> accessSvc_apiControllers: success
accessSvc_apiControllers --> CallingService: HTTP 200 (empty body)
```

## Related

- Architecture dynamic view: `components-continuumAccessService`
- Related flows: [Create Merchant Contact](create-merchant-contact.md), [Account Lifecycle Cleanup](account-lifecycle-cleanup.md)
