---
service: "okta"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOktaService, continuumOktaConfigStore]
---

# Architecture Context

## System Context

The Okta service sits within the Continuum Platform (`continuumSystem`), Groupon's core commerce engine. It bridges the external Okta identity provider (`oktaIdp`) with Continuum's internal user model. The service receives OIDC tokens and SCIM provisioning events from Okta, resolves and maps identities through its internal components, and propagates user profile and group data to `continuumUsersService`. Configuration and tenant mappings are persisted in a dedicated PostgreSQL store (`continuumOktaConfigStore`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Continuum Okta Service | `continuumOktaService` | Service | TypeScript/Node.js | — | Deployable service for SSO, provisioning, and identity synchronization with Okta. |
| Okta Configuration Store | `continuumOktaConfigStore` | Database | PostgreSQL | — | Stores tenant mappings, provisioning configuration, and connector metadata. |

## Components by Container

### Continuum Okta Service (`continuumOktaService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| SSO Broker (`ssoBroker`) | Handles OIDC authorization code and token exchange flows with Okta. | NestJS Component |
| Provisioning Sync (`provisioningSync`) | Processes SCIM-based user and group provisioning events. | NestJS Component |
| Directory Adapter (`directoryAdapter`) | Maps identity attributes and groups between Okta and the Continuum user model. | TypeScript Library |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumOktaService` | `oktaIdp` | Calls OIDC and SCIM APIs | OIDC / SCIM (HTTPS) |
| `continuumOktaService` | `continuumUsersService` | Synchronizes user identities and profile attributes | REST (internal) |
| `continuumOktaService` | `continuumOktaConfigStore` | Reads and writes configuration and mapping data | PostgreSQL |
| `provisioningSync` | `ssoBroker` | Uses token/session context for provisioning workflows | Direct (internal component) |
| `ssoBroker` | `directoryAdapter` | Requests user/group resolution and attribute mappings | Direct (internal component) |

## Architecture Diagram References

- Component view: `components-continuum-okta-service`
- Dynamic view: `dynamic-okta-sso-provisioning-flow`
