---
service: "expy-service"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

Expy Service exposes a synchronous REST API consumed by internal Groupon services. The API covers four concerns: experiment bucketing decisions, project and datafile management, feature flag and experiment CRUD (via manager sub-resources), and audience/access-policy/birdcage configuration. All endpoints follow JAX-RS conventions and are implemented using the Dropwizard (JTier) framework.

## Endpoints

### Experiment Bucketing

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/experiments` | Perform an experiment bucketing decision for a user | Internal network |

### Project Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/project` | Retrieve project configurations | Internal network |
| POST | `/project` | Create or update a project registration | Internal network |

### Datafile Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/datafile/{sdkKey}` | Fetch the current Optimizely datafile for the given SDK key | Internal network |

### Feature Flag Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/feature-manager/*` | List or retrieve feature flag definitions | Internal network |
| POST | `/feature-manager/*` | Create or update a feature flag | Internal network |
| PUT | `/feature-manager/*` | Update an existing feature flag | Internal network |
| DELETE | `/feature-manager/*` | Delete a feature flag | Internal network |

### Experiment Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/experiment-manager/*` | List or retrieve experiment definitions | Internal network |
| POST | `/experiment-manager/*` | Create or update an experiment | Internal network |
| PUT | `/experiment-manager/*` | Update an existing experiment | Internal network |
| DELETE | `/experiment-manager/*` | Delete an experiment | Internal network |

### Audience Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/audience/*` | List or retrieve audience definitions | Internal network |
| POST | `/audience/*` | Create or update an audience | Internal network |
| PUT | `/audience/*` | Update an existing audience | Internal network |
| DELETE | `/audience/*` | Delete an audience | Internal network |

### Access Policy Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/access-policy/*` | Retrieve access policies | Internal network |
| POST | `/access-policy/*` | Create or update an access policy | Internal network |
| PUT | `/access-policy/*` | Update an existing access policy | Internal network |
| DELETE | `/access-policy/*` | Delete an access policy | Internal network |

### Birdcage Integration

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/birdcage/*` | Retrieve Birdcage flag data proxied through Expy | Internal network |
| POST | `/birdcage/*` | Create or update Birdcage flag entries | Internal network |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all POST/PUT requests
- `Accept: application/json` — expected for all responses

### Error format

> No evidence found in the architecture model. Standard Dropwizard/JTier error format expected (JSON body with `code` and `message` fields). Confirm with service owner.

### Pagination

> No evidence found in the architecture model. Confirm pagination strategy with service owner for list endpoints under `/feature-manager/*`, `/experiment-manager/*`, `/audience/*`.

## Rate Limits

> No rate limiting configured — this is an internal service on the Continuum platform.

## Versioning

No URL-based API versioning is evident from the architecture model. The API is versioned implicitly through JTier deployment lifecycle. Confirm versioning strategy with the Optimize team.

## OpenAPI / Schema References

> No OpenAPI spec or schema files are referenced in the architecture model. Contact optimize@groupon.com for current API contract documentation.
