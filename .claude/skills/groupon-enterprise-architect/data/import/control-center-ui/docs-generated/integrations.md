---
service: "control-center-ui"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 2
internal_count: 2
---

# Integrations

## Overview

Control Center UI integrates with 4 systems: 2 internal Continuum backend services (DPCC Service, Pricing Control Center Jtier Service) and 2 external platforms (Doorman SSO for authentication, AWS S3 for bulk file staging). All backend integrations are mediated through Nginx reverse proxy paths.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Doorman SSO | OAuth2 redirect | User authentication and session management for internal staff | yes | `continuumDoormanSSO` |
| AWS S3 | SDK (aws-sdk) | File staging for bulk sale CSV uploads | no | N/A |

### Doorman SSO Detail

- **Protocol**: OAuth2 / SSO redirect
- **Base URL / SDK**: Doorman SSO service (Groupon internal)
- **Auth**: OAuth2 authorization code flow
- **Purpose**: Enforces authentication for all routes; unauthenticated users are redirected to Doorman. All internal tool users must have valid Doorman sessions.
- **Failure mode**: No users can access the application; all routes return auth failure or redirect loop.
- **Circuit breaker**: No evidence found in codebase.

### AWS S3 Detail

- **Protocol**: HTTPS / AWS SDK (aws-sdk 2.307.0)
- **Base URL / SDK**: aws-sdk 2.307.0 (configured bucket endpoint)
- **Auth**: AWS credentials (configured in environment/runtime)
- **Purpose**: Accepts CSV file uploads from the bulk sale uploader feature for backend processing.
- **Failure mode**: Bulk upload feature fails; manual sale creation via Sale Builder remains unaffected.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| DPCC Service | REST (Nginx proxy: `/__/proxies/dpcc-service/v1.0/sales`) | Sale and pricing CRUD: create, read, update, delete sale events and price configurations | `continuumDpccService` |
| Pricing Control Center Jtier Service | REST (Nginx proxy: `/__/proxies/pccjt-service`) | Deal search, division lookup, sale scheduling queries | `continuumPricingControlCenterJtierService` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon pricing analysts / commerce operations staff | HTTPS / browser | Internal tool access for sale and pricing management |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

> No evidence found in codebase for explicit health check, retry, or circuit breaker patterns at the SPA/Nginx layer. The Nginx proxy layer will surface backend errors as HTTP error responses to the SPA. Ember Data error handling surfaces these to the user via model error states. Backend health is the responsibility of DPCC Service and PCCJT Service owners.
