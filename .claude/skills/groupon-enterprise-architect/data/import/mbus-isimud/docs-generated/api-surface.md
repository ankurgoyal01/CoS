---
service: "mbus-isimud"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: []
---

# API Surface

## Overview

mbus-isimud exposes a JSON REST API on port 8080 (cloud) / 9000 (development). The API has three resource groups: `topology` for managing and executing named topologies, `execution` for querying and canceling past runs, and `generator` for inspecting the configured statistical data generators. All responses are JSON. The API is defined in `src/main/resources/openapi3.yml` and server stubs are generated at compile time via the swagger-codegen-maven-plugin.

## Endpoints

### Generator

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/generator` | Retrieve the full generator database (all size and duration distributions) | None |

### Execution

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/execution` | List all executions with pagination; filter by status (`pending`, `active`, `completed`, `all`) | None |
| `GET` | `/execution/{executionId}` | Retrieve details and results for a specific execution by ID | None |
| `DELETE` | `/execution/{executionId}` | Cancel an in-flight execution | None |

### Topology

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| `GET` | `/topology` | List all configured named topologies | None |
| `GET` | `/topology/{topologyName}` | Retrieve the full definition of a named topology | None |
| `GET` | `/topology/{topologyName}/messages` | Generate a dry-run message list for a named topology (no broker involved) | None |
| `POST` | `/topology/{topologyName}/messages` | Execute a named topology against the configured broker; returns an Execution record | None |
| `POST` | `/topology/messages` | Execute a fully custom topology supplied in the request body | None |
| `POST` | `/topology/scaled` | Execute a dynamically generated scaled topology (topic/queue count and producer/consumer templates specified in body) | None |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` is required for all `POST` requests.
- No authentication headers are required (the service is an internal utility tool).

### Error format

> No evidence found in codebase. Standard Dropwizard error responses are used (HTTP status code with JSON body).

### Pagination

Execution listing uses cursor-based pagination via `startId` (integer offset into the execution table) and `rows` (page size, default 10). The response includes a `Pagination` object with `start`, `next`, and `rows` fields.

## Query Parameters

| Parameter | Endpoints | Type | Default | Description |
|-----------|-----------|------|---------|-------------|
| `count` | `GET /topology/{name}/messages`, `POST /topology/{name}/messages`, `POST /topology/messages`, `POST /topology/scaled` | integer | 10 | Total number of messages to generate |
| `workers` | `POST /topology/{name}/messages`, `POST /topology/messages`, `POST /topology/scaled` | integer | 1 | Number of parallel worker threads |
| `seed` | `GET /topology/{name}/messages`, `POST` execution endpoints | integer | 0 | RNG seed for reproducible message generation |
| `type` | `GET /execution` | string enum | none | Filter executions by status: `pending`, `active`, `completed`, `all` |
| `startId` | `GET /execution` | integer | 0 | Pagination cursor |
| `rows` | `GET /execution` | integer | 10 | Page size |

## Key Request Body Schemas

### GenerateParameters (POST execution body)

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `speed` | double | 1.0 | Rate factor: 1 = real time, 2 = 2x speed, <=0 = ignore inter-message timing |
| `messages` | boolean | false | Include individual message records in response |
| `summary` | boolean | true | Include aggregate metrics summary |
| `summaryDepth` | integer | 1 | Metrics aggregation depth (1=ALL, 2=Channel, 3=Channel.Producer, 4=Channel.Producer.Index) |
| `brokers` | BrokerExecutionParameters | none | Optional per-broker producer/consumer allocation (ratios or counts) |

### BrokerExecutionParameters

| Field | Type | Description |
|-------|------|-------------|
| `brokers` | string[] | Named broker identifiers from configuration |
| `ratios` | map | Per-broker ratio for splitting producers and consumers |
| `counts` | map | Per-broker explicit producer/consumer counts |

## Rate Limits

No rate limiting configured.

## Versioning

No URL versioning is applied. The API version is defined as `0.1` in `openapi3.yml`. No versioning strategy is enforced beyond the single current version.

## OpenAPI / Schema References

- OpenAPI 3.0 spec: `src/main/resources/openapi3.yml`
- Legacy Swagger spec: `doc/swagger/swagger.yaml`
