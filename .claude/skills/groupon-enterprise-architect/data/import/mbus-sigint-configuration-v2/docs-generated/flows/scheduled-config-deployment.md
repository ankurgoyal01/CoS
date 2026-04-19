---
service: "mbus-sigint-configuration-v2"
title: "Scheduled Configuration Deployment"
generated: "2026-03-03"
type: flow
flow_name: "scheduled-config-deployment"
flow_type: scheduled
trigger: "Quartz DeployConfigJob or DeployRescheduleJob cron trigger"
participants:
  - "continuumMbusSigintConfigurationService"
  - "continuumMbusSigintConfigurationDatabase"
  - "Ansible Automation Runtime"
architecture_ref: "components-continuum-mbus-sigint-configuration-service"
---

# Scheduled Configuration Deployment

## Summary

The service automatically deploys Artemis message bus configuration on a per-cluster schedule using Quartz cron jobs. The `DeployRescheduleJob` fires daily (at 03:58 UTC in production) to rebuild the Quartz trigger list from the current `deploy_schedule` database table. When a `DeployConfigJob` trigger fires for a cluster, it renders the Artemis configuration via FreeMarker/StringTemplate templates and deploys it to the target environment by executing the `artemis_config_deploy.sh` script on the Ansible host via SSH.

## Trigger

- **Type**: schedule
- **Source**: Quartz scheduler (`SigintConfigJobScheduler`) — cron `0 58 3 * * ?` for `DeployReschedule` in production
- **Frequency**: Daily (03:58 UTC for reschedule trigger); per-cluster schedules are cron-configurable

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Scheduler Jobs | Fires `DeployRescheduleJob` and `DeployConfigJob` | `mbsc_schedulerJobs` |
| Domain Services | Reads schedules and updates request state | `mbsc_domainServices` |
| Persistence Adapters | Reads deploy_schedule and config data; writes deployment results | `mbsc_persistenceAdapters` |
| Config Rendering Task | Renders Artemis configuration from templates | `mbsc_configRenderingTask` |
| Integration Clients | Executes SSH command to Ansible host | `mbsc_integrationClients` |
| MBus Sigint Configuration Database | Stores schedule and request state | `continuumMbusSigintConfigurationDatabase` |
| Ansible Automation Runtime | Runs `artemis_config_deploy.sh` | External |

## Steps

1. **DeployRescheduleJob fires**: Quartz triggers `DeployRescheduleJob` at `0 58 3 * * ?` (daily 03:58 UTC in production).
   - From: Quartz scheduler
   - To: `mbsc_schedulerJobs` (DeployRescheduleJob)
   - Protocol: Quartz internal

2. **Read current deploy schedules**: Reads all enabled entries from the `deploy_schedule` table to determine which cluster/environment pairs need scheduled deployments.
   - From: `mbsc_schedulerJobs`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

3. **Rebuild Quartz triggers**: Creates or updates Quartz `DeployConfigJob` triggers for each cluster/environment with the configured cron expression.
   - From: `mbsc_schedulerJobs`
   - To: Quartz scheduler (PostgreSQL job store)
   - Protocol: Quartz / JDBC

4. **DeployConfigJob fires**: On the cluster-specific cron schedule, the `DeployConfigJob` executes for a specific `clusterId`/`environmentType` pair.
   - From: Quartz scheduler
   - To: `mbsc_schedulerJobs` (DeployConfigJob)
   - Protocol: Quartz internal

5. **Fetch configuration data**: Reads the full cluster configuration — destinations, diverts, user credentials, access permissions, redelivery settings — from PostgreSQL for the target environment.
   - From: `mbsc_schedulerJobs`
   - To: `mbsc_persistenceAdapters` -> `continuumMbusSigintConfigurationDatabase`
   - Protocol: JDBC

6. **Render Artemis configuration**: `mbsc_configRenderingTask` renders the configuration using FreeMarker or StringTemplate templates to produce the Ansible-compatible output.
   - From: `mbsc_schedulerJobs`
   - To: `mbsc_configRenderingTask`
   - Protocol: Direct

7. **Execute SSH deployment command**: Integration clients SSH to the Ansible host and run `artemis_config_deploy.sh #CLUSTER# #ENVIRONMENT#`.
   - From: `mbsc_configRenderingTask` -> `mbsc_integrationClients`
   - To: Ansible Automation Runtime
   - Protocol: SSH

8. **Record deployment result**: On success or failure, domain services update the request/config state. For scheduled deployments not linked to a pending request, errors are logged.
   - From: `mbsc_integrationClients`
   - To: `mbsc_domainServices` -> `mbsc_persistenceAdapters`
   - Protocol: Direct / JDBC

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Ansible SSH unreachable | SSH command returns non-zero exit or timeout | Deployment recorded as failed; logged; Quartz misfireThreshold: 5000ms before retry policy applies |
| `deploy_schedule` table empty | No triggers created | `DeployConfigJob` never fires; no deployment occurs |
| Quartz misfire | misfireThreshold 5000ms — job skipped or retried based on Quartz misfire policy | Deployment may be skipped for the interval; next scheduled trigger will run |
| Config rendering failure | Template error in `mbsc_configRenderingTask` | Deployment not triggered; exception logged; Ansible not called |

## Sequence Diagram

```
QuartzScheduler        -> mbsc_schedulerJobs  : DeployRescheduleJob fires (03:58 UTC)
mbsc_schedulerJobs     -> mbsc_persistenceAdapters : read deploy_schedule table
mbsc_persistenceAdapters -> DB               : SELECT * FROM deploy_schedule WHERE enabled=true
DB                     --> mbsc_persistenceAdapters : schedule rows
mbsc_schedulerJobs     -> QuartzScheduler    : rebuild DeployConfigJob triggers per cron
QuartzScheduler        -> mbsc_schedulerJobs  : DeployConfigJob fires (cluster cron)
mbsc_schedulerJobs     -> mbsc_persistenceAdapters : read cluster config (destinations, diverts, creds)
mbsc_schedulerJobs     -> mbsc_configRenderingTask : render Artemis config
mbsc_configRenderingTask -> mbsc_integrationClients : invoke SSH deploy
mbsc_integrationClients -> AnsibleRuntime   : SSH artemis_config_deploy.sh CLUSTER ENV
AnsibleRuntime         --> mbsc_integrationClients : exit code
mbsc_integrationClients -> mbsc_persistenceAdapters : update deployment result
```

## Related

- Architecture dynamic view: `components-continuum-mbus-sigint-configuration-service`
- Related flows: [Change Request Lifecycle](change-request-lifecycle.md), [Deploy Schedule Management](deploy-schedule-management.md)
