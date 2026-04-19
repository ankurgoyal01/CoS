---
service: "okta"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [oidc, scim]
auth_mechanisms: [oauth2, oidc-tokens]
---

# API Surface

## Overview

The Okta service exposes its functionality primarily through integration with the Okta identity provider using OIDC (OpenID Connect) and SCIM protocols. The `continuumOktaService` acts as a relying party and provisioning endpoint: it initiates and completes OIDC authorization code flows, exchanges tokens, and receives SCIM provisioning calls from Okta for user and group lifecycle management.

## Endpoints

### SSO and OIDC

> No evidence found in codebase. Specific endpoint paths are not defined in the federated architecture DSL or service metadata. The SSO Broker component handles OIDC authorization code and token exchange flows with Okta; actual route definitions are not present in the repository snapshot.

### SCIM Provisioning

> No evidence found in codebase. Specific SCIM endpoint paths are not defined in the federated architecture DSL. The Provisioning Sync component processes SCIM-based user and group provisioning events; actual route definitions are not present in the repository snapshot.

## Request/Response Patterns

### Common headers

> No evidence found in codebase.

### Error format

> No evidence found in codebase.

### Pagination

> No evidence found in codebase.

## Rate Limits

> No evidence found in codebase. Rate limiting, if applied, is governed by the upstream Okta IdP API limits and is not configured within this service's own codebase artifacts.

## Versioning

> No evidence found in codebase.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present in the repository snapshot. See the external Okta API documentation referenced in `.service.yml`:
> - Owners manual: https://docs.google.com/a/groupon.com/document/d/1rKfppoiMAZNdOqDHYnbXfM4wDBqJZdhJzrryoZ57EM0/edit?usp=sharing
> - Architecture diagrams: https://confluence.groupondev.com/display/IT/Okta+Architectural+Diagrams
