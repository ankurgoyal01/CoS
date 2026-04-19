---
service: "amsJavaScheduler"
title: "Scheduler Startup and Schedule Loading"
generated: "2026-03-03"
type: flow
flow_name: "scheduler-startup"
flow_type: scheduled
trigger: "Kubernetes CronJob launches the container pod"
participants:
  - "continuumAmsJavaScheduler"
  - "continuumAmsSchedulerScheduleStore"
architecture_ref: "components-continuum-ams-java-scheduler"
---

# Scheduler Startup and Schedule Loading

## Summary

When the Kubernetes CronJob controller triggers a pod for any of the five CronJob components (bcookie, universal, users, sadintegrationcheck, usersbatchsad), the JVM starts, the Scheduler Bootstrap initializes the application, and the Schedule Definition Loader reads the appropriate cron schedule file for the active environment and realm. Each line in the schedule file is parsed into a `(cron-expression, action-class)` pair and registered with the `cron4j` scheduler engine. The Action Dispatchers then execute the bound action immediately (or at the cron trigger time within the embedded scheduler), dispatching work to the appropriate runner component.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob controller fires at the `jobSchedule` defined in the Helm values for each component (e.g., `0 2 * * *` for universal NA production)
- **Frequency**: Nightly (once per day per component per region)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes CronJob | Launches the pod at the scheduled time | External orchestration |
| Scheduler Bootstrap | Reads env vars (`ACTIVE_ENV`, `RUN_CONFIG`, `CLASS_TO_RUN`), initializes JVM config, sets timezone, starts lifecycle | `amsScheduler_bootstrap` |
| Schedule Definition Loader | Reads the schedule file from the configured path, parses cron lines, binds action classes | `amsScheduler_scheduleLoader` |
| Schedule Store (text files) | Provides the cron schedule definition file | `continuumAmsSchedulerScheduleStore` |
| Action Dispatchers | Receives bound runnable actions and dispatches to the correct runner based on `AMS_TYPE` / `CLASS_TO_RUN` | `amsScheduler_actionDispatchers` |

## Steps

1. **Pod Start**: Kubernetes CronJob creates the pod and executes the entrypoint (`/docker-entrypoint.sh`)
   - From: Kubernetes CronJob controller
   - To: `continuumAmsJavaScheduler` pod
   - Protocol: Kubernetes pod lifecycle

2. **Environment Initialization**: Scheduler Bootstrap reads environment variables (`ACTIVE_ENV`, `RUN_CONFIG`, `CLASS_TO_RUN`, `TIME_OF_RUN`) and initializes the application configuration
   - From: `amsScheduler_bootstrap`
   - To: Environment / config system
   - Protocol: Direct (JVM system properties and env vars)

3. **Schedule File Load**: Schedule Definition Loader opens the file at the path specified by `RUN_CONFIG` (or the default bundled schedule path) and reads each line
   - From: `amsScheduler_scheduleLoader`
   - To: `continuumAmsSchedulerScheduleStore`
   - Protocol: File I/O

4. **Action Binding**: Each parsed `<cron-expression>:<FQCN>` line is instantiated as a runnable `Task` and registered with the `cron4j` `Scheduler` instance
   - From: `amsScheduler_scheduleLoader`
   - To: `amsScheduler_actionDispatchers`
   - Protocol: Direct (in-process)

5. **Dispatcher Execution**: The Action Dispatchers resolve the job type from `AMS_TYPE` or `CLASS_TO_RUN` and invoke the appropriate runner component (SAD Materialization, Users Batch, SAD Integrity, or EDW Feedback)
   - From: `amsScheduler_actionDispatchers`
   - To: appropriate runner (`amsScheduler_sadMaterialization`, `amsScheduler_usersBatch`, `amsScheduler_sadIntegrity`, or `amsScheduler_edwFeedback`)
   - Protocol: Direct (in-process)

6. **Pod Exit**: After the runner completes, the JVM exits; Kubernetes records the job completion status
   - From: `continuumAmsJavaScheduler` pod
   - To: Kubernetes CronJob controller
   - Protocol: Kubernetes pod exit code

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Schedule file not found | JVM exception on file read; startup fails | Pod exits with non-zero code; Kubernetes records job failure; next scheduled run retries |
| Invalid cron expression in schedule file | `cron4j` parsing exception | Startup fails; pod exits with error; operator must fix the schedule file and redeploy |
| `CLASS_TO_RUN` class not found | `ClassNotFoundException` at dispatch time | Pod exits with error; check `CLASS_TO_RUN` env var and JAR contents |
| Config file (`RUN_CONFIG`) missing | Application config exception | Pod exits with error; verify `RUN_CONFIG` path and mounted ConfigMap/volume |

## Sequence Diagram

```
KubernetesCronJob -> AmsJavaScheduler: Launch pod (jobSchedule trigger)
AmsJavaScheduler -> AmsJavaScheduler: Bootstrap reads ACTIVE_ENV, RUN_CONFIG, CLASS_TO_RUN
AmsJavaScheduler -> ScheduleStore: Load schedule file from RUN_CONFIG path
ScheduleStore --> AmsJavaScheduler: Return cron lines (expression:FQCN)
AmsJavaScheduler -> AmsJavaScheduler: Bind actions to cron4j scheduler
AmsJavaScheduler -> ActionDispatcher: Dispatch to runner (by AMS_TYPE)
ActionDispatcher -> Runner: Execute job logic (SAD/Users/Integrity/EDW)
Runner --> AmsJavaScheduler: Job complete
AmsJavaScheduler -> KubernetesCronJob: Pod exits (success/failure code)
```

## Related

- Architecture dynamic view: `dynamic-ams-scheduler-sad-amsScheduler_sadMaterialization`
- Related flows: [SAD Materialization](sad-materialization.md), [EDW Feedback Push](edw-feedback-push.md), [SAD Integrity Check](sad-integrity-check.md)
