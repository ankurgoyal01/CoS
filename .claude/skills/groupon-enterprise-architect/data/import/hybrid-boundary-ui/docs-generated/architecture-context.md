---
service: "hybrid-boundary-ui"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumHybridBoundaryUi]
---

# Architecture Context

## System Context

Hybrid Boundary UI is a single container (`continuumHybridBoundaryUi`) within `continuumSystem`. It is a browser-delivered Angular SPA served by Nginx. Users authenticate through Groupon Okta via OIDC before the application makes calls to the Hybrid Boundary API (`/release/v1`) for service configuration management and to the PAR Automation API (`/release/par`) for PAR request submission. All three external integrations are stub-only in the current federated architecture model — those services are not yet represented in the central Structurizr workspace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Hybrid Boundary UI | `continuumHybridBoundaryUi` | Web Application | Angular 8 SPA, Nginx | Angular 8 | Angular web UI for self-service management of Hybrid Boundary service configuration, endpoints, shifts, policies, and PAR workflows |

## Components by Container

### Hybrid Boundary UI (`continuumHybridBoundaryUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Hybrid Boundary UI App (`hbUiAngularSpa`) | Top-level Angular application, routing, and orchestration of all views | TypeScript, Angular |
| Auth Module (`hbUiAuthModule`) | OAuth2/OIDC integration and auth interceptor that attaches tokens to outbound requests | angular-oauth2-oidc |
| Config and User Services (`hbUiApiClient`) | HTTP clients for `/release/v1` service configuration and permissions APIs | Angular HttpClient |
| PAR Client (`hbUiParAutomationClient`) | HTTP client for `/release/par` PAR automation API | Angular HttpClient |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `hbUiAngularSpa` | `hbUiAuthModule` | Uses OAuth/OIDC authentication and token handling | Direct (in-process, Angular DI) |
| `hbUiAngularSpa` | `hbUiApiClient` | Calls `/release/v1` endpoints for service configuration operations | HTTPS/JSON |
| `hbUiAngularSpa` | `hbUiParAutomationClient` | Calls `/release/par` for PAR automation | HTTPS/JSON |
| `hbUiAuthModule` | Groupon Okta | Authenticates users and validates tokens (stub-only) | HTTPS/OIDC |
| `hbUiApiClient` | Hybrid Boundary API (`/release/v1`) | Reads and mutates Hybrid Boundary services and permissions (stub-only) | HTTPS/JSON |
| `hbUiParAutomationClient` | PAR Automation API (`/release/par`) | Creates PAR requests (stub-only) | HTTPS/JSON |

> All relationships to external systems (`unknownHybridBoundaryApiReleaseV1_u6f4c`, `unknownParAutomationApiReleasePar_u9d21`, `unknownGrouponOktaOauth_u3ab7`) are stub-only — those targets are not present in the current federated model.

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-hybrid-boundary-ui`
- Dynamic (Service Config Change): `dynamic-hybridBoundaryUiChangeFlow` (stub-only — view commented out due to external stub dependencies)
