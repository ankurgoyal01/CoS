---
service: "momo-config"
title: "Adaptive Delivery Control"
generated: "2026-03-03"
type: flow
flow_name: "adaptive-delivery-control"
flow_type: asynchronous
trigger: "Remote MX rejection rate exceeding suspension threshold for a binding/domain pair"
participants:
  - "continuumMtaEmailService"
  - "continuumMtaTransService"
  - "metricsStack"
architecture_ref: "dynamic-outbound-mail-flow"
---

# Adaptive Delivery Control

## Summary

The adaptive delivery control flow governs how the MTA clusters automatically throttle and suspend outbound delivery to specific ISPs when rejection rates exceed configured thresholds. Ecelerity's adaptive module monitors per-binding/domain delivery outcomes continuously and adjusts connection counts and message rates to protect sender reputation. State is persisted to LevelDB so that suspension windows survive process restarts. Adaptive delivery metrics are emitted to `metricsStack`.

## Trigger

- **Type**: event (delivery outcome threshold breach)
- **Source**: Ecelerity adaptive module detecting rejection rate exceeding `adaptive_rejection_rate_suspension_percentage` for a binding/domain combination
- **Frequency**: Continuous; evaluated on every delivery event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| MTA Email Cluster | Monitors delivery outcomes for campaign/transactional outbound | `continuumMtaEmailService` |
| MTA Trans Cluster | Primary adaptive delivery enforcement; applies throttle and suspension per binding/domain | `continuumMtaTransService` |
| MTA SMTP Cluster | Adaptive delivery enforcement for authenticated SMTP traffic (25% threshold) | `continuumMtaSmtpService` |
| LevelDB Adaptive Backstore | Persists per-binding/domain adaptive state | Internal (owned by `continuumMtaTransService`) |
| Remote Recipient MX | Issues 4xx/5xx responses that trigger adaptive adjustments | External |
| Metrics Stack | Receives adaptive delivery and throttle metrics | `metricsStack` |

## Steps

1. **Monitors delivery outcomes**: Ecelerity adaptive module (`msys/adaptive.lua` loaded via `scriptlet "adaptive"`) tracks per-binding/domain delivery, transient failure, and permanent failure events in real time
   - From: `continuumMtaTransService`
   - To: `continuumMtaTransService` (internal adaptive module)
   - Protocol: direct

2. **Evaluates rejection rate threshold**: Computes rolling rejection rate for each binding/domain pair; compares against `adaptive_rejection_rate_suspension_percentage` (50% for email/trans clusters, 25% for SMTP cluster)
   - From: `continuumMtaTransService`
   - To: `continuumMtaTransService` (internal)
   - Protocol: direct

3. **Applies domain-specific throttle overrides**: Checks configured per-domain profiles in `domains.conf` for static throttle limits before adaptive suspension (e.g., `qq.com`: `Max_Outbound_Connections = 1`, `Outbound_Throttle_Messages = 5`; `gmx.de`/`web.de`: `Max_Outbound_Connections = 9`, `outbound_throttle_messages = 60/20`; `gmx.net`: `Outbound_Throttle_Connections = 1331/900`)
   - From: `continuumMtaTransService`
   - To: `continuumMtaTransService` (internal config)
   - Protocol: direct

4. **Suspends binding/domain pair**: When threshold is breached, adaptive module suspends delivery for `adaptive_default_suspension = "1 hours"`; suspension state written to LevelDB at `/opt/msys/leveldb/adaptive.leveldb`; `Binding_Domain_Cache_Size = 5000000` entries cached in memory
   - From: `continuumMtaTransService`
   - To: LevelDB Adaptive Backstore
   - Protocol: direct (file I/O)

5. **Queues messages during suspension**: Messages addressed to the suspended binding/domain pair remain in the on-disk spool at `/var/spool/ecelerity`; no delivery attempts are made during the suspension window
   - From: `continuumMtaTransService`
   - To: Ecelerity spool (disk)
   - Protocol: direct

6. **Applies adaptive sweep overrides**: Domain-level and sweep-level override profiles from `adaptive_sweep.conf` and `adaptive_domains.conf` allow manual tuning of suspension thresholds and recovery behavior per domain; `adaptive_overrides` Lua script loaded via `scriptlet`
   - From: `continuumMtaTransService`
   - To: `continuumMtaTransService` (internal)
   - Protocol: direct

7. **Resumes delivery after suspension expires**: After `adaptive_default_suspension = "1 hours"`, the adaptive module lifts the suspension; delivery resumes at reduced rates; connection counts and message rates are gradually restored based on delivery success
   - From: LevelDB Adaptive Backstore
   - To: `continuumMtaTransService`
   - Protocol: direct

8. **Emits adaptive metrics**: Throttle state, suspension events, and delivery rate counters pushed to `metricsStack`
   - From: `continuumMtaTransService`
   - To: `metricsStack`
   - Protocol: Metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LevelDB write failure | Adaptive state kept in memory; survives until process restart | Risk of losing suspension state on restart |
| Permanent remote MX failure (5xx) | Logged as permanent failure; bounce written; message removed from queue | In-band bounce record to `loggingStack` |
| Transient remote MX failure (4xx) | Message retried after `Retry_Interval = 1200` seconds | Retry loop until `Message_Expiration` (79201s email, 259200s trans) |
| Host failure | `Host_Failure_Retry = 120` seconds before retrying failed host | Brief host-level backoff |
| Memory pressure during suspension | Ecelerity reduces intake at `Memory_Goal = 90%`; stops at `Memory_HWM = 95%` | Injection throttled; spool provides buffering |

## Sequence Diagram

```
continuumMtaTransService -> RemoteMX: SMTP delivery attempt
RemoteMX --> continuumMtaTransService: 4xx/5xx rejection
continuumMtaTransService -> continuumMtaTransService: Adaptive module evaluates rejection rate
continuumMtaTransService -> LevelDB: Write suspension state for binding/domain
continuumMtaTransService -> metricsStack: Emit adaptive suspension metric
continuumMtaTransService -> Spool: Queue messages during suspension window
LevelDB --> continuumMtaTransService: Suspension expired (1 hour)
continuumMtaTransService -> RemoteMX: Resume SMTP delivery at reduced rate
```

## Related

- Architecture dynamic view: `dynamic-outbound-mail-flow`
- Related flows: [Outbound Mail Delivery](outbound-mail-delivery.md)
