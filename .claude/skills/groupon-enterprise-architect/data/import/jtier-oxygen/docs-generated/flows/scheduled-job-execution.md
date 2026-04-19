---
service: "jtier-oxygen"
title: "Scheduled Job Execution"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-job-execution"
flow_type: scheduled
trigger: "Quartz cron — every minute (EverywhereJob) and every minute on designated exclusive instance (ExclusiveJob)"
participants:
  - "oxygenHttpApi"
  - "continuumOxygenPostgres"
architecture_ref: "dynamic-oxygen-runtime-flow"
---

# Scheduled Job Execution

## Summary

JTier Oxygen runs two Quartz-scheduled jobs to validate the JTier Quartz bundle and Quartz-on-Postgres persistence. `EverywhereJob` fires on every running instance of the service (no locking), while `ExclusiveJob` fires only on the instance designated as the exclusive scheduler — controlled by the `EXCLUSIVE_MEMBER` environment variable. Both jobs run on a cron expression of `"1 * * * * ?"` (every minute at second 1). Quartz job state is persisted in the Oxygen Postgres database.

## Trigger

- **Type**: Schedule (Quartz cron)
- **Source**: Quartz scheduler embedded in each Oxygen JVM instance; cron expression `"1 * * * * ?"` (fires every minute)
- **Frequency**: Every minute

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Quartz Scheduler (embedded in `continuumOxygenService`) | Triggers jobs based on cron expression; manages exclusive locking via Postgres | `continuumOxygenService` |
| Oxygen Postgres | Stores Quartz scheduler state, job records, and trigger locks | `continuumOxygenPostgres` |

## Steps

### EverywhereJob (runs on all instances)

1. **Cron trigger fires**: At second 1 of every minute, the Quartz scheduler on each Oxygen instance evaluates the `EverywhereTrigger`.
   - From: Quartz scheduler (embedded)
   - To: `EverywhereJob`
   - Protocol: In-process Quartz trigger

2. **Acquire trigger state from Postgres**: Quartz reads/writes trigger state in the Postgres `QRTZ_*` tables to record the last fire time.
   - From: Quartz scheduler
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC (DaaS-managed pool)

3. **Execute job**: `EverywhereJob` runs its business logic (the specific logic is a JTier framework validation routine) on every instance simultaneously.
   - From: Quartz scheduler
   - To: `EverywhereJob` (in-process)

4. **Update trigger state**: Quartz updates the next-fire-time and trigger state in Postgres.
   - From: Quartz scheduler
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC

### ExclusiveJob (runs on designated instance only)

1. **Cron trigger fires**: At second 1 of every minute, the Quartz scheduler on the exclusive instance (where `EXCLUSIVE_MEMBER=true`) evaluates the `ExclusiveTrigger`.
   - From: Quartz scheduler (exclusive instance only)
   - To: `ExclusiveJob`
   - Protocol: In-process Quartz trigger

2. **Acquire distributed lock**: Quartz uses Postgres-backed row locking to ensure only one instance fires the exclusive job across the cluster.
   - From: Quartz scheduler
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC (row-level lock on `QRTZ_LOCKS` table)

3. **Execute job**: `ExclusiveJob` runs on the single designated instance.
   - From: Quartz scheduler
   - To: `ExclusiveJob` (in-process)

4. **Release lock and update state**: Quartz releases the lock and updates trigger state in Postgres.
   - From: Quartz scheduler
   - To: `continuumOxygenPostgres`
   - Protocol: JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Postgres unavailable | Quartz cannot acquire lock or update state | Jobs may fail to fire or fire multiple times on recovery; Quartz JDBC job store handles reconnect |
| `EXCLUSIVE_MEMBER` not set | `ExclusiveJob` does not start (`autoStart: false`) | ExclusiveJob never fires; EverywhereJob unaffected |
| Job execution exception | Quartz catches exception and records misfire | Job reschedules for next trigger interval |

## Sequence Diagram

```
QuartzScheduler -> QuartzScheduler: cron "1 * * * * ?" fires
QuartzScheduler -> continuumOxygenPostgres: SELECT/UPDATE QRTZ_TRIGGERS
continuumOxygenPostgres --> QuartzScheduler: trigger state
QuartzScheduler -> EverywhereJob: execute() [all instances]
EverywhereJob --> QuartzScheduler: complete
QuartzScheduler -> continuumOxygenPostgres: UPDATE next fire time

QuartzScheduler -> continuumOxygenPostgres: LOCK QRTZ_LOCKS (exclusive instance only)
continuumOxygenPostgres --> QuartzScheduler: lock acquired
QuartzScheduler -> ExclusiveJob: execute() [exclusive instance only]
ExclusiveJob --> QuartzScheduler: complete
QuartzScheduler -> continuumOxygenPostgres: RELEASE lock + UPDATE trigger state
```

## Related

- Architecture dynamic view: `dynamic-oxygen-runtime-flow`
- Configuration: [Quartz config in configuration.md](../configuration.md)
- Data store: [Oxygen Postgres — Quartz tables](../data-stores.md)
- Deployment: [Schedule Kubernetes CronJob component](../deployment.md)
