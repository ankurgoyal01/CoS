---
service: "pingdom"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 2
---

# Integrations

## Overview

The Pingdom service has one external dependency (the Pingdom SaaS REST API) and is consumed by two internal Groupon services. The external dependency is a stub in the federated architecture model because the Pingdom SaaS platform is not a Groupon-owned container. Both internal consumers interact with the Pingdom SaaS API directly using credentials and URLs associated with this service's registration.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Pingdom SaaS API | HTTPS / REST | Reads service status and health context for uptime monitoring | yes | `pingdomSaaSUnknown_59f16522` |

### Pingdom SaaS API Detail

- **Protocol**: HTTPS REST
- **Base URL**: `https://api.pingdom.com/api/2.1`
- **Auth**: API key (`App-Key` header) + Account-Email header + Basic Authorization (base64 encoded credentials). API key and account email referenced in `tdo-team` shift-report cron script.
- **Purpose**: Provides uptime check results, check summaries (downtime seconds, average response times), probe listings, and tag-to-check-ID mappings consumed by `ein_project` and `tdo-team` integrations.
- **Failure mode**: Uptime data collection is skipped for the affected date window; `ein_project` logs warnings and returns `status: "error"` from the collection task. Shift reports are omitted for the affected window.
- **Circuit breaker**: No evidence found in codebase. The `toolbox.modules.pingdom.PD` client used by `ein_project` implements retry logic with exponential backoff for HTTP 429 (rate limit) responses and connection errors.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `ein_project` (ProdCAT portal) | Direct Python module call | Collects Pingdom uptime data from the API, stores in `pingdom_logs` table, serves uptime dashboards, and triggers JSM alerts for services below threshold | Internal to `ein_project` |
| `tdo-team` (pingdom-shift-report cron) | HTTPS / REST (direct Pingdom API call) | Fetches 4-hour Pingdom failure windows and posts formatted shift reports to Google Chat spaces | Internal to `tdo-team` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| `ein_project` ProdCAT portal | Python module (`toolbox.modules.pingdom.PD`) | Collects daily uptime percentages, average response times, and no-latency uptime per Pingdom check/tag; displays in internal dashboard |
| `tdo-team` pingdom-shift-report | Bash / REST | Queries Pingdom API for failures within a 4-hour rolling window; posts flap counts, downtime, and response-time summaries to IMOC Google Chat spaces |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The `ein_project` `add_pingdom_uptimes` task pre-filters existing database records with a single bulk query before making Pingdom API calls, batches writes using `bulk_create`, and applies a 0.1-second inter-batch delay to respect Pingdom API rate limits. The `trigger_uptime_alert` task checks that yesterday's data has been successfully synced before sending any JSM alerts, preventing false-positive alerts when the sync has not yet completed.
