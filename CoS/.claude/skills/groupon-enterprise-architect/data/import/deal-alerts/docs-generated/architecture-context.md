---
service: "deal-alerts"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDealAlertsWebApp", "continuumDealAlertsDb", "continuumDealAlertsWorkflows"]
---

# Architecture Context

## System Context

Deal Alerts sits within the Continuum Platform as a supply monitoring and merchant notification subsystem. It ingests deal data from the Marketing Deal Service (MDS), stores snapshots and deltas in a dedicated PostgreSQL database, and generates alerts that drive downstream actions. The system is split into three containers: a Next.js web app for human interaction, a PostgreSQL database as the authoritative data store, and n8n workflows for batch processing and integration orchestration.

External dependencies include Salesforce for contact resolution and task creation, Twilio for SMS notification delivery, and BigQuery for importing external alert signals.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Deal Alerts Web App | `continuumDealAlertsWebApp` | Web Application | Next.js, React, TypeScript | Next.js operational UI and ORPC backend for querying alerts, notifications, templates, and configuration. |
| Deal Alerts DB | `continuumDealAlertsDb` | Database | PostgreSQL | Authoritative PostgreSQL database for snapshots, deltas, alerts, notifications, actions, and configuration. |
| Deal Alerts Workflows | `continuumDealAlertsWorkflows` | Backend | n8n | n8n workflows that ingest deal data, derive alerts, create notifications, and execute downstream actions. |

## Components by Container

### Deal Alerts Web App (`continuumDealAlertsWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| ORPC Application Router | Aggregates domain routers for alerts, snapshots, templates, severity matrices, notifications, and health endpoints. | TypeScript, ORPC |
| Alerts API Router | Read alert lists and details with joined notification, action, and reply context. | TypeScript, ORPC, Kysely |
| Snapshots API Router | List and fetch deal snapshots with search across deal_search and deal_snapshots. | TypeScript, ORPC, Kysely |
| Deltas API Router | Serve deal_deltas time series and field-at-time lookups. | TypeScript, ORPC, Kysely |
| Monitored Fields API Router | Expose configured monitored_fields for diffing root and option scopes. | TypeScript, ORPC, Kysely |
| Templates API Router | Manage template previews and variable catalogs used across notifications. | TypeScript, ORPC, Kysely |
| Action Map API Router | Read and manage alert_action_map configurations mapping alert types to actions and templates. | TypeScript, ORPC, Kysely |
| Action Types API Router | Expose available action_types reference data. | TypeScript, ORPC, Kysely |
| Severity Matrix API Router | Serve severity matrix entries and metadata for alert severity resolution. | TypeScript, ORPC, Kysely |
| Logs API Router | Aggregate error logs across actions, summary emails, and notification replies for observability. | TypeScript, ORPC, Kysely |
| SMS Analytics API Router | Provide SMS notification stats, conversations, and filters over replies and statuses. | TypeScript, ORPC, Kysely |
| Muted Alerts API Router | CRUD operations for account- and opportunity-scoped muted_alerts. | TypeScript, ORPC, Kysely |
| Health API Router | Lightweight health and readiness endpoint. | TypeScript, ORPC |
| Kysely Database Client | Typed SQL client and connection pool to Deal Alerts Postgres. | Kysely, Postgres |
| BetterAuth SSO | Google SSO entrypoint with domain allowlist and token scrubbing backed by Postgres. | BetterAuth, Google OAuth |
| Template Renderer Adapter | Uses shared template-renderer library to preview notification and chat templates. | TypeScript, template-renderer |

### Deal Alerts DB (`continuumDealAlertsDb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Snapshot Storage | deal_snapshots table with search indexes plus time-partitioned deal_deltas history and monitored_fields configuration. | PostgreSQL schema |
| Snapshot Alerting Functions | PL/pgSQL functions insert_snapshots, get_deal_deltas, generate_alerts_from_snapshot, resolve_soldout/ending/ended orchestrating locks, delta computation, and alert creation. | PL/pgSQL |
| Alert Lifecycle Tables | alerts, alert_types, alert_statuses, muted_alerts, severity_matrices, severity_matrix_entries governing alert states and severity rules. | PostgreSQL schema |
| Action & Attribution Tables | actions, action_types, action_statuses, alert_action_map, alert_action_data, salesforce_task_actions, salesforce_tasks, alert_inventory_attributions supporting downstream tasks and attribution. | PostgreSQL schema |
| Notification & Reply Tables | notifications, notification_status_history, notification_replies, notifications_aggregation_log, region_business_hours, message_templates, message_template_variables storing outbound SMS/email data and replies. | PostgreSQL schema |
| Summary Email Tables | summary_email_runs, summary_emails, summary_email_exclusions tracking daily email summaries and opt-outs. | PostgreSQL schema |
| Ingestion Bookkeeping | ingestion_runs audit log for MDS ingest executions with counts and status. | PostgreSQL schema |

### Deal Alerts Workflows (`continuumDealAlertsWorkflows`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Deal Snapshots Ingestor | Scheduled and webhook-triggered workflow that pages MDS API, normalizes deals, and inserts snapshots to Postgres. | n8n |
| External Alerts Importer | Daily workflow pulling BigQuery alert signals and mapping them into internal alerts. | n8n |
| Execute Actions | Selects pending alerts, applies filters (deal, GP30, SF), severity rules, and assigns actions. | n8n |
| Execute Alert Actions | Executes prepared actions by creating Salesforce tasks and sending chat messages, then resolves alerts. | n8n |
| SoldOut Notifications | Processes SoldOut alerts, resolves contacts, selects templates, and creates notification records. | n8n |
| SMS Notifications Sender | Sends due SMS notifications via Twilio, handles callbacks, and records replies/status history. | n8n |
| Email Summary | Generates daily summary emails about alert-related tasks and records run state. | n8n |
| Attributions | Correlates inventory replenishment with Salesforce tasks and SMS replies to produce attribution records. | n8n |
| Get Contacts Resolver | Queries Salesforce to resolve merchant contacts with statuses for use by other workflows. | n8n |
| Mute Alerts Endpoint | Authenticated HTTP endpoint to create or update muted_alerts records idempotently. | n8n |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDealAlertsWebApp` | `continuumDealAlertsDb` | Reads alerts, notifications, actions, templates, and configuration via Kysely. | PostgreSQL |
| `continuumDealAlertsWebApp` | `continuumDealAlertsWorkflows` | Displays operational state for workflow-driven alerts and actions (read-only UI). | Status visibility |
| `continuumDealAlertsWorkflows` | `continuumDealAlertsDb` | Creates snapshots, alerts, notifications, actions, and email records. | JDBC/SQL |
| `continuumDealAlertsWorkflows` | `continuumMarketingDealService` | Pulls deal snapshots for ingestion. | HTTP |
| `continuumDealAlertsWorkflows` | `bigQuery` | Imports external alert signals. | BigQuery API |
| `continuumDealAlertsWorkflows` | `salesForce` | Resolves contacts and creates tasks. | HTTPS/REST |
| `continuumDealAlertsWorkflows` | `twilio` | Sends SMS and handles delivery callbacks. | HTTPS |

## Architecture Diagram References

- Component: `components-continuum-deal-alerts-web-app`
- Component: `components-continuum-deal-alerts-db`
- Component: `components-continuum-deal-alerts-workflows`
- Dynamic: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
