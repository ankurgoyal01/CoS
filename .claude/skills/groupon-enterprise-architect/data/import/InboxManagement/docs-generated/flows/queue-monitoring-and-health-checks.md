---
service: "inbox_management_platform"
title: "Queue Monitoring and Health Checks"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "queue-monitoring-and-health-checks"
flow_type: scheduled
trigger: "Polling schedule configured in the Queue Monitor daemon"
participants:
  - "inbox_queueMonitor"
  - "inbox_configAndStateAccess"
  - "continuumInboxManagementRedis"
  - "continuumInboxManagementPostgres"
architecture_ref: "dynamic-inbox-core-coordination"
---

# Queue Monitoring and Health Checks

## Summary

The queue monitoring flow is a scheduled background process that runs inside `inbox_queueMonitor` to continuously measure the health of the calc and dispatch queues in Redis. At each polling interval, it reads queue depths and processing metadata, emits metrics via `arpnetworking-metrics-client`, and provides the operational signals used by alerting infrastructure to detect backlog buildup or daemon stalls. The health check endpoint at `/grpn/healthcheck` provides a synchronous liveness signal for Kubernetes probes.

## Trigger

- **Type**: schedule
- **Source**: `inbox_queueMonitor` daemon internal polling timer
- **Frequency**: Configurable polling interval (defined in application.conf); typically seconds to sub-minute

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Queue Monitor | Polls queue depths and emits health metrics | `inbox_queueMonitor` |
| Config and State Access | Provides access to queue metadata and state | `inbox_configAndStateAccess` |
| Inbox Management Redis | Authoritative source of current queue depths | `continuumInboxManagementRedis` |
| Inbox Management Postgres | Source of runtime config including alert thresholds | `continuumInboxManagementPostgres` |

## Steps

1. **Timer fires**: `inbox_queueMonitor` polling timer triggers a monitoring cycle.
   - From: Daemon internal scheduler
   - To: `inbox_queueMonitor`
   - Protocol: Internal

2. **Read queue state metadata**: Queue Monitor reads queue metadata via `inbox_configAndStateAccess`.
   - From: `inbox_queueMonitor`
   - To: `inbox_configAndStateAccess`
   - Protocol: Internal

3. **Query calc queue depth**: `inbox_configAndStateAccess` queries Redis for the current depth of the calc queue (sorted set cardinality).
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

4. **Query dispatch queue depth**: `inbox_configAndStateAccess` queries Redis for the current depth of the dispatch queue.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementRedis`
   - Protocol: Redis

5. **Read alert thresholds**: Queue Monitor reads configured alert thresholds from Postgres via `inbox_configAndStateAccess`.
   - From: `inbox_configAndStateAccess`
   - To: `continuumInboxManagementPostgres`
   - Protocol: JDBC

6. **Emit queue depth metrics**: Queue Monitor emits `calc_queue_depth` and `dispatch_queue_depth` gauge metrics via `arpnetworking-metrics-client`.
   - From: `inbox_queueMonitor`
   - To: Metrics sink
   - Protocol: arpnetworking-metrics-client

7. **Health check endpoint responds**: The Admin UI's `inbox_adminApi` serves `/grpn/healthcheck` on demand, providing a synchronous HTTP liveness signal to Kubernetes probes.
   - From: Kubernetes liveness probe
   - To: `inbox_adminApi` at `GET /grpn/healthcheck`
   - Protocol: REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Redis unavailable during depth query | Error logged; metric not emitted for this cycle | Gap in metrics; alerting may not fire; Redis health alert fires separately |
| Postgres unavailable during threshold read | Last known thresholds used; error logged | Monitoring continues with potentially stale thresholds |
| Metrics sink unavailable | Metric emit fails; error logged | Gap in monitoring visibility; no user-facing impact |
| Health check endpoint unresponsive | Kubernetes marks pod as unhealthy | Kubernetes restarts the pod |

## Sequence Diagram

```
DaemonTimer -> inbox_queueMonitor: Polling interval fires
inbox_queueMonitor -> inbox_configAndStateAccess: Read queue/state metadata
inbox_configAndStateAccess -> continuumInboxManagementRedis: ZCARD calc_queue (Redis)
continuumInboxManagementRedis --> inbox_configAndStateAccess: calc_queue depth
inbox_configAndStateAccess -> continuumInboxManagementRedis: ZCARD dispatch_queue (Redis)
continuumInboxManagementRedis --> inbox_configAndStateAccess: dispatch_queue depth
inbox_queueMonitor -> inbox_configAndStateAccess: Read alert thresholds
inbox_configAndStateAccess -> continuumInboxManagementPostgres: Query threshold config (JDBC)
inbox_queueMonitor -> MetricsSink: Emit calc_queue_depth gauge
inbox_queueMonitor -> MetricsSink: Emit dispatch_queue_depth gauge
KubernetesProbe -> inbox_adminApi: GET /grpn/healthcheck (HTTP)
inbox_adminApi --> KubernetesProbe: 200 OK
```

## Related

- Architecture dynamic view: `dynamic-inbox-core-coordination`
- Related flows: [Calculation Coordination Workflow](calculation-coordination-workflow.md), [Dispatch Scheduling and Send Publication](dispatch-scheduling-and-send-publication.md)
- See also: [Runbook](../runbook.md) for alert definitions and troubleshooting, [API Surface](../api-surface.md) for `/grpn/healthcheck` details
