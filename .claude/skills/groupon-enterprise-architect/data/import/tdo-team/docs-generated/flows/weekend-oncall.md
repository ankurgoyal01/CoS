---
service: "tdo-team"
title: "Weekend On-Call Notification"
generated: "2026-03-03"
type: flow
flow_name: "weekend-oncall"
flow_type: scheduled
trigger: "Kubernetes CronJob — Wednesday and Friday at 02:00, 10:00, 17:00 UTC"
participants:
  - "continuumTdoTeamWeekendOncallJob"
architecture_ref: "tdo-team-containers"
---

# Weekend On-Call Notification

## Summary

The Weekend On-Call Notification flow runs three times on Wednesday and Friday (at 02:00, 10:00, and 17:00 UTC) to remind the IMOC team of weekend on-call coverage. It retrieves the weekend on-call schedule from OpsGenie (for both primary and secondary schedules), formats a roster message, and posts it to the IMOC Google Chat space. A complementary `imoc-ooo-weekend` job runs during the weekend itself to notify the Production Google Chat space that IMOC is on-call for emergencies only.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob (`continuumTdoTeamWeekendOncallJob`)
- **Frequency**: Wednesday and Friday at 02:00, 10:00, 17:00 UTC (`0 2,10,17 * * 3,5`)
- **Invocation**: `./cronjobs/weekend-oncall.sh` (Bash shell script)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Weekend Oncall CronJob | Schedule trigger; executes the Bash script | `continuumTdoTeamWeekendOncallJob` |
| OpsGenie API v2 | Source of on-call schedule participants for the weekend window | - |
| Google Chat webhook (IMOC space) | Destination for on-call roster notification (`AAQA6vBYz0U`) | - |

## Steps

1. **Query OpsGenie primary on-call schedule**: The script calls the OpsGenie API to retrieve current on-call participants for the primary IMOC schedule (`1c2e68a5-8acf-4ea5-b1b7-b5f7d36c0c19`) for the upcoming weekend window.
   - From: Weekend Oncall CronJob
   - To: OpsGenie API (`https://api.opsgenie.com/v2/schedules/1c2e68a5-8acf-4ea5-b1b7-b5f7d36c0c19/on-calls`)
   - Protocol: REST (HTTPS, `Authorization: GenieKey {key}` header)

2. **Query OpsGenie secondary on-call schedule**: The script also retrieves participants for the secondary IMOC schedule (`6d34656d-6ccb-4d3c-a674-9611edff860b`).
   - From: Weekend Oncall CronJob
   - To: OpsGenie API (`https://api.opsgenie.com/v2/schedules/6d34656d-6ccb-4d3c-a674-9611edff860b/on-calls`)
   - Protocol: REST (HTTPS, GenieKey)

3. **Resolve user display names**: For each participant returned by OpsGenie (identified by user ID), the script resolves full display names via the OpsGenie Users API.
   - From: Weekend Oncall CronJob
   - To: OpsGenie API (`https://api.opsgenie.com/v2/users/{userId}`)
   - Protocol: REST (HTTPS, GenieKey)

4. **Format on-call roster message**: The script constructs a Google Chat message listing primary and secondary on-call engineers for the weekend window.
   - From: Weekend Oncall CronJob (local)
   - Protocol: n/a

5. **Post roster to IMOC Google Chat space**: The script posts the formatted on-call roster to the IMOC Google Chat space (`AAQA6vBYz0U`) via webhook.
   - From: Weekend Oncall CronJob
   - To: Google Chat webhook (`https://chat.googleapis.com/v1/spaces/AAQA6vBYz0U/messages?...`)
   - Protocol: HTTPS webhook POST (JSON body)

## IMOC OOO Weekend Companion Flow

The `continuumTdoTeamImocOooWeekendJob` runs every 4 hours on Saturday and Sunday (`0 */4 * * 6,0`) and posts a fixed message to the Production Google Chat space (`AAAAOTeTjHg`) stating that IMOC is on-call for emergencies only (SEV1–3 incidents per the definitions document) and providing the `imoc-alerts@groupon.com` paging address.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| OpsGenie API returns empty schedule | Empty roster posted to Google Chat | IMOC team receives notification with no names; may require manual follow-up |
| OpsGenie API returns error | Script logs error; may post partial message | Notification may be incomplete or missing |
| Google Chat webhook POST fails | Script logs error; no retry | On-call roster not delivered to IMOC space |

## Sequence Diagram

```
CronJob -> OpsGenie API: GET /v2/schedules/{primary-schedule-id}/on-calls
OpsGenie API --> CronJob: list of on-call participants (weekend window)
CronJob -> OpsGenie API: GET /v2/schedules/{secondary-schedule-id}/on-calls
OpsGenie API --> CronJob: list of on-call participants
CronJob -> OpsGenie API: GET /v2/users/{userId} (for each participant)
OpsGenie API --> CronJob: user display name
CronJob -> Google Chat webhook (AAQA6vBYz0U): POST on-call roster message
Google Chat --> CronJob: 200 OK
```

## Related

- Architecture container view: `tdo-team-containers`
- Related flows: [Pingdom Shift Report](pingdom-shift-report.md)
- Integration details: [Integrations](../integrations.md)
- Runbook section: [Troubleshooting — Weekend On-Call Not Posted](../runbook.md)
