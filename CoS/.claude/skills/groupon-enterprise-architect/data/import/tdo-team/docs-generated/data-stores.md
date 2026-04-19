---
service: "tdo-team"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

The tdo-team service is stateless and does not own any data stores. Persistent state lives entirely in external systems:

- **Jira** (groupondev.atlassian.net) — incident tickets, advisory action items, subtask/IA tickets, logbook tickets, and SEV4 incident records are the source of truth
- **Google Drive** — IR documents and the IR template document (`17RdOoak4QWMOHQ2Adu649eOQ0ZIlOpYz0cJbSkdCy0o`) are stored in the TDO Team Drive (`0AP8-rRMZoqbNUk9PVA`), IR Review folder (`1TFPzaVdHjAg552ebDGTw1tLLsprqPiur`)
- **Service Portal** — service ownership metadata is read from `http://service-portal.production.service/api/v2/services/{name}`

Local log files are written to `/tdo-team/logs/` within the container pod (ephemeral, not persisted beyond the pod lifetime).

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No caching layer is used by this service. (The `influxdb` library is listed as a Pipfile dependency, suggesting a historical or optional metrics write path, but no InfluxDB connection is configured in the active codebase.)

## Data Flows

- CronJobs read ticket lists from Jira filters via `GET /rest/api/2/filter/{id}` and then `GET` the resulting `searchUrl`.
- CronJobs write Jira comments via `POST /rest/api/2/issue/{key}/comment`.
- Close-logbooks cronjob transitions Jira tickets via `POST /rest/api/2/issue/{key}/transitions`.
- IR Automation reads Jira ticket metadata, creates a Google Doc copy from the IR template, and writes the resulting doc URL back to the Jira ticket as a comment.
- Service owner data flows from Service Portal (`/api/v2/services/{name}`) into Jira comment bodies for notification purposes.
