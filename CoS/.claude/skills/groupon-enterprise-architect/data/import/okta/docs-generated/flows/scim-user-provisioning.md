---
service: "okta"
title: "SCIM User Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "scim-user-provisioning"
flow_type: synchronous
trigger: "Okta triggers a SCIM provisioning event for user lifecycle management"
participants:
  - "continuumOktaService"
  - "provisioningSync"
  - "ssoBroker"
  - "directoryAdapter"
  - "oktaIdp"
  - "continuumUsersService"
  - "continuumOktaConfigStore"
architecture_ref: "dynamic-okta-sso-provisioning-flow"
---

# SCIM User Provisioning

## Summary

This flow describes how Okta delivers SCIM provisioning events to the Continuum Okta Service to manage user and group lifecycle within Continuum. When a user is created, updated, or deactivated in Okta, the Okta IdP sends a SCIM 2.0 request to the `continuumOktaService`. The Provisioning Sync component processes the event, uses the SSO Broker for token/session context, delegates attribute resolution to the Directory Adapter, and applies the resulting changes to the Continuum user model via `continuumUsersService`.

## Trigger

- **Type**: api-call (inbound SCIM webhook from Okta IdP)
- **Source**: Okta Identity Provider — triggered when an admin creates, updates, or deactivates a user or group in the Okta admin console, or via automated HR system provisioning
- **Frequency**: On demand, per user lifecycle event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Okta IdP | Delivers SCIM provisioning event | `oktaIdp` |
| Continuum Okta Service | Receives and orchestrates provisioning event processing | `continuumOktaService` |
| Provisioning Sync | Processes the SCIM event and coordinates provisioning workflow | `provisioningSync` |
| SSO Broker | Provides token/session context to provisioning workflows | `ssoBroker` |
| Directory Adapter | Maps Okta user/group attributes to Continuum user model | `directoryAdapter` |
| Okta Configuration Store | Provides tenant and connector configuration | `continuumOktaConfigStore` |
| Continuum Users Service | Applies user profile and group assignment changes | `continuumUsersService` |

## Steps

1. **Receives SCIM provisioning event**: The Okta IdP sends a SCIM 2.0 HTTP request (Create, Update, Patch, or Delete) to the `continuumOktaService` provisioning endpoint.
   - From: `oktaIdp`
   - To: `continuumOktaService` (provisioningSync)
   - Protocol: SCIM 2.0 / HTTPS

2. **Reads tenant and connector configuration**: Provisioning Sync reads the relevant tenant mapping and provisioning connector configuration from the Okta Configuration Store.
   - From: `provisioningSync`
   - To: `continuumOktaConfigStore`
   - Protocol: PostgreSQL

3. **Acquires token/session context**: Provisioning Sync uses the SSO Broker to obtain the necessary token or session context for processing the provisioning workflow.
   - From: `provisioningSync`
   - To: `ssoBroker`
   - Protocol: Direct (internal NestJS component call)

4. **Requests identity attribute resolution**: The SSO Broker delegates attribute and group mapping to the Directory Adapter.
   - From: `ssoBroker`
   - To: `directoryAdapter`
   - Protocol: Direct (internal NestJS component call)

5. **Maps Okta attributes to Continuum user model**: The Directory Adapter translates Okta user attributes and group memberships into the Continuum user model format.
   - From: `directoryAdapter`
   - To: `ssoBroker` (resolved user/group object)
   - Protocol: Direct (internal)

6. **Syncs user profile and group assignments to Continuum**: The `continuumOktaService` sends the resolved user profile and group assignment data to `continuumUsersService` to create, update, or deactivate the Continuum user record.
   - From: `continuumOktaService`
   - To: `continuumUsersService`
   - Protocol: REST (internal)

7. **Returns provisioning result to Okta**: The service returns an appropriate SCIM response (success or error) to the Okta IdP.
   - From: `continuumOktaService`
   - To: `oktaIdp`
   - Protocol: SCIM 2.0 / HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid SCIM payload from Okta | Provisioning Sync validation rejects the request | SCIM 400 error returned to Okta; Okta retries based on its retry policy |
| Tenant configuration not found | Provisioning Sync cannot resolve connector config | SCIM error returned; provisioning event not applied |
| `continuumUsersService` unavailable | Sync call fails | SCIM error returned to Okta; user not updated in Continuum |
| Duplicate provisioning event | Behavior not specified in codebase | No evidence of explicit idempotency handling |

## Sequence Diagram

```
oktaIdp -> continuumOktaService (provisioningSync): SCIM Create/Update/Delete request
continuumOktaService (provisioningSync) -> continuumOktaConfigStore: Reads tenant/connector config
continuumOktaService (provisioningSync) -> ssoBroker: Requests token/session context
ssoBroker -> directoryAdapter: Requests user/group attribute mapping
directoryAdapter --> ssoBroker: Returns mapped Continuum user/group object
ssoBroker --> continuumOktaService (provisioningSync): Returns session context
continuumOktaService -> continuumUsersService: Syncs user profile and group assignments
continuumUsersService --> continuumOktaService: Acknowledges sync
continuumOktaService --> oktaIdp: Returns SCIM success response
```

## Related

- Architecture dynamic view: `dynamic-okta-sso-provisioning-flow`
- Related flows: [SSO Login via OIDC](sso-oidc-login.md), [Identity Attribute Mapping](identity-attribute-mapping.md)
