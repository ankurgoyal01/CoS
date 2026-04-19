## Deal Alerts — Service Overview

Deal Alerts ingests MDS data into PostgreSQL, computes field-level deltas, raises alerts, orchestrates downstream actions via n8n workflows, and exposes a Next.js web app for configuration, observability, and debugging.

---

## Postgres DB (`packages/db`)

The PostgreSQL schema in `packages/db` is the system of record for deal history, alerts, actions, notifications, and operational metadata.

- **Snapshots and deltas**
  - `deal_snapshots` stores the latest normalized snapshot per deal, with a generated hash and soft-delete marker.
  - `monitored_fields` defines which root and option fields should be diffed.
  - `deal_deltas` is range-partitioned on `timestamp` and records field-level changes across deal- and option-level scopes.
  - The `insert_snapshots(input_items jsonb)` function upserts snapshots with per-deal advisory locks, computes deltas via `get_deal_deltas`, and derives alert records via `generate_alerts_from_snapshot` and its resolver functions (`resolve_soldout`, `resolve_deal_ended`, `resolve_deal_ending`).

- **Alerting and actions**
  - `alert_types`, `alert_statuses`, and `alerts` store alert definitions, lifecycle status (for example, `Pending`, `Filtered`, `Muted`, `Resolved`), and per-alert payload (context, severity, dates, source).
  - `severity_matrices` and `severity_matrix_entries` model configurable severity rules per alert type and GP bands.
  - `alert_action_map` links alert types and severities to concrete action types and optional templates.
  - `actions`, `action_statuses`, and type-specific tables (`salesforce_task_actions`, `chat_actions`, `salesforce_tasks`) track which downstream actions were created, their status (`Created`, `Sent`, `Error`, etc.), and provider-specific payloads.
  - `alert_action_data` and `alert_inventory_attributions` provide denormalized views for enriched alert data (for example, GP metrics) and attribution between alerts, inventory deltas, tasks, and replies.

- **Notifications and replies**
  - Reference tables (`notification_channels`, `notification_statuses`, `notification_providers`) enumerate supported channels, statuses, and providers.
  - `notifications` stores outbound messages (primarily SMS) linked to alerts, with channel, status, provider metadata, scheduling fields, and arbitrary context; uniqueness constraints ensure one notification per alert/channel and deduplicate provider message IDs.
  - `notifications_aggregation_log` enforces “at most one notification per deal per day” for aggregation-sensitive flows.
  - `notification_status_history` records immutable provider status updates for each message.
  - `notification_replies` captures inbound replies and outbound follow-ups, with direction, threading, commands/parameters, and status, enabling downstream attribution and opt-out handling.

- **Supporting and configuration data**
  - `ingestion_runs` tracks ingestion executions with timing and basic volume counters.
  - `muted_alerts` stores account- or opportunity-scoped mutes per alert type with expiration and audit fields.
  - `region_business_hours` defines business-hour windows used by notification schedulers.
  - `templates` and related tablesß back the template system the web app and workflows use.
  - Summary-email tables (`summary_email_runs`, `summary_email_exclusions`, `summary_emails`, `summary_emails` recipients) support scheduled email summaries and opt-outs.

The full schema, including auth/identity tables and all constraints, is documented in `packages/db/README.md` and `packages/db/src/schema.sql`.

---

## n8n workflows (`resources/n8n/workflows`)

Each workflow below is backed by a JSON definition under `resources/n8n/workflows` and metadata in `resources/n8n/n8n_workflows.yml`. The link for each workflow uses the format `https://n8n.groupondev.com/workflow/{id}`.

### Ingestion and alert creation

## Deal Snapshots

https://n8n.groupondev.com/workflow/V9gADZiaZNLt8K84

### Description
This workflow periodically pulls paged deal data from the MDS API, writes normalized snapshots into the `deal_snapshots` table, and drives the database-side logic that computes deltas and raises alerts. It supports both scheduled execution and webhook-based paging so that large datasets can be processed in batches while tracking ingestion runs and basic metrics.

### Error handling and recovery
An error trigger routes failures to a centralized HTTP endpoint that records rich diagnostic details while allowing the workflow to finish cleanly. Start and finish notifications are emitted for each run with counts and timing information, so operators can detect partial failures and retry ingestion for specific runs if needed.

## External Alerts

https://n8n.groupondev.com/workflow/Uozx2Bzj08Dp9Nhr

### Description
This workflow imports external alert signals from BigQuery, converts them into Deal Alerts’ internal alert types, and inserts them into the `alerts` table with structured context. It runs on a daily schedule and maps human-readable alert descriptions into normalized metrics that downstream workflows use for actions and templating.

### Error handling and recovery
An error trigger sends detailed failure payloads to the same monitoring endpoint used by other jobs, including stack traces and workflow metadata. The workflow also records duration and the number of new alerts processed so that reruns over a time window can be reasoned about and partial imports can be retried.

### Alert action orchestration

## Execute Actions

https://n8n.groupondev.com/workflow/IK9q2JMcXvraTJLE

### Description
This workflow selects unprocessed alerts from Postgres, applies business filters, resolves Salesforce context, and maps alerts into high-level actions such as task creation or chat notifications. It batches work, enriches alerts with account and opportunity details, and prepares structured action payloads for execution.

### Error handling and recovery
An error trigger posts rich error reports to a monitoring endpoint and does not block future executions. The workflow tracks how many alerts were processed in a run and how long processing took, making it possible to safely rerun the job for overlapping windows without duplicating already processed actions.

## Execute Alert Actions

https://n8n.groupondev.com/workflow/ctqPyZnJtidxeVDt

### Description
This subworkflow receives prepared actions and executes them by calling external systems such as Salesforce and chat endpoints, then marks the originating actions as sent in Postgres. It encapsulates the details of building provider-specific requests and maintains a consistent contract with the main Execute Actions workflow.

### Error handling and recovery
Individual action executions use built-in retry settings where appropriate and mark failures in the actions table while continuing to process other items. This allows operators to rerun failed actions without re-triggering successful ones and to inspect which actions were retried or skipped.

## Get Contacts

https://n8n.groupondev.com/workflow/47tIBI9nKTX9NWPG

### Description
This subworkflow resolves the correct merchant contact for a given opportunity by querying Salesforce and applying business rules on account type, category, and region. It returns a normalized contact record with status flags that downstream workflows use when deciding whether an alert can be messaged.

### Error handling and recovery
The workflow encodes resolution outcomes as explicit statuses (for example, no contact, invalid number, or scope-limited) and returns structured reasons instead of hard failures. Calling workflows can treat these statuses as filters when creating notifications, avoiding retries that would never succeed while still being able to re-resolve contacts if account data changes.

### Notifications and messaging

## Sold Out Notifications

https://n8n.groupondev.com/workflow/7Qq4BLdilnldMA7Q

### Description
This workflow reads sold-out alerts from the database, resolves merchant contacts, and creates SMS notification records in the `notifications` table, including scheduling based on business hours and alert context. It processes alerts in batches and prepares one or more candidate messages per alert depending on configuration.

### Error handling and recovery
Errors are reported via a dedicated error trigger that posts details to the monitoring endpoint while letting the workflow continue. The job records how many alerts were processed in each run and uses status fields on notifications so that failed batches can be retried without duplicating messages that have already been scheduled.

## SMS Notifications Sender

https://n8n.groupondev.com/workflow/V1NnG5Jj0TjFJolZ

### Description
This workflow is responsible for sending scheduled SMS notifications, receiving provider status callbacks, and capturing inbound replies. It periodically queries the `notifications` table for due messages, sends them via the SMS provider, updates statuses and status history, and logs replies to a spreadsheet and to Postgres for later analysis.

### Error handling and recovery
An error trigger with structured reporting covers both the sending pipeline and the webhook listeners. The workflow maintains a global counter of processed messages per run and uses idempotent queries and status updates so that reruns or retries do not resend already delivered messages but can safely pick up messages that were left in an intermediate state.

## Email Summary

https://n8n.groupondev.com/workflow/ueEAUSiqvU37vSSQ

### Description
This workflow generates daily summary emails of alert-related tasks for account owners and managers, aggregating recent Salesforce activity into digestible reports. It tracks execution windows in a dedicated table so that each run covers a specific time range without gaps or overlaps.

### Error handling and recovery
Error triggers send detailed failure data to monitoring, and the workflow records summary run state in Postgres so that a failed run can be retried for a known time interval. Email sending uses limited retries and continues past individual failures so one problematic recipient does not block the rest of the batch.

## Attributions

https://n8n.groupondev.com/workflow/cT5FnUW8MgLN8Z8s

### Description
This workflow attempts to attribute inventory increases to either Salesforce task completion or SMS replies associated with alerts. It correlates tasks, replies, and deal quantity deltas over configurable time windows to produce attribution records that describe which follow-ups likely drove replenishment.

### Error handling and recovery
The workflow relies on idempotent queries into Postgres so that reruns over the same time window recompute the same attribution results. Conditional steps ensure that missing data does not cause hard failures; instead, records without sufficient evidence are skipped or produced with lower confidence.

### Administrative API

## Mute Alerts

https://n8n.groupondev.com/workflow/xHrW0DnGy7m33R16

### Description
This workflow exposes an authenticated HTTP endpoint that allows users or tools to mute specific alert types for a Salesforce account or opportunity until a given time. It validates and normalizes incoming requests, writes or updates records in the `muted_alerts` table, and returns clear responses about what was changed.

### Error handling and recovery
Input validation errors are returned as structured JSON responses with appropriate HTTP status codes, without touching persistent state. For valid requests, database writes are designed to be idempotent for the same key so that retried calls extend or overwrite existing mutes without creating duplicates.

---

## Web app (`apps/web`)

The web app in `apps/web` is a Next.js (App Router) application that connects to the Deal Alerts database and backend services to provide an operational UI.

- **Tech stack**
  - Next.js with React and TypeScript.
  - Kysely for type-safe SQL access to Postgres.
  - ORPC for typed RPC between the frontend and backend.
  - Tailwind-based design system components for a11y-friendly UI.

- **Responsibilities**
  - Read-only views over deals, alerts, notifications, and related entities for debugging and observability.
  - Administrative workflows for configuring alert rules, templates, and other runtime settings of the alerting system.
  - Helper tools for exploring template variables and previewing rendered messages that match the behavior of the shared template renderer.


