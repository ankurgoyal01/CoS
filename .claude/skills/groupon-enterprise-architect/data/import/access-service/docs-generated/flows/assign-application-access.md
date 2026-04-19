---
service: "mx-merchant-access"
title: "Assign Application Access"
generated: "2026-03-03"
type: flow
flow_name: "assign-application-access"
flow_type: synchronous
trigger: "POST /v1/contact/{account_uuid}/{merchant_uuid}/application/{application_name}/access API call"
participants:
  - "accessSvc_apiControllers"
  - "accessSvc_domainServices"
  - "accessSvc_persistence"
  - "continuumAccessPostgres"
architecture_ref: "components-continuumAccessService"
---

# Assign Application Access

## Summary

This flow assigns or updates the role of an existing merchant contact within the context of a specific application. If the contact already has a role for the given application, the role is updated; otherwise a new access entry is created. The operation enables fine-grained, per-application access control within MAS.

## Trigger

- **Type**: api-call
- **Source**: Internal MX platform service authenticated with `X_API_KEY`
- **Frequency**: On-demand (per access-change action in merchant management workflows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Calling service | Initiates the access assignment request | External caller |
| API Controllers | Receives and validates the HTTP request; extracts path, query, and body parameters | `accessSvc_apiControllers` |
| Domain Services | Resolves the contact, looks up or creates the role binding, and applies the upsert | `accessSvc_domainServices` |
| Persistence Layer | Writes or updates `merchant_access` records and inserts an `audit` row | `accessSvc_persistence` |
| PostgreSQL | Stores all access and audit records | `continuumAccessPostgres` |

## Steps

1. **Receive request**: Caller sends `POST /v1/contact/{account_uuid}/{merchant_uuid}/application/{application_name}/access` with `X_API_KEY` header, `audit_user_id`, `audit_user_type` query params, and a JSON body specifying the desired role.
   - From: `calling service`
   - To: `accessSvc_apiControllers`
   - Protocol: REST/HTTP

2. **Validate and dispatch**: API controller validates path parameters (UUID format), required query params, and body; delegates to the access domain service.
   - From: `accessSvc_apiControllers`
   - To: `accessSvc_domainServices`
   - Protocol: Direct (Spring bean)

3. **Resolve contact**: Domain service looks up the existing `merchant_contact` by `account_uuid` and `merchant_uuid`.
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

4. **Resolve role**: Domain service looks up the requested role by `application_name` and role name to obtain the `role_id`.
   - From: `accessSvc_domainServices`
   - To: `accessSvc_persistence`
   - Protocol: Direct (Spring bean)

5. **Upsert merchant_access**: Persistence layer creates a new `merchant_access` record linking `contact_id` to `role_id`, or deactivates the previous entry and inserts a new one if a role already exists for this application context.
   - From: `accessSvc_persistence`
   - To: `continuumAccessPostgres`
   - Protocol: JPA/JDBC

6. **Write audit record**: An `audit` row is inserted recording the old and new `merchant_access` IDs.
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
| Contact not found for account/merchant pair | Business validation in domain service | HTTP 4xx client error |
| Application or role name not recognized | Lookup failure in persistence | HTTP 4xx client error |
| Invalid UUID format in path | Spring MVC binding | HTTP 400 Bad Request |
| Database write failure | Transaction rollback | HTTP 500 Internal Server Error |

## Sequence Diagram

```
CallingService -> accessSvc_apiControllers: POST /v1/contact/{account_uuid}/{merchant_uuid}/application/{app}/access
accessSvc_apiControllers -> accessSvc_domainServices: assignAccess(accountUuid, merchantUuid, applicationName, roleBody, auditData)
accessSvc_domainServices -> accessSvc_persistence: findContact(accountUuid, merchantUuid)
accessSvc_persistence -> continuumAccessPostgres: SELECT merchant_contact
continuumAccessPostgres --> accessSvc_persistence: contact entity
accessSvc_domainServices -> accessSvc_persistence: findRole(applicationName, roleName)
accessSvc_persistence -> continuumAccessPostgres: SELECT role JOIN application
continuumAccessPostgres --> accessSvc_persistence: role entity
accessSvc_domainServices -> accessSvc_persistence: upsertAccess(contactId, roleId, auditData)
accessSvc_persistence -> continuumAccessPostgres: INSERT/UPDATE merchant_access, INSERT audit
continuumAccessPostgres --> accessSvc_persistence: success
accessSvc_domainServices --> accessSvc_apiControllers: success
accessSvc_apiControllers --> CallingService: HTTP 200 (empty body)
```

## Related

- Architecture dynamic view: `components-continuumAccessService`
- Related flows: [Create Merchant Contact](create-merchant-contact.md), [Query Contact Access](query-contact-access.md)
