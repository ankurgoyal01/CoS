---
service: "keboola"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Keboola platform status (managed by vendor) | Vendor-managed | Not applicable | Not applicable |

The `.service.yml` sets `status_endpoint.prefix: http://` with no path defined and `schema: disabled`, indicating no Groupon-managed health endpoint exists. Pipeline health is observable via Keboola's in-platform run monitoring and via Google Chat alerts from `kbcOpsNotifier`.

## Monitoring

### Metrics

> No evidence found in codebase. No Groupon-owned metrics or monitoring instrumentation exists. Pipeline run status (success/failure) is reported via Google Chat notifications from the `kbcOpsNotifier` component.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Keboola architecture overview | Confluence | https://groupondev.atlassian.net/wiki/spaces/GBDP/pages/80804446209/Keboola |
| Runbook | Google Docs | https://docs.google.com/document/d/1WgaJQjiZ1XoWkcn-gOmKGV7AD97TlXo5k5ghozaor_A/edit |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pipeline run failure | `kbcOpsNotifier` emits failure status after a pipeline run | warning / critical (depends on severity) | Check Keboola UI for run logs; create support ticket via Keboola in-platform support if needed |
| Destination load failure | `kbcDestinationWriters` reports error to `kbcOpsNotifier` | critical | Verify BigQuery availability; check Keboola run logs; escalate to Keboola support |

## Common Operations

### Restart Service

Keboola service is owned and maintained by the Keboola team. No action is needed from Groupon to restart the platform. To re-trigger a failed pipeline run, use the Keboola web UI to manually start the orchestration job.

### Scale Up / Down

Not applicable. Scaling is managed by the Keboola vendor. Operational procedures to be defined by service owner.

### Database Operations

Not applicable. Keboola does not own a Groupon-managed database. Data lands in BigQuery (external). Operational procedures to be defined by service owner.

## Troubleshooting

### Pipeline Extraction Failure

- **Symptoms**: Google Chat alert from `kbcOpsNotifier` indicating extraction run failure; BigQuery datasets not updated
- **Cause**: Salesforce API connectivity issue, credential expiry, or data volume exceeding connector limits
- **Resolution**: Check Keboola UI run logs for the extraction component; verify Salesforce API connectivity; create a Keboola support ticket via the in-platform support button if credential rotation is required

### Destination Load Failure

- **Symptoms**: Google Chat alert from `kbcOpsNotifier` indicating load stage failure; BigQuery not updated despite extraction succeeding
- **Cause**: BigQuery API connectivity issue, schema mismatch, or quota exhaustion
- **Resolution**: Check Keboola UI run logs for the destination writer component; verify BigQuery project status in GCP console; contact Keboola support for persistent load failures

### Transformation Failure

- **Symptoms**: Google Chat alert indicating transformation step failure; extraction succeeds but no data reaches BigQuery
- **Cause**: Transformation script error, malformed source data, or memory/time limit exceeded in the transformation runtime
- **Resolution**: Review transformation logs in Keboola UI; inspect source data for unexpected schema changes; update transformation configuration via Keboola UI

### Requesting Keboola Support

Keboola has an integrated support feature in the platform UI (bottom-right corner button). Create a support ticket by selecting the inquiry type, filling in a summary and description, attaching relevant component/configuration names, and selecting severity level. For critical issues (Severity 1 or 2), immediate response SLA applies per Keboola's support agreement.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All pipeline runs failing; no data reaching BigQuery | Immediate | gdoop-dev@groupon.com + Keboola support (Severity 1) |
| P2 | Specific pipeline runs failing; partial data loss | 30 min | gdoop-dev@groupon.com + Keboola support (Severity 2) |
| P3 | Delayed runs or non-critical notification failures | Next business day | gdoop-dev@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Salesforce | Verify via Keboola extraction connector status in UI | Pause affected pipelines; notify data consumers of delay |
| BigQuery | Verify via GCP console or Keboola destination writer status in UI | Retain data in Keboola staging; replay load when BigQuery recovers |
| Google Chat | Check GChat space `AAAArqovlCY` for recent messages | Monitor Keboola UI directly for run status |
