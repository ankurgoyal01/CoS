---
service: "HotzoneGenerator"
title: "Weekly Email Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "weekly-email-dispatch"
flow_type: scheduled
trigger: "Weekly cron on Fridays (15:00 UTC NA, 07:00 UTC EMEA) via weekly_email_run_job"
participants:
  - "continuumHotzoneGeneratorJob"
architecture_ref: "dynamic-hotzoneGenerationFlow"
---

# Weekly Email Dispatch

## Summary

Each Friday, a separate cron entry invokes the job in `weekly_email` run mode using the `weekly_email_run_job` script. In this mode, the job connects directly to the Proximity PostgreSQL database via JDBC to retrieve consumer IDs that are eligible for a weekly proximity email, then iterates over each consumer and POSTs a send-email trigger to the Proximity Notifications API. This flow is separate from and independent of the daily hotzone generation flow.

## Trigger

- **Type**: schedule
- **Source**: `cron/na/weekly_email_run_job` and `cron/emea/weekly_email_run_job` scripts
- **Frequency**: Weekly — NA: every Friday at 15:00 UTC; EMEA: every Friday at 07:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Hotzone Generator Job (`weeklyEmailDispatcher`) | Reads consumer IDs and POSTs email triggers per consumer | `continuumHotzoneGeneratorJob` |
| Proximity PostgreSQL Database | Stores weekly-eligible consumer IDs (read-only access) | `proximityHotzonePostgres` (stub) |
| Proximity Notifications API | Receives per-consumer send-email trigger | stub |

## Steps

1. **Initialise DB connection**: `AppDataConnection` reads `postgres.host`, `postgres.app.user`, `postgres.app.pass`, and `postgres.database` from `AppConfig`. Establishes a JDBC connection to `jdbc:postgresql://{host}/{database}`.
   - From: `weeklyEmailDispatcher`
   - To: Proximity PostgreSQL
   - Protocol: JDBC/PostgreSQL

2. **Query weekly consumer IDs**: Executes a query to retrieve a list of consumer UUIDs eligible for the weekly email from the Proximity database.
   - From: `weeklyEmailDispatcher`
   - To: Proximity PostgreSQL
   - Protocol: JDBC/PostgreSQL

3. **Trigger email per consumer**: For each consumer UUID, sends `POST /v1/proximity/location/hotzone/{consumerId}/send-email?client_id={proximity.clientId}` with body `{}` to the Proximity Notifications API.
   - From: `proximitySyncClient`
   - To: Proximity Notifications API
   - Protocol: HTTPS/JSON

4. **Log result**: Logs `"Email sent"` with the API output on success, or `"Sending weekly email failed."` on exception (exception is caught and logged; iteration continues to the next consumer).

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| JDBC connection fails | Returns empty consumer list via `Collections.EMPTY_LIST` | No emails sent; run completes without error |
| Proximity API send-email call fails for one consumer | Caught and logged; continues to next consumer | That consumer's email is not sent; others continue |
| Empty consumer list | Loop exits immediately | No emails sent; run completes cleanly |

## Sequence Diagram

```
cron -> continuumHotzoneGeneratorJob: Invoke weekly_email_run_job (Friday)
continuumHotzoneGeneratorJob -> ProximityPostgreSQL: JDBC query for weekly consumer IDs
ProximityPostgreSQL --> continuumHotzoneGeneratorJob: List of consumer UUIDs
loop for each consumerId
  continuumHotzoneGeneratorJob -> ProximityAPI: POST /v1/proximity/location/hotzone/{consumerId}/send-email
  ProximityAPI --> continuumHotzoneGeneratorJob: Email dispatch result
end
```

## Related

- Architecture dynamic view: `dynamic-hotzoneGenerationFlow`
- Related flows: [Hotzone Generation (Config Mode)](hotzone-generation.md), [Auto Campaign Generation](auto-campaign-generation.md)
