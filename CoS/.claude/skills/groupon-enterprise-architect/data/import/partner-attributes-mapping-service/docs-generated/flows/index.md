---
service: "partner-attributes-mapping-service"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for the Partner Attributes Mapping Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Mapping Request Flow](mapping-request-flow.md) | synchronous | API call (`POST /v1/mapping`, `POST /v1/search_*`, `PUT /v1/*_mappings`, `DELETE /v1/groupon_mapping/{id}`) | Create, search, update, or delete bidirectional ID mappings between Groupon and partner entity identifiers |
| [Signature Creation Flow](signature-creation-flow.md) | synchronous | API call (`POST /v1/signature`) | Generate an HMAC-SHA1 signature for a payload destined for a partner endpoint |
| [Signature Validation Flow](signature-validation-flow.md) | synchronous | API call (`POST /v1/signature/validation`) | Validate an inbound HMAC signature sent by a partner |
| [Partner Secret Management Flow](partner-secret-management-flow.md) | synchronous | API call (`POST /v1/partners/{name}/secrets/generate`, `PUT /v1/partners/{name}/secrets/update`) | Generate or rotate HMAC signing secrets for a registered partner |
| [Service Startup and Migration Flow](service-startup-flow.md) | scheduled | Service process start (pod initialization) | Apply pending database schema migrations and initialize application components before serving traffic |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 1 |

## Cross-Service Flows

The mapping and signature flows are documented as dynamic views in the Continuum architecture model:

- `dynamic-pams-mapping-request-flow` — covers the internal component path for all mapping CRUD operations
- `dynamic-pams-signature-request-flow` — covers the internal component path for signature creation and validation

These dynamic views are defined in `architecture/views/dynamics/pams-mapping-request-flow.dsl` and `architecture/views/dynamics/pams-signature-request-flow.dsl`.

Callers of PAMS (upstream internal Groupon services distributing CLO inventory to partners) participate in cross-service flows tracked in the central Continuum architecture model.
