---
service: "seer-service"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [internal-network]
---

# API Surface

## Overview

Seer Service exposes a REST API (JAX-RS / Jersey, served on port 8080) organised into seven resource groups: `/jira`, `/jenkins`, `/deploybot`, `/opsgenie`, `/sonarqube`, `/serviceportal`, and `/seer`. All responses are `application/json`. The API is consumed by internal tooling only; it is not exposed to end users or external partners. Most write endpoints (`POST`) exist as manual-trigger alternatives to the scheduled Quartz jobs and allow operators to force an immediate data upload.

## Endpoints

### Jira (`/jira`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/jira/boards` | Returns all Jira board metadata | internal |
| GET | `/jira/sprint/reports` | Returns all stored sprint reports | internal |
| POST | `/jira/upload_sprint_report` | Manually triggers sprint report upload for a given request body | internal |
| POST | `/jira/upload_project_board_mappings` | Uploads project-to-Jira-board mappings to the database | internal |
| POST | `/jira/upload_board_sprint_mappings` | Uploads Jira board-to-sprint mappings to the database | internal |
| POST | `/jira/upload_sprint_report/{boardId}/{startDate}` | Uploads sprint reports for a specific board from a given start date | internal |
| POST | `/jira/upload_project_sprint_reports/{projectId}/{startDate}` | Uploads sprint reports for a specific project from a given start date | internal |
| POST | `/jira/upload_all_projects_sprint_reports/{startDate}` | Uploads sprint reports for all projects from a given start date | internal |
| GET | `/jira/get_board_sprint_report/{boardId}` | Retrieves stored sprint reports for a specific board | internal |
| GET | `/jira/get_sprint_report/board/{boardId}/sprint/{sprintId}` | Retrieves a specific sprint report by board and sprint ID | internal |
| POST | `/jira/upload_all_incidents` | Manually triggers upload of all GPROD incidents | internal |
| GET | `/jira/incidents/report` | Returns incident MTTR report for a date range (`startDate`, `endDate` query params) | internal |
| GET | `/jira/incidents` | Returns daily and weekly incident counts filtered by date range, service, owner, and severity (`startDate`, `endDate`, `service`, `owner`, `minSEV`, `maxSEV` query params) | internal |
| POST | `/jira/upload_multiple_sprint_report` | Triggers upload of multiple sprint reports | internal |

### Jenkins (`/jenkins`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/jenkins/upload_all_builds` | Manually triggers upload of all Jenkins build data | internal |
| GET | `/jenkins/build/report` | Returns daily and weekly build-time report (`startDate`, `endDate`, `service` query params) | internal |

### Deploybot (`/deploybot`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/deploybot/deployments/{serviceName}` | Returns stored deployments for a named service | internal |
| POST | `/deploybot/upload_all_deployments` | Manually triggers upload of all deployment records | internal |
| GET | `/deploybot/report` | Returns daily and weekly deployment frequency report (`startDate`, `endDate`, `service` query params) | internal |

### OpsGenie (`/opsgenie`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/opsgenie/teams` | Returns all OpsGenie team information | internal |
| POST | `/opsgenie/load_all_team_info` | Loads and stores all OpsGenie team details | internal |
| POST | `/opsgenie/load_all_alerts_info/{teamID}` | Loads and stores all alerts for a specific team | internal |
| POST | `/opsgenie/upload_all_teams_alerts_info` | Loads and stores alerts for all teams | internal |
| POST | `/opsgenie/upload_all_teams_custom_alerts_info/{startDate}` | Loads alerts for all teams from a given start date | internal |
| GET | `/opsgenie/team/{id}/report` | Returns alert report for a team over a date range | internal |
| GET | `/opsgenie/team/{id}/report_by_freq` | Returns alert report for a team with daily/weekly frequency breakdown | internal |

### SonarQube (`/sonarqube`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/sonarqube/metrics` | Returns all stored SonarQube project quality metrics | internal |

### Service Portal (`/serviceportal`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/serviceportal/services` | Returns all known service names | internal |
| GET | `/serviceportal/owners` | Returns service-to-owner mappings | internal |
| GET | `/serviceportal/{serviceName}/details` | Returns ownership and metadata for a named service | internal |
| POST | `/serviceportal/upload_all_services` | Uploads all service details from Service Portal to the database | internal |

### Seer / GitHub (`/seer`)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `/seer/upload_all_pull_requests` | Manually triggers upload of all GitHub pull-request data | internal |
| GET | `/seer/pullreq/report` | Returns daily and weekly pull-request metrics report (`startDate`, `endDate`, `service` query params) | internal |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` on all POST requests
- `Access-Control-Allow-Origin: *` on read endpoints that support cross-origin access (Jira boards, OpsGenie teams, SonarQube metrics, sprint reports)
- `Access-Control-Allow-Headers: Origin, X-Requested-With, X-Request-Id, Content-Type, Accept` on CORS-enabled endpoints
- `Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS` on CORS-enabled endpoints
- `Access-Control-Max-Age: 1728000` on CORS-enabled endpoints

### Error format

HTTP 500 is returned on internal errors. No structured error body is guaranteed by the current implementation — callers should treat a non-2xx response as a failure.

### Pagination

> No evidence found in codebase. The GitHub pull-request API call uses page 1 (`?page=1`) but no pagination is exposed in Seer's own endpoints.

## Rate Limits

> No rate limiting configured.

## Versioning

No versioning strategy is applied. All endpoints are unversioned at the URL level.

## OpenAPI / Schema References

An OpenAPI/Swagger schema is generated from the `com.groupon.seer_service.resources` package via `doc/swagger/config.yml`. The schema path is declared as `doc/swagger/swagger.yaml` in `.service.yml`. The generated file is not committed to the repository; it is produced at build time.
