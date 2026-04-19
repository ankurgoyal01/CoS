---
service: "tdo-team"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 5
internal_count: 1
---

# Integrations

## Overview

The tdo-team service integrates with five external systems and one internal Groupon service. All integrations are outbound only — the service makes HTTP calls on schedule, there is no inbound traffic. Authentication uses Basic Auth (Jira), OAuth 2.0 (Google APIs), API key (OpsGenie, Pingdom), and a Groupon client-ID header (Service Portal). Failure in any integration causes the affected cronjob to log an error and exit; there is no circuit breaker or retry logic beyond Kubernetes pod restart on failure.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Jira (groupondev.atlassian.net) | REST | Query incident/advisory/logbook/SEV4 tickets; post comments; transition tickets | yes | - |
| Google Drive / Docs API | REST (Google SDK) | Create IR document directories; copy IR template; rename and update IR documents | yes | - |
| OpsGenie API v2 | REST | Retrieve weekend on-call schedule participants by schedule ID | yes | - |
| Pingdom API v2.1 | REST | Fetch all monitor checks, results, and availability summaries for shift reports | yes | - |
| Google Chat / Slack webhooks | HTTPS webhook | Post shift reports, on-call rosters, IMOC OOO notices, and IR creation notifications | yes | - |

### Jira (groupondev.atlassian.net) Detail

- **Protocol**: REST (Jira REST API v2)
- **Base URL**: `https://groupondev.atlassian.net/rest/api/2/`
- **Auth**: HTTP Basic Auth with `incident-management@groupon.com` credentials (encoded in Authorization header)
- **Purpose**: Central data source for all incident and advisory action automation. Scripts read filters (`GET /filter/{id}`), search results, and individual ticket data; write comments (`POST /issue/{key}/comment`); and transition ticket status (`POST /issue/{key}/transitions`)
- **Key Jira Filter IDs used**:
  - `48661` — Advisory actions 30-day reminders
  - `44644` — GPROD subtasks 3 days to due date
  - `44645` — GPROD subtasks 10 days to due date
  - `44615` — GPROD subtasks 30 days to due date
  - `47402` — Open logbook tickets (older than 7 days, closed after 10)
  - `48483` — Open SEV4 tickets needing SLA reminders
- **JQL for IR Automation**: `project = GPROD and type=Incident and sev in (1,2,3,4,5) and status in ('Done','Mitigated') and 'IR Complete' not in ('Yes','Meeting Not Needed') and 'IR Document Link' is EMPTY and created >= startOfDay(-180)`
- **Failure mode**: Cronjob logs error and exits; Jira comments are not retried in the same run
- **Circuit breaker**: No

### Google Drive / Docs API Detail

- **Protocol**: REST via `google-api-python-client` SDK
- **Auth**: OAuth 2.0 with scopes `drive`, `drive.metadata`, `documents`; credentials stored in `secrets/google_secrets.json`
- **Purpose**: IR Automation creates a directory structure in the TDO Team Drive for each resolved incident and copies the IR template to produce a named IR document; also writes the document link back to Jira
- **Key resource IDs**:
  - TDO Team Drive: `0AP8-rRMZoqbNUk9PVA`
  - IR Template Document: `17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o`
  - IR Review Folder: `1TFPzaVdHjAg552ebDGTw1tLLsprqPiur`
- **Failure mode**: IR Automation logs exception and continues to next incident
- **Circuit breaker**: No

### OpsGenie API v2 Detail

- **Protocol**: REST
- **Base URL**: `https://api.opsgenie.com/v2/`
- **Auth**: `GenieKey` API key header
- **Purpose**: Weekend Oncall Job retrieves on-call participants for primary schedule (`1c2e68a5-8acf-4ea5-b1b7-b5f7d36c0c19`) and secondary schedule (`6d34656d-6ccb-4d3c-a674-9611edff860b`) for the upcoming weekend window; resolves user IDs to full names
- **Failure mode**: Script posts incomplete or empty roster to Google Chat
- **Circuit breaker**: No

### Pingdom API v2.1 Detail

- **Protocol**: REST
- **Base URL**: `https://api.pingdom.com/api/2.1`
- **Auth**: HTTP Basic Auth (Authorization header, App-key header, Account-Email header) using `pingdom@groupon.com` account
- **Purpose**: Pingdom Shift Report Job fetches all monitor checks, per-check results (in `down`/`unconfirmed` states), and 4-hour summary averages (downtime seconds, avg response time) to build shift reports
- **Thresholds applied**: flaps > 5 times, downtime > 300 seconds, avg response time > 4000 ms
- **Failure mode**: Script skips checks with null API responses (noted in code); partial report is posted to Google Chat
- **Circuit breaker**: No

### Google Chat / Slack Webhooks Detail

- **Protocol**: HTTPS webhook (POST with JSON body)
- **Purpose**:
  - `continuumTdoTeamPingdomShiftReportJob` posts to two Google Chat spaces: IMOC-Pingdom Shift Reports (`AAAAF7rv8s0`) and IMOC Handover (`AAAAnz4axIw`)
  - `continuumTdoTeamWeekendOncallJob` posts to IMOC Google Chat space (`AAQA6vBYz0U`)
  - `continuumTdoTeamImocOooWeekendJob` posts to Production Google Chat space (`AAAAOTeTjHg`)
  - `irAutomationSlackHelper` posts to "Incident Management" channel via webhook (`AAAAnz4axIw`)
- **Failure mode**: Logged; no retry
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Service Portal | REST | Look up service owner name and metadata by service name (`/api/v2/services/{name}`), used to tag Jira comments with service owner account IDs | - |

### Service Portal Detail

- **Protocol**: REST (HTTP)
- **Base URL**: `http://service-portal.production.service` (injected via `SP_URL` environment variable)
- **Auth**: `GRPN-Client-ID: tdo-coea-automation` header
- **Purpose**: All Bash cronjobs call `GET /api/v2/services/{serviceName}` to resolve the service owner's name, then query Jira's user search to obtain the Jira account ID for use in `@mention` comments
- **Failure mode**: If Service Portal returns null owner, the cronjob falls back to tagging the IMOC team account (`6102c01bc51f3a0069ab29b3`) in the Jira comment

## Consumed By

> Upstream consumers are tracked in the central architecture model. This service has no inbound callers; all invocations are schedule-driven by Kubernetes.

## Dependency Health

No circuit breaker or retry patterns are implemented. Each cronjob script makes sequential HTTP calls and logs errors if a call fails. Kubernetes will record the pod's exit code; a non-zero exit marks the CronJob run as failed. Liveness and readiness probes check for the existence of `/tdo-team/grpn/healthcheck` file during pod startup.
