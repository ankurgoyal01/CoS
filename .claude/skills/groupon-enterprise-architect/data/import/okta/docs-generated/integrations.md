---
service: "okta"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The Okta service has one external dependency (the Okta identity provider) and two internal Continuum dependencies (`continuumUsersService` and `continuumOktaConfigStore`). The service calls the Okta IdP for OIDC token exchange and SCIM provisioning, then propagates identity data inward to the Continuum user service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Okta Identity Provider | OIDC / SCIM (HTTPS) | SSO token exchange and user/group provisioning | yes | `oktaIdp` |

### Okta Identity Provider Detail

- **Protocol**: OIDC (OpenID Connect) for SSO; SCIM 2.0 for provisioning
- **Base URL / SDK**: Production — `https://groupon.okta.com`; Staging — `https://grouponsandbox.okta.com/` (from `.service.yml`)
- **Auth**: OAuth2 / OIDC client credentials and authorization code flow
- **Purpose**: The SSO Broker component exchanges authorization codes and tokens with the Okta IdP. The Provisioning Sync component processes SCIM provisioning events (user/group lifecycle) originating from Okta.
- **Failure mode**: SSO logins and provisioning events cannot be processed if the Okta IdP is unavailable.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `continuumUsersService` | REST (internal) | Synchronizes user identities and profile attributes resolved from Okta | `continuumUsersService` |
| `continuumOktaConfigStore` | PostgreSQL | Reads and writes tenant mappings, provisioning configuration, and connector metadata | `continuumOktaConfigStore` |

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Okta service is consumed by Groupon applications and services that depend on Okta-brokered SSO sessions and Continuum user identities.

## Dependency Health

> No evidence found in codebase. Health check, retry, and circuit breaker patterns for external and internal dependencies are not defined in the available architecture DSL or service metadata. For operational monitoring, refer to the SolarWinds SEUM dashboard: http://usch1swnet01.group.on/Orion/SEUM/TransactionDetails.aspx?NetObject=T:8
