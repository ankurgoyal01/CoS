---
service: "okta"
title: "Identity Attribute Mapping"
generated: "2026-03-03"
type: flow
flow_name: "identity-attribute-mapping"
flow_type: synchronous
trigger: "Invoked within SSO login or SCIM provisioning flows when identity attribute resolution is required"
participants:
  - "ssoBroker"
  - "directoryAdapter"
  - "continuumOktaConfigStore"
architecture_ref: "components-continuum-okta-service"
---

# Identity Attribute Mapping

## Summary

This flow describes how the Directory Adapter resolves and translates identity attributes and group memberships between the Okta identity model and the Continuum user model. The flow is invoked as a sub-flow within both the [SSO Login via OIDC](sso-oidc-login.md) and [SCIM User Provisioning](scim-user-provisioning.md) flows whenever an identity needs to be mapped from Okta's representation to Continuum's representation.

## Trigger

- **Type**: api-call (internal component invocation)
- **Source**: SSO Broker (`ssoBroker`), triggered during OIDC token processing or SCIM provisioning event handling
- **Frequency**: On demand, per SSO login or provisioning event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| SSO Broker | Initiates the mapping request; provides Okta identity claims or SCIM user payload | `ssoBroker` |
| Directory Adapter | Resolves and translates identity attributes and group memberships | `directoryAdapter` |
| Okta Configuration Store | Provides attribute mapping rules and group configuration for the tenant | `continuumOktaConfigStore` |

## Steps

1. **Receives mapping request from SSO Broker**: The SSO Broker passes Okta identity claims (from an OIDC ID token or SCIM payload) to the Directory Adapter along with tenant context.
   - From: `ssoBroker`
   - To: `directoryAdapter`
   - Protocol: Direct (internal TypeScript library call)

2. **Reads attribute mapping configuration**: The Directory Adapter reads the tenant-specific attribute mapping rules and group definitions from the Okta Configuration Store.
   - From: `directoryAdapter`
   - To: `continuumOktaConfigStore`
   - Protocol: PostgreSQL

3. **Maps user identity attributes**: The Directory Adapter translates Okta user profile attributes (e.g., email, name, custom attributes) to their corresponding Continuum user model fields using the configured mapping rules.
   - From: `directoryAdapter` (internal processing)
   - To: `directoryAdapter` (resolved attribute set)
   - Protocol: Direct (in-process)

4. **Maps group memberships**: The Directory Adapter resolves Okta group memberships to Continuum group/role assignments based on configured group mapping rules.
   - From: `directoryAdapter` (internal processing)
   - To: `directoryAdapter` (resolved group assignments)
   - Protocol: Direct (in-process)

5. **Returns resolved Continuum user/group object**: The Directory Adapter returns the fully mapped Continuum user model object (including profile attributes and group assignments) to the SSO Broker.
   - From: `directoryAdapter`
   - To: `ssoBroker`
   - Protocol: Direct (internal TypeScript library return)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Unknown Okta attribute with no mapping rule | Attribute skipped or default applied | Depends on implementation; no evidence in codebase |
| Group not found in Continuum mapping config | Group assignment skipped | Depends on implementation; no evidence in codebase |
| Config store unavailable during attribute lookup | Read fails | Mapping cannot be completed; calling flow fails |

## Sequence Diagram

```
ssoBroker -> directoryAdapter: Requests user/group resolution and attribute mappings
directoryAdapter -> continuumOktaConfigStore: Reads tenant attribute mapping rules
continuumOktaConfigStore --> directoryAdapter: Returns mapping configuration
directoryAdapter -> directoryAdapter: Maps Okta attributes to Continuum user model
directoryAdapter -> directoryAdapter: Maps Okta groups to Continuum groups/roles
directoryAdapter --> ssoBroker: Returns resolved Continuum user/group object
```

## Related

- Architecture component view: `components-continuum-okta-service`
- Related flows: [SSO Login via OIDC](sso-oidc-login.md), [SCIM User Provisioning](scim-user-provisioning.md)
