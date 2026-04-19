---
service: "amsJavaScheduler"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

AMS Java Scheduler has one primary internal dependency (`continuumAudienceManagementService`) and three external infrastructure dependencies (YARN ResourceManager, EDW Feedback Host over SSH, and an SMTP relay for alerting). All dependencies are outbound — the scheduler initiates all calls; nothing calls back into it. The service has no inbound consumers at the API level; it is invoked solely by the Kubernetes CronJob engine.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| YARN ResourceManager | HTTP (REST) | Query queue capacity before launching new-flow SAD jobs | no | `hadoopYarnResourceManager` (stub) |
| EDW Feedback Host | SSH | Execute remote EDW feedback push scripts to transfer published audience data to Teradata | yes | `hadoopEdwFeedbackHost` (stub) |
| SMTP Notification Relay | SMTP | Send operational alert emails for process anomalies (e.g., unverified SADs, process-down) | no | `smtpNotificationRelay` (stub) |

### YARN ResourceManager Detail

- **Protocol**: HTTP REST
- **Base URL / SDK**: Configured via application config; accessed through `amsScheduler_yarnCapacity` (`YarnClient` component)
- **Auth**: Not explicitly documented; internal cluster authentication assumed
- **Purpose**: The SAD Materialization Runner queries YARN queue usage to determine safe parallelism before launching new-flow audience jobs. This prevents Hadoop queue overload.
- **Failure mode**: If YARN is unreachable, capacity-constrained job launches may be skipped or fallback to a default parallelism limit
- **Circuit breaker**: No evidence found

### EDW Feedback Host Detail

- **Protocol**: SSH (keyless SSH via JSch library `com.jcraft:jsch:0.1.52`)
- **Base URL / SDK**: Remote host address configured per environment; accessed through `amsScheduler_sshEdwExecutor` (`EdwFeedbackOverSsh` / `KeylessSshCallWrapper`)
- **Auth**: Keyless SSH (host-level trust; no password in config)
- **Purpose**: After retrieving published audiences from the AMS API, the EDW Feedback Runner executes remote shell commands on the EDW Feedback Host to push audience data to the Teradata Warehouse
- **Failure mode**: SSH connection failures cause EDW feedback push to fail for that scheduled run; no automatic retry is documented beyond the next scheduled execution
- **Circuit breaker**: No evidence found

### SMTP Notification Relay Detail

- **Protocol**: SMTP (via `org.apache.commons:commons-email:1.4`)
- **Base URL / SDK**: Configured via application config; used by `amsScheduler_alerting` (`EmailUtil` component)
- **Auth**: Not documented; internal relay assumed
- **Purpose**: Sends operational alert emails to `audience-eng@groupon.com` (soft alerts) and `audience_service@groupon.pagerduty.com` (hard PagerDuty pages) for anomalies
- **Failure mode**: Email delivery failure is non-critical; a failed alert does not stop job execution
- **Circuit breaker**: No evidence found

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Audience Management Service (AMS) | HTTP/JSON (REST) | SAD search, SAI creation, users-batch SAD API, published-audience retrieval for EDW feedback | `continuumAudienceManagementService` |

### Audience Management Service (AMS) Detail

- **Protocol**: HTTP/JSON REST
- **Base URL / SDK**: Configured per environment via `RUN_CONFIG` YAML; accessed through `amsScheduler_amsRestClient` (`AMSRestClient` component), with `jersey-client` and `okhttp` HTTP clients and `AudienceManagementWorkFlowAPI:4.6.6` as the primary client library
- **Auth**: Internal service-to-service; specific token mechanism not explicitly documented
- **Purpose**: All four runner components (SAD Materialization, Users Batch, SAD Integrity, EDW Feedback) call AMS APIs. Operations include: searching Scheduled Audience Definitions, creating Scheduled Audience Instances, invoking users-batch endpoints, checking SAD staleness, resetting materialization timestamps, and retrieving published audiences
- **Failure mode**: AMS unavailability causes the scheduled job run to fail; the next Kubernetes CronJob execution retries at the next scheduled interval
- **Circuit breaker**: No evidence found

## Consumed By

> Upstream consumers are tracked in the central architecture model. At the API level, no other service consumes AMS Java Scheduler — it is invoked only by the Kubernetes CronJob controller.

## Dependency Health

The legacy `scheduler_proc_monitor.py` script (on-premise only) monitors whether the Java scheduler process is alive, sends a PagerDuty alert if it is not detected, and attempts an automatic restart. In cloud deployments, Kubernetes CronJob and pod health probes (`/bin/true` exec probes) replace this script. No HTTP-level health checks or circuit breakers are implemented for downstream dependencies.
