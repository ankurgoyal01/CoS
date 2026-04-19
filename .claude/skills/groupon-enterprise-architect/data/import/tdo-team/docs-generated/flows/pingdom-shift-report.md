---
service: "tdo-team"
title: "Pingdom Shift Report"
generated: "2026-03-03"
type: flow
flow_name: "pingdom-shift-report"
flow_type: scheduled
trigger: "Kubernetes CronJob — every 4 hours daily"
participants:
  - "continuumTdoTeamPingdomShiftReportJob"
architecture_ref: "tdo-team-containers"
---

# Pingdom Shift Report

## Summary

The Pingdom Shift Report flow runs every 4 hours and generates a monitoring shift summary from Pingdom data. It fetches all Pingdom check results for the past 4-hour window, applies thresholds for flaps (more than 5), downtime (more than 300 seconds), and response time (average above 4000 ms), and posts a formatted shift report to two Google Chat spaces: the IMOC Pingdom Shift Reports space and the IMOC Handover space. The script has one of the longest active deadlines (1500 seconds) due to the volume of per-check API calls.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`continuumTdoTeamPingdomShiftReportJob`)
- **Frequency**: Every 4 hours daily (`0 0,4,8,12,16,20 * * *`)
- **Invocation**: `./cronjobs/pingdom-shift-report.sh` (Bash shell script)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Pingdom Shift Report CronJob | Schedule trigger; executes the Bash script | `continuumTdoTeamPingdomShiftReportJob` |
| Pingdom API v2.1 | Source of monitor check data, check results, and summary averages | - |
| Google Chat webhook (IMOC Pingdom Shift Reports space) | Destination for shift report (`AAAAF7rv8s0`) | - |
| Google Chat webhook (IMOC Handover space) | Destination for shift report (`AAAAnz4axIw`) | - |

## Steps

1. **Fetch all Pingdom checks**: The script calls `GET /api/2.1/checks` on the Pingdom API to retrieve the full list of active monitor checks.
   - From: Pingdom Shift Report CronJob
   - To: Pingdom API (`https://api.pingdom.com/api/2.1/checks`)
   - Protocol: REST (HTTPS, Basic Auth with App-key and Account-Email headers)

2. **Fetch check results for 4-hour window**: For each check, the script calls `GET /api/2.1/results/{checkId}` for the past 4-hour window and filters for `down` and `unconfirmed_down` results to count flaps.
   - From: Pingdom Shift Report CronJob
   - To: Pingdom API (`https://api.pingdom.com/api/2.1/results/{checkId}?from={4h_ago}&to={now}&status=down,unconfirmed_down`)
   - Protocol: REST (HTTPS, Basic Auth)

3. **Fetch 4-hour summary statistics**: For each check, the script calls `GET /api/2.1/summary.average/{checkId}` for the 4-hour window to retrieve total downtime seconds and average response time.
   - From: Pingdom Shift Report CronJob
   - To: Pingdom API (`https://api.pingdom.com/api/2.1/summary.average/{checkId}?from={4h_ago}&to={now}`)
   - Protocol: REST (HTTPS, Basic Auth)

4. **Apply anomaly thresholds**: The script evaluates three threshold criteria for each check:
   - Flaps threshold: more than 5 state changes in the window
   - Downtime threshold: more than 300 seconds of downtime
   - Response time threshold: average response time above 4000 ms
   Checks that exceed any threshold are flagged for inclusion in the report.
   - From: Pingdom Shift Report CronJob (local computation)
   - Protocol: n/a

5. **Build and post shift report to IMOC Pingdom Shift Reports space**: The script constructs a formatted Google Chat message summarizing all flagged checks and posts it to the IMOC Pingdom Shift Reports space (`AAAAF7rv8s0`).
   - From: Pingdom Shift Report CronJob
   - To: Google Chat webhook (`https://chat.googleapis.com/v1/spaces/AAAAF7rv8s0/messages?...`)
   - Protocol: HTTPS webhook POST

6. **Post shift report to IMOC Handover space**: The script posts the same or a condensed version of the report to the IMOC Handover Google Chat space (`AAAAnz4axIw`).
   - From: Pingdom Shift Report CronJob
   - To: Google Chat webhook (`https://chat.googleapis.com/v1/spaces/AAAAnz4axIw/messages?...`)
   - Protocol: HTTPS webhook POST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pingdom API returns null for a check | Noted in code ("skip null response checks") | Check is skipped; partial report is still posted |
| All checks healthy (no threshold breaches) | Empty anomaly list; report still posted indicating clean shift | Shift report posted with "no issues" indication |
| Google Chat webhook POST fails | Logged | Report not delivered to affected space; no retry |
| Script runtime exceeds 1500s (activeDeadlineSeconds) | Kubernetes terminates pod | Report may be incomplete; partial data posted if webhook was called before timeout |

## Sequence Diagram

```
CronJob -> Pingdom API: GET /api/2.1/checks
Pingdom API --> CronJob: list of all monitor checks
loop for each check:
  CronJob -> Pingdom API: GET /api/2.1/results/{checkId}?from=4h_ago&to=now&status=down,unconfirmed_down
  Pingdom API --> CronJob: check result events (flap count)
  CronJob -> Pingdom API: GET /api/2.1/summary.average/{checkId}?from=4h_ago&to=now
  Pingdom API --> CronJob: downtime seconds, avg response time
  CronJob -> CronJob: evaluate thresholds (flaps>5, downtime>300s, avg_rt>4000ms)
end loop
CronJob -> Google Chat webhook (AAAAF7rv8s0): POST shift report
Google Chat --> CronJob: 200 OK
CronJob -> Google Chat webhook (AAAAnz4axIw): POST shift report
Google Chat --> CronJob: 200 OK
```

## Related

- Architecture container view: `tdo-team-containers`
- Related flows: [Weekend On-Call Notification](weekend-oncall.md)
- Integration details: [Integrations](../integrations.md)
- Runbook section: [Troubleshooting — Pingdom Shift Report Not Posting](../runbook.md)
