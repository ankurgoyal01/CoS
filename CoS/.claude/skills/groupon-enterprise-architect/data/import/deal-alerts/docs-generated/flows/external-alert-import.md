---
service: "deal-alerts"
title: "External Alert Import"
generated: "2026-03-03"
type: flow
flow_name: "external-alert-import"
flow_type: scheduled
trigger: "Daily schedule in n8n"
participants:
  - "continuumDealAlertsWorkflows_externalAlertsImporter"
  - "bigQuery"
  - "continuumDealAlertsDb_alertLifecycle"
architecture_ref: "dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle"
---

# External Alert Import

## Summary

The External Alerts Importer is a daily n8n workflow that pulls alert signals from Google BigQuery and maps them into the internal alert system. These external signals supplement the alerts generated internally by the snapshot ingestion process, providing additional data-driven insights from analytics pipelines (e.g., Teradata, Keboola). Imported alerts are stored with their external source identifier and participate in the same action orchestration pipeline as internal alerts.

## Trigger

- **Type**: schedule
- **Source**: n8n scheduled timer
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External Alerts Importer | Orchestrates BigQuery query and alert mapping | `continuumDealAlertsWorkflows_externalAlertsImporter` |
| BigQuery | Source of external alert signals from analytics pipelines | `bigQuery` |
| Alert Lifecycle Tables | Receives mapped external alert records | `continuumDealAlertsDb_alertLifecycle` |

## Steps

1. **Query BigQuery**: The workflow executes a query against BigQuery to fetch external alert signals for the current period.
   - From: `continuumDealAlertsWorkflows_externalAlertsImporter`
   - To: `bigQuery`
   - Protocol: BigQuery API

2. **Map to internal alerts**: Each external signal is mapped to the internal alert schema with `deal_id`, `alert_type`, `context`, `description`, `severity`, and `source` (set to 'bigquery', 'teradata', or 'keboola').
   - From: `continuumDealAlertsWorkflows_externalAlertsImporter`
   - To: Internal processing

3. **Insert alerts**: Mapped alerts are inserted into the `alerts` table with the appropriate external source tag.
   - From: `continuumDealAlertsWorkflows_externalAlertsImporter`
   - To: `continuumDealAlertsDb_alertLifecycle`
   - Protocol: SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| BigQuery API unavailable | Workflow fails; retried on next daily run | No external alerts for that day; internal alerts unaffected |
| Invalid alert data from BigQuery | Mapping validation skips malformed records | Valid alerts still inserted |

## Sequence Diagram

```
ExternalAlertsImporter -> BigQuery: Query external alert signals
BigQuery --> ExternalAlertsImporter: Alert signal rows
ExternalAlertsImporter -> AlertLifecycle: Insert mapped alerts (source='bigquery')
```

## Related

- Architecture dynamic view: `dynamic-deal-alerts-continuumDealAlertsDb_alertLifecycle`
- Related flows: [Deal Snapshot Ingestion](deal-snapshot-ingestion.md), [Action Orchestration](action-orchestration.md)
