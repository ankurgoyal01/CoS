---
service: "openvpn-config"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

OpenVPN Config Automation has four external dependencies and no internal service-to-service dependencies. The primary integration is the OpenVPN Cloud Connexa SaaS REST API, which is called by all automation scripts. Three supporting integrations — Okta, corpad, and AWS DNS — are referenced in the service metadata (`.service.yml`) and architecture DSL stubs, but are not directly invoked by the Python scripts; they underpin the Cloud Connexa platform configuration rather than the automation layer.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| OpenVPN Cloud Connexa API | REST / HTTPS | All CRUD operations on networks, users, applications, IP services, and access groups | yes | `unknown_openvpncloudconnexa_10bbc2fe` |
| Okta | OIDC/SAML | Identity provider for Cloud Connexa user authentication (configured in Cloud Connexa, not invoked directly by scripts) | yes | `unknown_okta_65819e19` |
| corpad | Dependency | Corporate directory integration referenced by service metadata | no | `unknown_corpad_136b7626` |
| AWS DNS | DNS | DNS infrastructure for Cloud Connexa connector endpoints | no | `unknown_awsdns_72dd62ba` |

### OpenVPN Cloud Connexa API Detail

- **Protocol**: REST / HTTPS + JSON
- **Base URL**: `OPENVPN_API` environment variable (e.g., `https://<tenant>.openvpn.com`)
- **Auth**: OAuth 2.0 client credentials — POST to `/api/beta/oauth/token` with HTTP Basic (`OPENVPN_CLIENT_ID` / `OPENVPN_CLIENT_SECRET`); Bearer token used on all subsequent requests
- **Purpose**: The sole target of all automation scripts. Used to list, create, and delete networks, applications, IP services, user groups, users, and access groups in the Cloud Connexa tenant.
- **Failure mode**: Scripts terminate with a non-zero exit code and print error details (request args, response headers, response body) to stderr. No retry logic beyond rate-limit handling (HTTP 429 with sleep on `x-ratelimit-replenish-time`).
- **Circuit breaker**: No — the automation is a CLI batch tool with no long-running process; failure is surfaced at invocation time.

### Okta Detail

- **Protocol**: OIDC/SAML (configured within Cloud Connexa, not directly by automation scripts)
- **Base URL / SDK**: Not directly called by Python scripts
- **Auth**: N/A for automation layer
- **Purpose**: Provides identity federation so Groupon employees authenticate to the VPN via their Okta credentials
- **Failure mode**: If Okta is unavailable, user authentication to the VPN fails; backup/restore automation scripts are unaffected
- **Circuit breaker**: Not applicable

### corpad Detail

- **Protocol**: Dependency (referenced in `.service.yml`)
- **Purpose**: Corporate directory integration; specific usage not directly evidenced in automation scripts
- **Failure mode**: Not directly invoked by scripts; impact on automation not applicable

### AWS DNS Detail

- **Protocol**: DNS
- **Purpose**: DNS resolution for Cloud Connexa connector host endpoints
- **Failure mode**: Connector connectivity may degrade; backup/restore scripts are unaffected as they use the Cloud Connexa control-plane API directly

## Internal Dependencies

> No evidence found in codebase. OpenVPN Config Automation has no internal Groupon service-to-service dependencies.

## Consumed By

> Upstream consumers are tracked in the central architecture model. This automation toolset is invoked directly by InfoSec and NetOps engineers; it is not called by other internal services.

## Dependency Health

The `make_api_call` wrapper in `openvpn_api.py` handles HTTP 429 (rate limit exceeded) by sleeping for the duration specified in the `x-ratelimit-replenish-time` response header before retrying. All other non-2xx responses cause an immediate `raise_for_status()` exception, printing diagnostic context to stderr. No health check endpoints, circuit breakers, or retry-with-backoff logic beyond 429 handling are implemented.
