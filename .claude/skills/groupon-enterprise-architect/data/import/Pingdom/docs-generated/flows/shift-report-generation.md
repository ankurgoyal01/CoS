---
service: "pingdom"
title: "Shift Report Generation"
generated: "2026-03-03"
type: flow
flow_name: "shift-report-generation"
flow_type: scheduled
trigger: "Periodic Kubernetes CronJob (tdo-team pingdom-shift-report)"
participants:
  - "pingdomServicePortal"
  - "pingdomSaaSUnknown_59f16522"
  - "tdo-team (pingdom-shift-report cron)"
  - "Google Chat (IMOC spaces)"
architecture_ref: "dynamic-pingdom-shift-report"
---

# Shift Report Generation

## Summary

The Shift Report Generation flow queries the Pingdom SaaS REST API for monitor failures, flaps, downtime, and average response times within the last 4-hour rolling window, then posts a formatted summary to two IMOC (Incident Management On-Call) Google Chat spaces. It is executed as a Kubernetes CronJob (`pingdom-shift-report`) in the `tdo-team` application deployment. The report highlights monitors that flapped more than 5 times, had downtime exceeding 5 minutes, or had average response times above 4 seconds.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob in `tdo-team` namespace; entrypoint `./cronjobs/pingdom-shift-report.sh`
- **Frequency**: Periodic (exact cron schedule managed in Kubernetes deployment; script covers 4-hour rolling windows)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `tdo-team` CronJob | Executes shift report bash script; orchestrates all API calls and report posting | `tdo-team` Kubernetes CronJob |
| Pingdom SaaS API | Source of check IDs, probe names, check results, and summary statistics | `pingdomSaaSUnknown_59f16522` |
| Google Chat (IMOC Pingdom Shift Reports space) | Receives formatted shift report with flap/downtime/response-time summaries | External webhook |
| Google Chat (IMOC Handover space) | Receives reminder notification with link to the shift report and IMOC member mentions | External webhook |

## Steps

1. **Calculate 4-hour time window**: Computes `end_time` as current UTC time and `start_time` as 4 hours prior, both expressed as Unix epoch timestamps.
   - From: `pingdom-shift-report.sh`
   - To: local variables
   - Protocol: Direct (bash `date` command)

2. **Fetch all check IDs, hostnames, and names**: Calls `GET https://api.pingdom.com/api/2.1/checks` with API key and authorization headers to retrieve the full list of Pingdom monitors.
   - From: `pingdom-shift-report.sh`
   - To: Pingdom SaaS API
   - Protocol: HTTPS REST

3. **Fetch all probe names**: Calls `GET https://api.pingdom.com/api/2.1/probes` once and caches results for probe name resolution.
   - From: `pingdom-shift-report.sh`
   - To: Pingdom SaaS API
   - Protocol: HTTPS REST

4. **Query check results per monitor**: For each check ID, calls `GET https://api.pingdom.com/api/2.1/results/<check_id>?status=down,unconfirmed&from=<start>&to=<end>` to retrieve status transitions within the window.
   - From: `pingdom-shift-report.sh`
   - To: Pingdom SaaS API
   - Protocol: HTTPS REST

5. **Query check summaries per monitor**: For each check ID, calls `GET https://api.pingdom.com/api/2.1/summary.average/<check_id>?from=<start>&to=<end>&includeuptime=true` to retrieve `totaldown` seconds and `avgresponse` milliseconds.
   - From: `pingdom-shift-report.sh`
   - To: Pingdom SaaS API
   - Protocol: HTTPS REST

6. **Resolve probe names**: For each result with a `probeid`, looks up the probe name in the pre-fetched probe list JSON.
   - From: `pingdom-shift-report.sh`
   - To: local variable (`ALL_PROBES` JSON)
   - Protocol: Direct (jq)

7. **Build flap report**: Identifies monitors with more than 5 status transitions (`FLAPS_THRESHOLD=5`) in the window. Formats as tabular text sorted by flap count descending.
   - From: `pingdom-shift-report.sh`
   - To: in-memory variable
   - Protocol: Direct (awk/sort/uniq)

8. **Build downtime report**: Identifies monitors with `totaldown > 300` seconds (`DOWNTIME_THRESHOLD=300`). Formats as tabular text sorted by downtime seconds descending.
   - From: `pingdom-shift-report.sh`
   - To: in-memory variable
   - Protocol: Direct (awk/sort)

9. **Build response-time report**: Identifies monitors with `avgresponse > 4000` ms (`RESPONSETIME_AVG_THRESHOLD=4000`). Formats as tabular text sorted by average response time descending.
   - From: `pingdom-shift-report.sh`
   - To: in-memory variable
   - Protocol: Direct (awk/sort)

10. **Post shift report to IMOC Pingdom Shift Reports space**: POSTs a JSON payload containing all three report sections to the Google Chat webhook for the IMOC Pingdom Shift Reports space.
    - From: `pingdom-shift-report.sh`
    - To: Google Chat webhook (`https://chat.googleapis.com/v1/spaces/AAAAF7rv8s0/messages?...`)
    - Protocol: HTTPS (Google Chat Webhook)

11. **Post reminder to IMOC Handover space**: POSTs a reminder payload mentioning the on-duty IMOC members (resolved by UTC time window: 16:00–00:00, 00:00–08:00, or 08:00–16:00) to the IMOC Handover Google Chat space.
    - From: `pingdom-shift-report.sh`
    - To: Google Chat webhook (`https://chat.googleapis.com/v1/spaces/AAAAnz4axIw/messages?...`)
    - Protocol: HTTPS (Google Chat Webhook)

12. **Signal termination**: Creates the `$TERM_FILE` (`/tmp/signals/terminated`) to signal Kubernetes that the job has completed successfully.
    - From: `pingdom-shift-report.sh`
    - To: Kubernetes pod filesystem
    - Protocol: Direct (touch)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pingdom API returns empty/null response for a check | Check summary skipped if it contains `null`; result printed as empty row | That check excluded from downtime/response summaries |
| Google Chat POST fails | `curl` exits with non-zero; no retry logic | Report not delivered; no alert; requires manual re-run |
| CronJob exceeds `activeDeadlineSeconds` (1500s) | Kubernetes kills the pod | Partial report; check logs for the last processed check ID |
| Pingdom API credentials invalid/expired | `curl` returns 403; jq parses empty; no check results processed | Empty report posted; investigate credential rotation |

## Sequence Diagram

```
KubernetesCronJob -> pingdom-shift-report.sh: exec
pingdom-shift-report.sh -> PingdomSaaSAPI: GET /checks
PingdomSaaSAPI --> pingdom-shift-report.sh: [{id, hostname, name}]
pingdom-shift-report.sh -> PingdomSaaSAPI: GET /probes
PingdomSaaSAPI --> pingdom-shift-report.sh: [{id, name}]
loop for each check_id
  pingdom-shift-report.sh -> PingdomSaaSAPI: GET /results/<check_id>?status=down,unconfirmed&from=&to=
  PingdomSaaSAPI --> pingdom-shift-report.sh: [{time, status, statusdesc, probeid}]
  pingdom-shift-report.sh -> PingdomSaaSAPI: GET /summary.average/<check_id>?from=&to=&includeuptime=true
  PingdomSaaSAPI --> pingdom-shift-report.sh: {totaldown, avgresponse}
end
pingdom-shift-report.sh -> pingdom-shift-report.sh: build flap/downtime/response reports
pingdom-shift-report.sh -> GoogleChat(AAAAF7rv8s0): POST shift report payload
pingdom-shift-report.sh -> GoogleChat(AAAAnz4axIw): POST reminder with IMOC member mentions
pingdom-shift-report.sh -> KubernetesFilesystem: touch /tmp/signals/terminated
```

## Related

- Architecture dynamic view: `dynamic-pingdom-shift-report`
- Related flows: [Daily Uptime Data Collection](daily-uptime-collection.md), [Uptime Alert Evaluation](uptime-alert-evaluation.md)
