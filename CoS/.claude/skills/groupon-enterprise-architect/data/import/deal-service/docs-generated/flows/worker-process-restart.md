---
service: "deal-service"
title: "Worker Process Restart"
generated: "2026-03-02"
type: flow
flow_name: "worker-process-restart"
flow_type: continuous
trigger: "Worker process exits (crash or normal termination)"
participants:
  - "continuumDealService"
  - "continuumDealServiceRedisLocal"
architecture_ref: "dynamic-worker-process-restart"
---

# Worker Process Restart

## Summary

Deal Service uses a master/worker process model. The master process (`app.coffee` entry point) forks a child worker process that runs the deal processing loop. If the worker crashes or exits for any reason, the master process detects the exit event and automatically forks a new worker. Because all in-flight job state is held in the Redis `processing_cloud` and `nodejs_deal_scheduler` sorted sets (not in worker memory), no deal data is lost on worker restart. This design provides self-healing behavior without external process supervision.

## Trigger

- **Type**: event
- **Source**: Worker process `exit` event detected by the master process
- **Frequency**: On worker crash or termination; should be rare in normal operation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Deal Service Master Process | Monitors worker; forks replacement on exit | `continuumDealService` |
| Deal Service Worker Process | Runs the deal processing loop; may exit on crash | `continuumDealService` |
| Deal Service Redis (Local) | Holds durable job state in `processing_cloud` and `nodejs_deal_scheduler` | `continuumDealServiceRedisLocal` |

## Steps

1. **Master forks initial worker**: On service startup, the master process calls Node.js `child_process.fork()` (or equivalent) to spawn the worker.
   - From: `continuumDealService` (master)
   - To: `continuumDealService` (worker)
   - Protocol: Node.js process fork

2. **Master registers exit listener**: The master registers an `exit` (or `close`) event handler on the child process reference.
   - From: `continuumDealService` (master)
   - To: child process object (in-process Node.js)
   - Protocol: in-process Node.js EventEmitter

3. **Worker runs processing loop**: The worker process executes the [Deal Processing Cycle](deal-processing-cycle.md) indefinitely. All job identifiers are persisted in Redis sorted sets, not in worker memory.
   - From: `continuumDealService` (worker)
   - To: `continuumDealServiceRedisLocal`, upstream APIs, data stores
   - Protocol: Redis / REST / Sequelize / MongoDB

4. **Worker exits (crash or normal)**: An unhandled exception, OOM kill, or deliberate termination causes the worker process to exit. The exit event fires on the master's child process handle.
   - From: `continuumDealService` (worker)
   - To: `continuumDealService` (master, via OS process exit)
   - Protocol: OS process signal / Node.js child process event

5. **Master detects exit**: The master's `exit` listener fires with the exit code.
   - From: OS / Node.js runtime
   - To: `continuumDealService` (master event handler)
   - Protocol: in-process Node.js EventEmitter

6. **Master logs restart**: The exit event and any exit code are logged via Lumber (structured JSON), which Filebeat ships to Splunk. Rapt may send a pod restart alert to the `mis-deployment` Slack channel.
   - From: `continuumDealService` (master)
   - To: log output / Splunk
   - Protocol: structured logging

7. **Master forks new worker**: The master immediately forks a new worker process, which initializes fresh connections and re-enters the processing loop.
   - From: `continuumDealService` (master)
   - To: `continuumDealService` (new worker)
   - Protocol: Node.js process fork

8. **New worker resumes processing**: The new worker connects to Redis and picks up any deal IDs remaining in `processing_cloud` and `nodejs_deal_scheduler`, resuming exactly where the previous worker left off.
   - From: `continuumDealService` (new worker)
   - To: `continuumDealServiceRedisLocal`
   - Protocol: Redis

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Worker crashes repeatedly in a tight loop | Kubernetes liveness probe (`echo live`) eventually fails after 30s initial delay + 15s period; Kubernetes kills and restarts the pod | Pod is restarted by Kubernetes; fresh master+worker launched |
| Redis unavailable when new worker starts | Worker cannot connect; logs error; exits; master re-forks | Crash loop until Redis becomes available; Kubernetes liveness probe will eventually cycle the pod |
| Master process itself crashes | Kubernetes pod exits; Kubernetes restarts the pod per restart policy | Fresh pod with master+worker launched |

## Sequence Diagram

```
Master -> Worker: fork() on startup
Worker -> Worker: run processing loop (indefinitely)
--- (crash event) ---
Worker -> Master: process exit event (exit code)
Master -> Splunk: log worker exit
Master -> Worker2: fork() new worker
Worker2 -> RedisLocal: connect + resume ZRANGEBYSCORE processing_cloud
Worker2 -> Worker2: resume processing loop
```

## Related

- Architecture dynamic view: `dynamic-worker-process-restart`
- Related flows: [Deal Processing Cycle](deal-processing-cycle.md), [Dynamic Configuration Reload](dynamic-configuration-reload.md)
