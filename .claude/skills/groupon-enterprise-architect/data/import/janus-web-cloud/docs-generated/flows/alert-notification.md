---
service: "janus-web-cloud"
title: "Alert Notification Flow"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "alert-notification"
flow_type: scheduled
trigger: "Quartz-scheduled job execution or manual API call to POST /janus/api/v1/alert/{id}/send"
participants:
  - "jwc_apiResources"
  - "jwc_alertingEngine"
  - "jwc_mysqlDaos"
  - "janusOperationalSchema"
  - "jwc_integrationAdapters"
  - "elasticSearch"
  - "smtpRelay"
architecture_ref: "dynamic-alert-notification-flow"
---

# Alert Notification Flow

## Summary

The Alert Notification flow evaluates configured alert rules against live metrics data in Elasticsearch and dispatches email notifications to configured recipients when threshold conditions are met. It is the primary mechanism by which Janus Web Cloud surfaces operational anomalies to stakeholders. The flow is driven by Quartz scheduled jobs persisted in `continuumJanusMetadataMySql`, and can also be triggered on demand via the alert send API.

## Trigger

- **Type**: schedule (Quartz) or api-call (manual send)
- **Source**: Quartz Scheduler (reads trigger state from `quartzSchedulerTables`) or `POST /janus/api/v1/alert/{id}/send`
- **Frequency**: Per configured Quartz trigger schedule per alert definition; manual on demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives manual alert send request and routes to Alerting Engine; also serves CRUD for alert definitions | `jwc_apiResources` |
| Alerting Engine | Orchestrates threshold evaluation, loads alert config, and coordinates notification dispatch | `jwc_alertingEngine` |
| MySQL DAOs | Reads alert definitions, threshold expressions, recipient lists, and writes alert evaluation outcomes | `jwc_mysqlDaos` |
| Janus Operational Schema | Stores alert definitions, threshold expressions, recipient metadata, and outcome records | `janusOperationalSchema` |
| Integration Adapters | Executes Elasticsearch metric queries and dispatches SMTP notification emails | `jwc_integrationAdapters` |
| Elasticsearch | Source of metric index data evaluated against alert threshold expressions | `elasticSearch` |
| SMTP Relay | Delivers alert notification emails to configured recipients | `smtpRelay` |

## Steps

1. **Receive evaluation trigger**: The Quartz scheduler fires a scheduled alert job, or an operator calls `POST /janus/api/v1/alert/{id}/send` via API Resources.
   - From: `quartzSchedulerTables` (scheduled) or external caller (manual)
   - To: `jwc_alertingEngine` (via `jwc_apiResources` for manual path)
   - Protocol: Direct (in-process Quartz callback) or REST

2. **Load alert definitions**: Alerting Engine instructs MySQL DAOs to load the alert rule, threshold expression, evaluation window, and recipient list.
   - From: `jwc_alertingEngine`
   - To: `jwc_mysqlDaos` -> `janusOperationalSchema`
   - Protocol: Direct (in-process) / JDBC

3. **Query metrics from Elasticsearch**: Integration Adapters execute the metric query against the configured Elasticsearch index using the alert's expression parameters.
   - From: `jwc_alertingEngine` -> `jwc_integrationAdapters`
   - To: `elasticSearch`
   - Protocol: Elasticsearch REST SDK (elasticsearch 5.6.16)

4. **Evaluate threshold expression**: Alerting Engine applies the mathematical threshold expression (`commons-math3 3.6.1`) to the retrieved metric values to determine if the alert condition is satisfied.
   - From: `jwc_alertingEngine`
   - To: in-process evaluation
   - Protocol: Direct

5. **Dispatch notification**: If the threshold is breached, Alerting Engine instructs Integration Adapters to render an email template (Thymeleaf 3.0.14) and send it via the SMTP relay.
   - From: `jwc_alertingEngine` -> `jwc_integrationAdapters`
   - To: `smtpRelay`
   - Protocol: SMTP (simple-java-mail 4.1.1)

6. **Persist evaluation outcome**: MySQL DAOs write the alert evaluation result (triggered/not-triggered, timestamp, metric value) back to `janusOperationalSchema`.
   - From: `jwc_alertingEngine` -> `jwc_mysqlDaos`
   - To: `janusOperationalSchema`
   - Protocol: Direct (in-process) / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Elasticsearch unreachable | Evaluation step fails; exception caught by Alerting Engine | Alert not evaluated for this cycle; error logged to `loggingStack`; Quartz retries on next scheduled trigger |
| Threshold expression evaluation error | Exception caught in Alerting Engine | Alert marked as evaluation-error in `janusOperationalSchema`; no email sent |
| SMTP delivery failure | Exception from simple-java-mail caught by Integration Adapters | Alert email not delivered; evaluation outcome still written to MySQL; error logged |
| MySQL write failure | JDBI exception propagated | Outcome not persisted; error logged; Quartz will retry on next cycle |

## Sequence Diagram

```
Quartz / API Caller -> jwc_alertingEngine: Fire alert evaluation (scheduled or POST /janus/api/v1/alert/{id}/send)
jwc_alertingEngine -> jwc_mysqlDaos: Load alert definition, threshold, recipients
jwc_mysqlDaos -> janusOperationalSchema: SELECT alert metadata
janusOperationalSchema --> jwc_mysqlDaos: Alert definition row
jwc_mysqlDaos --> jwc_alertingEngine: Alert config
jwc_alertingEngine -> jwc_integrationAdapters: Execute metric query
jwc_integrationAdapters -> elasticSearch: Query metric index
elasticSearch --> jwc_integrationAdapters: Metric data
jwc_integrationAdapters --> jwc_alertingEngine: Metric values
jwc_alertingEngine -> jwc_alertingEngine: Evaluate threshold expression (commons-math3)
jwc_alertingEngine -> jwc_integrationAdapters: Dispatch notification email (if threshold breached)
jwc_integrationAdapters -> smtpRelay: SMTP send (simple-java-mail + Thymeleaf template)
smtpRelay --> jwc_integrationAdapters: Delivery acknowledgement
jwc_alertingEngine -> jwc_mysqlDaos: Write evaluation outcome
jwc_mysqlDaos -> janusOperationalSchema: INSERT/UPDATE alert outcome
```

## Related

- Architecture dynamic view: `dynamic-alert-notification-flow`
- Related flows: [Metadata Management](metadata-management.md) (alert CRUD via `/janus/api/v1/alert/*`)
- See [API Surface](../api-surface.md) for alert endpoint details
- See [Integrations](../integrations.md) for Elasticsearch and SMTP dependency details
