---
service: "okta"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for the Okta service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [SSO Login via OIDC](sso-oidc-login.md) | synchronous | User initiates login through a Groupon application | OIDC authorization code flow between the Continuum Okta Service and the Okta IdP; culminates in an authenticated session for the user. |
| [SCIM User Provisioning](scim-user-provisioning.md) | synchronous | Okta triggers a SCIM provisioning event (user create/update/deactivate) | SCIM-based user lifecycle event processed by Provisioning Sync, mapped by Directory Adapter, and applied to Continuum user model via `continuumUsersService`. |
| [Identity Attribute Mapping](identity-attribute-mapping.md) | synchronous | Triggered within SSO login or provisioning flows | Directory Adapter resolves and translates Okta identity attributes and group memberships into the Continuum user model format. |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The SSO and provisioning flow is documented in the central architecture dynamic view `dynamic-okta-sso-provisioning-flow` (defined in `architecture/views/dynamics/okta-sso-login.dsl`). This view captures the interactions between `continuumOktaService`, `oktaIdp`, and `continuumUsersService`.

See [Architecture Context](../architecture-context.md) for the full relationship map.
