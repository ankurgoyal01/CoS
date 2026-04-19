---
service: "janus-web-cloud"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal]
---

# API Surface

## Overview

Janus Web Cloud exposes a REST HTTP API consumed by operator tooling and internal Continuum services. All endpoints are grouped under functional resource paths. The primary API prefix is `/janus/api/v1/`, with additional top-level resource groups for annotations, attributes, Avro schemas, events, destinations, contexts, GDPR, metrics, replay, and promotion operations. The API follows standard HTTP verb semantics (GET for reads, POST/PUT for creates/updates, DELETE for removals).

## Endpoints

### Alert Management (`/janus/api/v1/alert/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/janus/api/v1/alert/{id}` | Retrieve a single alert definition | Internal |
| GET | `/janus/api/v1/alert/` | List all alert definitions | Internal |
| POST | `/janus/api/v1/alert/` | Create a new alert definition | Internal |
| PUT | `/janus/api/v1/alert/{id}` | Update an existing alert definition | Internal |
| DELETE | `/janus/api/v1/alert/{id}` | Delete an alert definition | Internal |
| POST | `/janus/api/v1/alert/{id}/send` | Manually trigger evaluation and dispatch of a specific alert | Internal |

### Annotations (`/annotations/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/annotations/` | List annotations | Internal |
| POST | `/annotations/` | Create an annotation | Internal |
| PUT | `/annotations/{id}` | Update an annotation | Internal |
| DELETE | `/annotations/{id}` | Delete an annotation | Internal |

### Attributes (`/attributes/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/attributes/` | List event attribute definitions | Internal |
| POST | `/attributes/` | Create an attribute definition | Internal |
| PUT | `/attributes/{id}` | Update an attribute definition | Internal |
| DELETE | `/attributes/{id}` | Delete an attribute definition | Internal |

### Avro Schema Registry (`/avro/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/avro/` | List registered Avro schemas | Internal |
| GET | `/avro/{id}` | Retrieve a specific schema version | Internal |
| POST | `/avro/` | Register a new Avro schema | Internal |
| PUT | `/avro/{id}` | Update/version an existing schema | Internal |

### Events (`/events/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/events/` | List Janus event definitions | Internal |
| POST | `/events/` | Create an event definition | Internal |
| PUT | `/events/{id}` | Update an event definition | Internal |
| DELETE | `/events/{id}` | Delete an event definition | Internal |

### Destinations (`/destinations/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/destinations/` | List configured destinations | Internal |
| POST | `/destinations/` | Create a destination | Internal |
| PUT | `/destinations/{id}` | Update a destination | Internal |
| DELETE | `/destinations/{id}` | Delete a destination | Internal |

### Contexts (`/contexts/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/contexts/` | List context definitions | Internal |
| POST | `/contexts/` | Create a context | Internal |
| PUT | `/contexts/{id}` | Update a context | Internal |
| DELETE | `/contexts/{id}` | Delete a context | Internal |

### GDPR (`/gdpr/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/gdpr/` | Query GDPR event report data | Internal |
| POST | `/gdpr/` | Initiate a GDPR report generation request | Internal |

### Metrics (`/metrics/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/metrics/` | Query Janus operational metrics from Elasticsearch | Internal |

### Replay (`/replay/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/replay/` | List replay job definitions and statuses | Internal |
| POST | `/replay/` | Submit a new replay request | Internal |
| GET | `/replay/{id}` | Retrieve status of a specific replay job | Internal |
| DELETE | `/replay/{id}` | Cancel a pending replay job | Internal |

### Promote (`/promote/*`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/promote/` | Promote a metadata configuration to a target environment | Internal |

## Request/Response Patterns

### Common headers

> No evidence found of a mandated common header set beyond standard HTTP headers. Consumers should refer to JTier platform conventions for correlation-ID propagation.

### Error format

> No evidence found of a documented standard error response shape in the architecture model. Dropwizard's default error format returns JSON with `code` and `message` fields.

### Pagination

> No evidence found of a documented pagination pattern. Assumed list endpoints return full result sets or apply server-side limits.

## Rate Limits

> No rate limiting configured.

## Versioning

The primary alert API is versioned via the URL path prefix `/janus/api/v1/`. Other resource groups (`/annotations`, `/attributes`, `/avro`, `/events`, `/destinations`, `/contexts`, `/gdpr`, `/metrics`, `/replay`, `/promote`) do not carry an explicit version segment in the path.

## OpenAPI / Schema References

> No evidence found of an OpenAPI specification or proto file in the architecture model. Schema definitions are managed through the `/avro/*` API endpoints backed by `janusSchemaRegistry`.
