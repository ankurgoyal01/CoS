---
service: "ckod-backend-jtier"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [header-token]
---

# API Surface

## Overview

CKOD API exposes a JSON REST API over HTTP on port 8080. The API provides read and write access to Keboola job runs, deployment tracking records, SLA job completion data, cost alerts, project metadata, critical incident records, and dependency graphs. Consumers authenticate Jira-related operations using the `X-GRPN-Email` header. An admin port (8081) is exposed for Dropwizard health and metrics endpoints. All endpoints return `application/json`. The OpenAPI spec is available at `doc/swagger/swagger.yaml` in the repository.

## Endpoints

### Active Users

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/activeUser` | Retrieves point-of-contact for a project | None |

### Cost Alerts

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/costAlert/createAlertConfig` | Creates a new cost alert configuration | None |
| POST | `/costAlert/createServiceAlertConfig` | Maps a service to an alert configuration | None |
| DELETE | `/costAlert/deleteServiceAlertConfigs/{serviceId}` | Removes service-to-alert mappings for given alert IDs | None |
| GET | `/costAlert/getAlertConfig` | Returns alert configurations by IDs | None |
| GET | `/costAlert/getServiceAlertConfig/{id}` | Returns service-to-alert mapping for a service | None |
| GET | `/costAlert/kbcTelemetry/{jobStartDate}` | Returns KBC telemetry data for a given job start date | None |
| GET | `/costAlert/kbcTelemetryAgg/{kbcProjectId}` | Returns aggregated KBC telemetry data for a project | None |
| GET | `/costAlert/kbcWsCost/{projectId}` | Returns aggregated KBC workspace cost data for a project | None |
| GET | `/costAlert/serviceNames` | Returns the list of tracked service names | None |
| PUT | `/costAlert/updateAlertConfig/{id}` | Updates an existing cost alert configuration | None |
| GET | `/costAlert/{date}` | Returns cost alert data for a specified date | None |

### Dependencies

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dependency/{projectId}` | Returns dependency relationships for a Keboola project | None |

### Deployments

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deployments/all` | Returns a filtered list of tracked deployments | None |
| GET | `/deployments/create/airflow` | Creates a deployment tracking item for an Airflow deployment | `X-GRPN-Email` header |
| GET | `/deployments/create/keboola` | Creates a Jira GPROD ticket to track a Keboola deployment | `X-GRPN-Email` header |
| GET | `/deployments/describe` | Returns branch component details for a Keboola deployment | None |
| GET | `/deployments/diff_authors` | Returns commit authors between two refs in a GitHub repo | None |
| GET | `/deployments/diff_link` | Generates a GitHub diff link from a Deploybot URL | None |
| GET | `/deployments/environment` | Returns the environment of a deployment given a Deploybot URL | None |
| GET | `/deployments/initial_release` | Indicates whether a pipeline has a staging release but no production release | None |
| GET | `/deployments/metadata` | Returns all metadata associated with a Deploybot URL | None |
| GET | `/deployments/pipeline_authors` | Returns all contributors to a GitHub repository pipeline | None |
| GET | `/deployments/sox` | Returns whether the pipeline for a given Deploybot URL is SOX-scoped | None |
| GET | `/deployments/sox/requester/{deployment_ticket_id}` | Returns the requester of a SOX pipeline deployment ticket | None |

### DnD Critical Incidents

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/dndcriticalincident` | Returns DnD critical incidents filtered by date, status, severity, and other criteria | None |
| GET | `/dndcriticalincident/{id}` | Returns a single DnD critical incident by ID | None |

### EDW SLA Job Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/edwslajobdetail` | Returns EDW SLA job detail records filtered by date and SLA status | None |
| GET | `/edwslajobdetail/{id}` | Returns a single EDW SLA job detail record by ID | None |

### Keboola Jobs

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/jobs` | Retrieves Keboola pipeline job runs with filtering by project, status, and date range | None |
| GET | `/reruns` | Retrieves job rerun records for a given original run ID | None |

### KBC BigQuery Cost

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/kbcbqcost/{id}` | Returns BQ cost for a specific Keboola project (current_date - 1) | None |

### OP SLA Job Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/opslajobdetail` | Returns Optimus Prime SLA job detail records | None |
| GET | `/opslajobdetail/{id}` | Returns a single OP SLA job detail record by ID | None |

### Projects

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/projects` | Returns Keboola projects with optional flow inflation and soft-delete filter | None |
| GET | `/projects/{id}` | Returns a single Keboola project by ID | None |

### RM SLA Job Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/rmslajobdetail` | Returns RM SLA job detail records | None |
| GET | `/rmslajobdetail/{id}` | Returns a single RM SLA job detail record by ID | None |

### Keboola SLA Job Details

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/slajobdetail` | Returns Keboola SLA job detail records filtered by date, status, and project | None |
| GET | `/slajobdetail/{id}` | Returns a single Keboola SLA job detail record by ID | None |

## Request/Response Patterns

### Common headers

- `X-GRPN-Email` — Caller's email; used for deployment ticket requester attribution on `/deployments/create/*` endpoints.
- `Content-Type: application/json` — Required on all POST/PUT requests.

### Error format

> No evidence found in codebase. Standard Dropwizard/JTier error format is expected (JSON body with `code` and `message`).

### Pagination

The `/deployments/all` and `/jobs` endpoints accept `start_date`/`end_date` and `from`/`to` query parameters for time-range filtering. No cursor or page-number pagination was found in the Swagger definition.

## Rate Limits

> No rate limiting configured in discovered configuration files.

## Versioning

No API versioning strategy is present. All endpoints are served at the root path with no version prefix.

## OpenAPI / Schema References

- OpenAPI 2.0 (Swagger) specification: `doc/swagger/swagger.yaml`
- Swagger config: `doc/swagger/config.yml`
