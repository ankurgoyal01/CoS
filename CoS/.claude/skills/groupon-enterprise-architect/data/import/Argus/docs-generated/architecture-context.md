---
service: "argus"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - "continuumArgusAlertSyncJob"
    - "continuumArgusDashboardSyncJob"
    - "continuumArgusSummaryReportJob"
---

# Architecture Context

## System Context

Argus sits within the **Continuum Platform** (`continuumSystem`) as a set of three batch CLI jobs responsible for all Wavefront monitoring configuration. It has no inbound callers at runtime — it is invoked by the Jenkins CI pipeline on `master` branch merges or by operators manually. All runtime interactions are outbound to the Wavefront SaaS API at `https://groupon.wavefront.com`. The services it monitors (Lazlo, API Proxy, Deckard, Client ID, Torii, Consent Log) are peer containers within Continuum; Argus does not call those services directly but reads metrics they emit into Wavefront.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Argus Alert Sync Job | `continuumArgusAlertSyncJob` | Batch Job | Groovy, Gradle, SnakeYAML | 2.3.11 / 5.0 | CLI job that loads alert definitions from YAML templates and creates/updates Wavefront alerts |
| Argus Dashboard Sync Job | `continuumArgusDashboardSyncJob` | Batch Job | Groovy, Gradle, SnakeYAML, HTTPBuilder | 2.3.11 / 5.0 / 0.7.1 | CLI job that loads graph definitions, builds dashboard payloads, and updates Wavefront dashboards |
| Argus Alert Summary Job | `continuumArgusSummaryReportJob` | Batch Job | Groovy, Gradle, HTTPBuilder | 2.3.11 / 5.0 | CLI report mode that queries recent alert firing counts and prints a summary for operators |

## Components by Container

### Argus Alert Sync Job (`continuumArgusAlertSyncJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Alert Definition Loader (`argusAlertDefinitionLoader`) | Recursively reads alert YAML definition files from `src/main/resources/alerts/` | Groovy File I/O, SnakeYAML |
| Alert Template Renderer (`argusAlertTemplateRenderer`) | Renders Wavefront condition and display expressions by substituting template variables (metric, method, threshold, colo, host) using `SimpleTemplateEngine` | Groovy SimpleTemplateEngine |
| Alert Submitter (`argusAlertSubmitter`) | Searches existing alerts via `POST /api/v2/search/alert`; creates new alerts via `POST /api/v2/alert`; updates changed alerts via `PUT /api/v2/alert/:id` | HTTPBuilder, Wavefront API |

### Argus Dashboard Sync Job (`continuumArgusDashboardSyncJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dashboard Definition Loader (`argusDashboardTemplateLoader`) | Loads graph definitions, SLA definitions (`definitions/clientsSLA.yml`), and chart templates from YAML resources | Groovy File I/O, SnakeYAML |
| Dashboard Payload Builder (`argusDashboardChartBuilder`) | Queries live Wavefront metrics via `GET /chart/api`, matches metric names against graph definition regexes, and assembles dashboard section and chart payloads | Groovy, SimpleTemplateEngine |
| Dashboard Submitter (`argusDashboardSubmitter`) | Submits fully assembled dashboard payloads to Wavefront via `POST /api/dashboard` | HTTPBuilder, Wavefront API |

### Argus Alert Summary Job (`continuumArgusSummaryReportJob`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Summary Query Builder (`argusSummaryQueryBuilder`) | Builds `flapping(1w, -1*ts(~alert.isfiring.<alertId>))` queries for each alert to measure weekly firing frequency | Groovy |
| Summary Reporter (`argusSummaryReporter`) | Executes flapping queries against `GET /chart/api`, collects results, filters by threshold, and prints top firing alerts to console | HTTPBuilder, Console Output |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumArgusAlertSyncJob` | `wavefront` | Searches, creates, and updates alerts via API | REST / HTTPS |
| `continuumArgusDashboardSyncJob` | `wavefront` | Reads metrics and updates dashboards via API | REST / HTTPS |
| `continuumArgusSummaryReportJob` | `wavefront` | Queries alert firing time series via API | REST / HTTPS |
| `argusAlertDefinitionLoader` | `argusAlertTemplateRenderer` | Passes parsed alert definitions for templating | In-process |
| `argusAlertTemplateRenderer` | `argusAlertSubmitter` | Provides rendered alert payloads for Wavefront sync | In-process |
| `argusDashboardTemplateLoader` | `argusDashboardChartBuilder` | Provides definitions and templates for chart assembly | In-process |
| `argusDashboardChartBuilder` | `argusDashboardSubmitter` | Provides dashboard payloads for submission | In-process |
| `argusSummaryQueryBuilder` | `argusSummaryReporter` | Supplies rendered summary queries and thresholds | In-process |

## Architecture Diagram References

- Component (Alert Sync Job): `components-continuum-argus-alert-sync-job`
- Component (Dashboard Sync Job): `components-continuum-argus-dashboard-sync-job`
- Component (Summary Report Job): `components-continuum-argus-summary-report-job`
- Dynamic flow: `dynamic-argus-alert-sync-flow`
