---
service: "lavatoryRunner"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

Lavatory Runner has three outbound external dependencies: Artifactory (primary), Splunk (log sink), and Wavefront (metrics). It has no inbound consumers calling into it and no internal Groupon service dependencies. All integration is one-directional: the runner connects to external systems during each scheduled execution.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Artifactory | HTTPS/REST | Query artifact metadata (AQL) and delete stale Docker image tags | yes | `artifactory` |
| Splunk | File / Splunk forwarder | Ingest cleanup and performance logs from `/var/log/lavatory/` | no | `loggingStack` |
| Wavefront | Push metrics | Expose purge statistics and performance metrics | no | N/A |

### Artifactory Detail

- **Protocol**: HTTPS/REST (Artifactory Query Language — AQL via POST to `/artifactory/api/search/aql`)
- **Base URL / SDK**: Configured via `ARTIFACTORY_HOST`, `ARTIFACTORY_PORT`, and `ARTIFACTORY_PATH` environment variables; resolved per colo using `TARGET_COLOS` for multi-colo download-date checks
- **Auth**: Username/password credentials (`ARTIFACTORY_USERNAME` / `ARTIFACTORY_PASSWORD`); the dedicated `lavatory` user account holds admin rights in Artifactory
- **Purpose**: All artifact metadata reads and delete operations are issued against the Artifactory REST API. AQL queries retrieve `manifest.json` files filtered by `@docker.repoName`, `updated`, and `stat.downloaded` fields. Deletions remove tag directories from Docker repositories.
- **Failure mode**: If Artifactory is unreachable, the container exits with a non-zero status; cron logs the failure. No retry logic is implemented within the policy runner itself.
- **Circuit breaker**: No evidence found in codebase.

### Splunk Detail

- **Protocol**: Log file forwarding (`/var/log/lavatory/<repo-name>.log` files on the host)
- **Base URL / SDK**: Splunk forwarder configured on `artifactory-utility` hosts; search index `index=prod_ops sourcetype=lavatory`
- **Auth**: Host-level Splunk forwarder credentials (managed outside this repo)
- **Purpose**: Captures per-run cleanup results including `INFO performance` lines with `repo`, `size_in_bytes`, `removed_bytes_count`, `removed_bytes_percent`, `removed_files_count`, and `removed_files_percent` fields.
- **Failure mode**: Log writes continue to local file; Splunk ingestion is best-effort.
- **Circuit breaker**: Not applicable.

### Wavefront Detail

- **Protocol**: Push metrics (implemented within the Lavatory base image)
- **Base URL / SDK**: Dashboard at `https://groupon.wavefront.com/dashboard/lavatory`
- **Auth**: Managed by the Lavatory base image configuration.
- **Purpose**: Exposes purge run metrics for operational visibility.
- **Failure mode**: No evidence found in codebase regarding failure handling.
- **Circuit breaker**: No evidence found in codebase.

## Internal Dependencies

> No evidence found in codebase. Lavatory Runner has no internal Groupon service dependencies.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Lavatory Runner is invoked by host-level cron jobs on `artifactory-utility` machines. The cron expressions are defined in Ansible group_vars files (not in this repo). The runner is not called by any other Groupon service.

## Dependency Health

No automated health check, retry, or circuit breaker patterns are implemented within the Lavatory Runner codebase. If Artifactory is unavailable, the container exits immediately with failure, and cron logs the error. Operators should monitor Splunk (`sourcetype=lavatory`) and Wavefront for signs of failing runs.
