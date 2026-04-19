---
service: "Netsuite"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `https://status.netsuite.com/` | HTTP (external status page) | Manual / as needed | N/A |
| NetSuite Execution Log | In-platform log viewer | Per-execution | N/A |
| `customrecord_poes_auto_ctrl` running check field | Custom record flag | Per scheduled script run | N/A |
| PagerDuty service `PV35CXK` | Alert | On incident | Immediate |

> A status endpoint is explicitly disabled (`disabled: true`) in `.service.yml` because NetSuite is a SaaS platform.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| OTP script running flag stuck | Custom record field | `custrecord_poes_auto_ctrl_running_chk = T` beyond `custscript_push_*_running_reset` minutes | Exceeded reset threshold |
| Script execution errors | NetSuite Execution Log | ERROR entries from `nlapiLogExecution('ERROR', ...)` in any scheduled script or RESTlet | Any ERROR-level entry |
| SnapLogic pipeline response code | HTTP response | Non-200 response from SnapLogic trigger URL | `responseCode != 200` after 5 retries |
| Vendor bill creation failures | RESTlet response | `status: 'error'` entries in RESTlet response array | Any error status returned to caller |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| NetSuite Status | Oracle (external) | https://status.netsuite.com/ |
| NetSuite Execution Log | NetSuite UI (in-app) | Setup > Execution Log |
| PagerDuty | PagerDuty | https://groupon.pagerduty.com/services/PV35CXK |
| Confluence Internal Docs | Confluence | https://groupondev.atlassian.net/wiki/x/AALDERM |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| OTP scheduled script stuck | `custrecord_poes_auto_ctrl_running_chk = T` AND elapsed time > reset threshold | warning | Reset running flag to `F` on `customrecord_poes_auto_ctrl` record; verify last success timestamp; re-run script |
| SnapLogic integration failure | 5 consecutive failed HTTP responses from NetSuite to SnapLogic | critical | Check SnapLogic pipeline status; verify Bearer token validity; check SnapLogic feed URL is correct |
| Vendor bill RESTlet error | `status: 'error'` with `message: 'governance exceeded'` | warning | RESTlet is hitting governance limit; reduce batch size sent by caller or increase `custscript_vb_min_usage` threshold |
| PagerDuty alert | On-call notification via `netsuitesupport@groupon.com` | critical | Engage on-call engineer; escalate to FS - NetSuite team |

## Common Operations

### Restart Service

NetSuite scheduled scripts do not have a "restart" concept. To re-enable a stuck scheduled script:
1. Navigate to Setup > Scripting > Scripts > find the affected scheduled script
2. Open the Script Deployment record
3. Set Status to Scheduled (if it was set to Not Scheduled due to error)
4. Reset the `custrecord_poes_auto_ctrl_running_chk` flag to `F` on the relevant `customrecord_poes_auto_ctrl` record (search for it in Lists > Custom Records)
5. Verify the `custrecord_poes_auto_ctrl_last_success` and `custrecord_poes_auto_ctrl_last_modified` timestamps are correct

### Scale Up / Down

> Not applicable. NetSuite SaaS manages capacity. Adjust script batch sizes via deployment parameters (`custscript_push_*_nbr_to_send`, `custscript_push_*_max_kb_to_send`) to control throughput.

### Database Operations

NetSuite does not support direct DB access. For data corrections:
- Use NetSuite CSV import for bulk record updates
- Use SuiteScript Suitelet or one-time scheduled scripts for programmatic batch corrections
- Vendor bill backfill scripts (e.g., `Backfill OTP.js`) exist for historical data repairs

## Troubleshooting

### OTP export not reaching GLS or PO Manager
- **Symptoms**: GLS invoicing service or PO Manager EMEA reports missing OTP data; `customrecord_poes_auto_ctrl_last_success` is stale
- **Cause**: Scheduled script stuck (running flag = T), SnapLogic endpoint down, authentication failure, or governance limit exceeded
- **Resolution**: (1) Check NetSuite Execution Log for the relevant scheduled script. (2) Verify `customrecord_poes_auto_ctrl` running flag state. (3) Test SnapLogic pipeline URL manually. (4) Reset running flag and re-trigger script if stuck.

### Vendor bill RESTlet returning errors
- **Symptoms**: GLS reports bill creation failures; RESTlet returns `status: 'error'`
- **Cause**: Missing required fields (`glsPaymentUuid`, `entity`, `duedate`, `custbody_invoice_number`, `terms`), vendor not found, governance exceeded, or duplicate invoice number
- **Resolution**: (1) Check the `message` field in the RESTlet response for the specific error. (2) For `'governance exceeded'`, reduce batch size. (3) For `'vendor not found in netsuite'`, verify vendor internal ID in NetSuite. (4) For `'Terms not found in netsuite'`, verify payment term exists.

### JPM ACH payment files not submitting
- **Symptoms**: Finance staff unable to submit payment files; SnapLogic returns non-200 response from JPM Suitelet
- **Cause**: SnapLogic pipeline offline, Bearer token expired, or File Cabinet folder ID incorrect
- **Resolution**: (1) Check SnapLogic pipeline status for `Banking/JPM NS2 Send to ACH`. (2) Verify Bearer token in Suitelet script source has not expired. (3) Confirm File Cabinet folder `195312` contains the pending files.

### Kyriba sync not completing
- **Symptoms**: Treasury team reports Kyriba data not updated; Kyriba Suitelet shows error
- **Cause**: SnapLogic pipeline offline or Bearer token invalid
- **Resolution**: (1) Re-trigger manually via Kyriba Inbound or Outbound Suitelet. (2) Check SnapLogic `Kyriba outbound parent Trigger` / `Kyriba NS2 Inbound Kickoff` pipeline status.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | AP payment batch blocked, no vendor bills being created | Immediate | FS - NetSuite team (`netsuitesupport@groupon.com`), PagerDuty `PV35CXK` |
| P2 | OTP export delayed, reconciliation trigger failing | 30 min | FS - NetSuite team, Slack `#nsteam` |
| P3 | Minor script errors, non-critical automation failures | Next business day | FS - NetSuite team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Oracle NetSuite platform | https://status.netsuite.com/ | No fallback — platform dependency; escalate to Oracle Support |
| SnapLogic | SnapLogic dashboard / pipeline status | Manual re-trigger via Suitelet after issue resolves |
| JPMorgan Chase ACH | SnapLogic pipeline response code | Manual payment submission directly to JPM portal |
| Kyriba | SnapLogic pipeline response; Kyriba platform status | Manual file upload to Kyriba portal |
| BlackLine | SnapLogic pipeline response; BlackLine platform status | Manual balance entry in BlackLine |
