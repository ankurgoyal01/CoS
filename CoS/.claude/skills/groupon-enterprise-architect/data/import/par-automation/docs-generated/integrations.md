---
service: "par-automation"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 2
internal_count: 3
---

# Integrations

## Overview

PAR Automation has five downstream dependencies and one upstream consumer. Three are internal Groupon systems (Hybrid Boundary Lambda API, Service Portal, and Jira); two are external or platform-level (Okta IdP and GCP Secret Manager). All integrations are synchronous HTTP or SDK calls made within the scope of a single inbound request.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Okta IdP | OAuth2/HTTPS | Obtain bearer token for authenticating outbound Hybrid Boundary API calls | yes | `oktaIdp` |
| GCP Secret Manager | GCP SDK | Read service credentials (`HYBRID-BOUNDARY-SVC-USER`, Okta client secret, Jira API token) | yes | `cloudPlatform` |

### Okta IdP Detail

- **Protocol**: OAuth2 password grant over HTTPS
- **Base URL**: `https://groupon.okta.com/oauth2/aus1eg7vvhmWbdb7T1d8/v1/token` (configured via `okta_base_url`)
- **Auth**: HTTP Basic using headless service account `svc_hbuser` (`HYBRID-BOUNDARY-SVC-USER-OKTA` secret as client secret; `0oa1j37yho896VMQc1d8` as client ID)
- **Scope requested**: `openid groups profile email`
- **Purpose**: Acquires an `id_token` that is attached as `Authorization: Bearer` header on all Hybrid Boundary policy API calls
- **Failure mode**: If Okta is unavailable, the PAR request fails with `HTTP 500`
- **Circuit breaker**: No evidence found in codebase

### GCP Secret Manager Detail

- **Protocol**: GCP Secret Manager Go SDK (`cloud.google.com/go/secretmanager v1.11.5`)
- **Project**: Determined at runtime from `PROJECT_NUMBER` env var
- **Purpose**: Loads `HYBRID-BOUNDARY-SVC-USER` (password), `HYBRID-BOUNDARY-SVC-USER-OKTA` (Okta client secret), and `HYBRID-BOUNDARY-SVC-USER-JIRA` (Jira API token) at startup
- **Failure mode**: Panics at startup if the secret cannot be retrieved
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Service Portal | REST/HTTP | Retrieve service metadata and regulatory classifications (C1/C2/C3/SOX/PCI) for both the requesting service and the target domain | `servicePortal` |
| Hybrid Boundary Lambda API | REST/HTTP | Read existing authorization policies (duplicate check) and write new policies on approval | `continuumHybridBoundaryLambdaApi` |
| Jira (continuumJiraService) | REST/HTTPS | Create PAR Task and GPROD Logbook tickets; manage ticket status transitions | `continuumJiraService` |

### Service Portal Detail

- **Protocol**: REST/HTTP
- **Base URL**: `{service_portal_protocol}://{service_portal_root_domain}` — e.g., `http://service-portal.production.service` (production), `http://service-portal.staging.service` (staging), `http://service-portal.gensandbox.service` (sandbox)
- **Auth**: `GRPN-Client-ID: service-portal-test` header
- **Endpoints used**: `GET /grpn/healthcheck` (availability check), `GET /api/v2/services/{serviceName}?includes=regulatory_classifications`
- **Purpose**: Determines whether each service is classified as C1, C2, C3, SOX, or PCI — these attributes drive the auto-approval rules
- **Failure mode**: PAR request fails with appropriate HTTP error code if Service Portal is unavailable or the service is not found
- **Circuit breaker**: No evidence found in codebase

### Hybrid Boundary Lambda API Detail

- **Protocol**: REST/HTTP (internal service mesh routing)
- **Base URL**: `http://{hb_api_domain}` — e.g., `http://hybrid-boundary--api.production.service` (production)
- **Auth**: `Authorization: Bearer {okta_id_token}` — token fetched from Okta per request
- **Endpoints used**:
  - `GET /release/v1/services/{service}/{domain}/authorization/policies` — reads existing policies for duplicate detection
  - `POST /release/v1/services/{service}/{domain}/authorization/policies` — writes new policy on approval
- **Purpose**: Applies access control policy changes to the Hybrid Boundary mesh
- **Failure mode**: PAR request fails with `HTTP 500` on connection error; `HTTP 404` if the target domain is not registered
- **Circuit breaker**: No evidence found in codebase

### Jira (continuumJiraService) Detail

- **Protocol**: REST/HTTPS via `go-jira` v1.13.0 client
- **Base URL**: `https://groupondev.atlassian.net` (production), `https://groupondev-sandbox-274.atlassian.net` (staging/sandbox)
- **Auth**: HTTP Basic with a dedicated Jira service account and API token (`HYBRID-BOUNDARY-SVC-USER-JIRA` secret)
- **Projects used**: `PAR` (issue type: Task), `GPROD` (issue type: Logbook)
- **Purpose**: Creates auditable records of every PAR request; GPROD tickets record the production change
- **Failure mode**: PAR request fails with `HTTP 500` if Jira is unavailable; tickets are not created in non-production environments

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Hybrid Boundary UI (`continuumHybridBoundaryUi`) | REST/HTTP | Submits PAR form data to `POST /release/par` on behalf of engineers requesting service access |

> Upstream consumers beyond the Hybrid Boundary UI are tracked in the central architecture model.

## Dependency Health

All outbound HTTP calls use a 20-second client timeout. There is no retry logic, circuit breaker, or bulkhead pattern implemented — a failure in any downstream dependency causes the in-flight PAR request to fail immediately. Service Portal availability is pre-checked with a `/grpn/healthcheck` call before making the main service lookup.
