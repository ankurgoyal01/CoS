---
service: "client-id"
title: "Scheduled Rate Limit Change"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-rate-limit-change"
flow_type: scheduled
trigger: "Internal background executor polls active schedules"
participants:
  - "continuumClientIdService"
  - "continuumClientIdScheduler"
  - "continuumClientIdPersistence"
  - "continuumClientIdDatabase"
architecture_ref: "dynamic-continuum-client-id"
---

# Scheduled Rate Limit Change

## Summary

Client ID Service supports scheduled, time-bounded changes to token and service-token rate limits. An operator creates a schedule record specifying a token, service, temporary rate limits, and a start/end window. A background executor (`ScheduledChangeHandler`) periodically polls active schedules and applies the temporary limits at `startTime` and reverts them at `endTime`. This allows temporary rate-limit bumps for known traffic spikes (e.g., promotional events) without manual intervention at the time of the change.

## Trigger

- **Type**: schedule (internal executor)
- **Source**: `ScheduledChangeHandler` (Scheduled Executor component within `continuumClientIdService`)
- **Frequency**: Periodic (executor interval configured via jtier scheduled task framework)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator (admin) | Creates the schedule record in advance via management UI | External actor |
| Scheduled Change Handler | Background executor that applies and reverts rate-limit changes | `continuumClientIdScheduler` |
| Persistence Layer | Reads schedules; updates token rate-limit columns and schedule state | `continuumClientIdPersistence` |
| MySQL Primary | Source of schedule records; target for rate-limit updates | `continuumClientIdDatabase` |

## Steps

### Phase 1 — Schedule Creation (synchronous, operator-driven)

1. **Operator creates schedule**: Operator submits `POST /schedules` with `tokenValue`, `serviceName`, `tempClientLimit`, `tempIPLimit`, `startTime`, `endTime`, and a description. The `originalClientLimit` and `originalIPLimit` are read from the current service-token record and stored in the schedule for revert.
   - From: Operator browser
   - To: `continuumClientIdApiResources`
   - Protocol: REST (HTTP)

2. **Persist schedule record**: Persistence Layer inserts a record into the `schedules` table with `status = ACTIVE` and `started = 0`.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

### Phase 2 — Rate Limit Apply (scheduled)

3. **Executor polls active schedules**: `ScheduledChangeHandler.run()` calls `scheduleDao.getByStatus(ACTIVE)` to load all active, not-yet-started schedules.
   - From: `continuumClientIdScheduler`
   - To: `continuumClientIdPersistence` → `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

4. **Evaluates start window**: For each schedule where `started == 0` and `startTime` is not in the future, `ScheduleChangeHelper.makeRateLimitChange()` is called.
   - From: `continuumClientIdScheduler`
   - To: `continuumClientIdPersistence`
   - Protocol: In-process

5. **Applies temporary rate limits**: Persistence Layer updates `api_service_tokens.client_rate_limit` and `ip_rate_limit` to the temporary values for the matching service-token record. Updates `schedules.started = 1`.
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

### Phase 3 — Rate Limit Revert (scheduled)

6. **Executor evaluates end window**: On a subsequent executor cycle, for schedules where `started == 1` and `endTime` is not in the future, `ScheduleChangeHelper.revertRateLimitChange()` is called.
   - From: `continuumClientIdScheduler`
   - To: `continuumClientIdPersistence`
   - Protocol: In-process

7. **Reverts original rate limits**: Persistence Layer updates `api_service_tokens.client_rate_limit` and `ip_rate_limit` back to the `originalClientLimit` / `originalIPLimit` values stored in the schedule. Updates `schedules.status = SUSPENDED` (deactivates the schedule).
   - From: `continuumClientIdPersistence`
   - To: `continuumClientIdDatabase`
   - Protocol: JDBI / MySQL

8. **API Proxy picks up changes**: On the next API Proxy sync cycle, the `updated_at` change on `api_service_tokens` causes the token to appear in the incremental sync response, updating the rate-limit enforcement in API Proxy.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL unavailable during apply/revert | Exception thrown in executor run; logged by jtier scheduler | Rate-limit change is not applied; executor retries on next cycle |
| Schedule created with `startTime` in the past | Executor applies change immediately on next poll cycle (condition: `!startTime.isAfterNow()`) | Change applies on the next executor tick |
| Operator manually disables schedule before startTime | `POST /schedules/{id}/disable` sets `status = SUSPENDED` | Executor skips the schedule on next poll |

## Sequence Diagram

```
Operator -> continuumClientIdApiResources: POST /schedules (tokenValue, tempLimits, startTime, endTime)
continuumClientIdApiResources -> continuumClientIdPersistence: insertSchedule(schedule)
continuumClientIdPersistence -> continuumClientIdDatabase: INSERT INTO schedules (started=0, status=ACTIVE)

[At startTime — background executor]
continuumClientIdScheduler -> continuumClientIdPersistence: getSchedulesByStatus(ACTIVE)
continuumClientIdPersistence -> continuumClientIdDatabase: SELECT * FROM schedules WHERE status=ACTIVE
continuumClientIdScheduler -> continuumClientIdPersistence: makeRateLimitChange(schedule)
continuumClientIdPersistence -> continuumClientIdDatabase: UPDATE api_service_tokens SET client_rate_limit=tempLimit
continuumClientIdPersistence -> continuumClientIdDatabase: UPDATE schedules SET started=1

[At endTime — background executor]
continuumClientIdScheduler -> continuumClientIdPersistence: revertRateLimitChange(schedule)
continuumClientIdPersistence -> continuumClientIdDatabase: UPDATE api_service_tokens SET client_rate_limit=originalLimit
continuumClientIdPersistence -> continuumClientIdDatabase: UPDATE schedules SET status=SUSPENDED
```

## Related

- Architecture dynamic view: No dynamic views modeled yet
- Related flows: [API Proxy Token Sync](api-proxy-token-sync.md), [Client and Token Registration](client-token-registration.md)
