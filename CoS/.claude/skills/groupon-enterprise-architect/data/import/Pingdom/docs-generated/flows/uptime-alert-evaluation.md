---
service: "pingdom"
title: "Uptime Alert Evaluation"
generated: "2026-03-03"
type: flow
flow_name: "uptime-alert-evaluation"
flow_type: scheduled
trigger: "Daily cron task, triggered after daily uptime data collection"
participants:
  - "pingdomServicePortal"
  - "ein_project (ProdCAT portal)"
  - "JSM (Jira Service Management)"
architecture_ref: "dynamic-pingdom-uptime-alert"
---

# Uptime Alert Evaluation

## Summary

The Uptime Alert Evaluation flow checks yesterday's Pingdom uptime data stored in the `pingdom_logs` table against a configurable threshold (default 99%) and creates a JSM (Jira Service Management) P3 alert assigned to the IMOC team for any service tag whose `no_latency_uptime` falls below that threshold. The flow is a guard-and-alert pattern: it first verifies that yesterday's data exists (to prevent premature alerts if the sync has not completed), then evaluates and sends at most one JSM alert per run aggregating all failing tags.

## Trigger

- **Type**: schedule
- **Source**: Daily cron scheduler within `ein_project` `trigger_uptime_alert` task, run after `add_pingdom_uptimes` completes
- **Frequency**: Daily

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `ein_project` (ProdCAT portal) | Orchestrates alert evaluation; queries `pingdom_logs`; creates JSM alert | Internal to `ein_project` |
| `pingdom_logs` database table | Source of stored daily uptime records | Owned by `ein_project` |
| JSM (Jira Service Management) | Receives P3 alert assigned to IMOC team | External (`atlassian_tools.get_jsm_client()`) |

## Steps

1. **Check data availability**: Queries `PingdomUptime.objects.filter(date=yesterday).exists()` to confirm yesterday's collection run has populated the database.
   - From: `trigger_uptime_alert`
   - To: `pingdom_logs` database table
   - Protocol: Django ORM

2. **Skip if no data**: If no records exist for yesterday, returns `status: "skipped"` with a message indicating the sync has not yet completed. No alert is sent.
   - From: `trigger_uptime_alert`
   - To: cron scheduler (return value)
   - Protocol: Direct

3. **Retrieve tag-based uptime data**: Calls `get_tag_based_uptimes(yesterday, yesterday)` to compute averaged uptime metrics per tag for the previous day.
   - From: `trigger_uptime_alert`
   - To: `pingdom_logs` database table (via Django ORM aggregation)
   - Protocol: Django ORM

4. **Filter significant alerts**: Iterates uptime records and selects those where `no_latency_uptime` is below `UPTIME_ALERT_THRESHOLD` (default 99.0%). Validates each record's structure before comparison.
   - From: `trigger_uptime_alert`
   - To: in-memory filter (`_filter_significant_alerts`)
   - Protocol: Direct

5. **Return healthy if no alerts**: If no tags are below threshold, returns `status: "success"` with `alerts_sent: 0`. No JSM call is made.
   - From: `trigger_uptime_alert`
   - To: cron scheduler (return value)
   - Protocol: Direct

6. **Build JSM alert message**: Constructs an alert message (max 130 chars) and a detailed description (max 15000 chars) listing each failing tag with its uptime value and the Pingdom checks URL (`https://my.pingdom.com/app/newchecks/checks`).
   - From: `trigger_uptime_alert`
   - To: in-memory string builder
   - Protocol: Direct

7. **Create JSM alert**: Calls `jsm.create_alert(message, description, priority="P3", responders=[{id: IMOC_TEAM, type: "team"}], source="ProdCAT Uptime Monitor", tags=["uptime", "pingdom", "production"])`.
   - From: `trigger_uptime_alert`
   - To: JSM API (`atlassian_tools.get_jsm_client()`)
   - Protocol: HTTPS REST (Atlassian JSM API)

8. **Return execution metrics**: Reports `alerts_sent`, `services_checked`, `significant_alerts` count, `execution_time`, `query_time`, `notification_failures`, and `threshold`.
   - From: `trigger_uptime_alert`
   - To: cron scheduler (return value / logs)
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| No data for yesterday | Returns `status: "skipped"`; no alert sent | Alert deferred; retry expected on next scheduled run after sync completes |
| No uptime data returned from tag query | Returns `status: "skipped"` | No alert; investigate `ein_project` logs for data collection failures |
| `IMOC_TEAM` setting not configured | Logs error; increments `notification_failures`; does not raise | Alert not created; `notification_failures: 1` returned |
| JSM client raises exception | Logs error with traceback; increments `notification_failures`; returns success with failures noted | Alert not created; requires manual follow-up or re-run |
| Invalid uptime data structure in record | Logs warning; skips that record via `_validate_uptime_data` | Tag excluded from alert evaluation |

## Sequence Diagram

```
CronScheduler -> trigger_uptime_alert: invoke()
trigger_uptime_alert -> pingdom_logs: EXISTS(date=yesterday)
pingdom_logs --> trigger_uptime_alert: true/false
alt no data
  trigger_uptime_alert --> CronScheduler: {status: "skipped"}
end
trigger_uptime_alert -> pingdom_logs: AVG(uptime) GROUP BY tag WHERE date=yesterday
pingdom_logs --> trigger_uptime_alert: [{tag, uptime, no_latency_uptime, response}]
trigger_uptime_alert -> trigger_uptime_alert: filter tags below UPTIME_ALERT_THRESHOLD
alt no alerts
  trigger_uptime_alert --> CronScheduler: {status: "success", alerts_sent: 0}
end
trigger_uptime_alert -> trigger_uptime_alert: build alert message + description
trigger_uptime_alert -> JSM: create_alert(message, description, priority=P3, responders=[IMOC_TEAM])
JSM --> trigger_uptime_alert: {id: alert_id}
trigger_uptime_alert --> CronScheduler: {status: "success", alerts_sent: 1, ...}
```

## Related

- Architecture dynamic view: `dynamic-pingdom-uptime-alert`
- Related flows: [Daily Uptime Data Collection](daily-uptime-collection.md)
