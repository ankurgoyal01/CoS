---
service: "doorman"
title: "Health Check and Status"
generated: "2026-03-03"
type: flow
flow_name: "health-check-status"
flow_type: synchronous
trigger: "Kubernetes probe or operator GET to /grpn/healthcheck, /ping, or /status"
participants:
  - "kubernetesProbe"
  - "continuumDoormanService"
architecture_ref: "components-doorman_components"
---

# Health Check and Status

## Summary

Doorman exposes three operational endpoints for Kubernetes probes and operators: a load-balancer health check (`/grpn/healthcheck`), a simple liveness ping (`/ping`), and a runtime status endpoint (`/status`). The health check drives Kubernetes liveness and readiness probes; the status endpoint lets operators confirm the deployed version, build SHA, and environment without examining container internals.

## Trigger

- **Type**: api-call
- **Source**: Kubernetes kubelet (liveness/readiness probes) or operator performing manual verification
- **Frequency**: Per Kubernetes probe interval (automatic); on-demand (operator)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes probe / operator | Issues HTTP GET to the operational endpoint | — |
| Doorman `statusController` | Handles the request and returns the appropriate response | `continuumDoormanService` |
| Doorman `runtimeInfo` | Supplies `bootedAt`, `sha`, and `version` data to the status endpoint | `continuumDoormanService` |

## Steps

### Health Check (`/grpn/healthcheck`)

1. **Receives GET /grpn/healthcheck**: Kubernetes liveness or readiness probe issues an HTTP GET to port 3180.
   - From: Kubernetes kubelet
   - To: `continuumDoormanService` (`statusController`)
   - Protocol: HTTP

2. **Checks heartbeat file presence**: `statusController` checks for the existence of `heartbeat.txt` at the application root (`App.root`). Sets `Cache-Control: private, no-cache, no-store, must-revalidate`.
   - From: `statusController`
   - To: filesystem
   - Protocol: direct

3. **Returns status code**: If `heartbeat.txt` exists, returns `200` (content type: `text/plain`). If absent, returns `503`.
   - From: `continuumDoormanService`
   - To: Kubernetes kubelet
   - Protocol: HTTP

### Ping (`/ping`)

1. **Receives GET /ping**: Liveness probe or operator issues an HTTP GET.
   - From: Operator / probe
   - To: `continuumDoormanService` (`statusController`)
   - Protocol: HTTP

2. **Returns ack**: Responds with `{"reply":"ack"}` (JSON).
   - From: `continuumDoormanService`
   - To: requester
   - Protocol: HTTP

### Status (`/status` or `/status.json`)

1. **Receives GET /status**: Operator issues an HTTP GET.
   - From: Operator
   - To: `continuumDoormanService` (`statusController`)
   - Protocol: HTTP

2. **Reads runtime info**: `statusController` calls `App.runtime_info` to obtain `booted_at`, `sha`, and `version` from the `RuntimeInfo` object (populated at startup from the `REVISION` file).
   - From: `statusController`
   - To: `runtimeInfo`
   - Protocol: direct

3. **Returns status JSON**: Responds with JSON containing `bootedAt` (ISO8601), `environment` (`RACK_ENV`), `serverTime` (ISO8601 UTC), `sha` (last 7 chars of revision), and `version` (full revision string).
   - From: `continuumDoormanService`
   - To: Operator
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `heartbeat.txt` absent | `/grpn/healthcheck` returns `503` | Kubernetes marks pod not ready; probe fails |
| `REVISION` file absent at startup | `runtimeInfo.sha` and `version` are `nil` | `/status` returns `null` for `sha` and `version` fields |

## Sequence Diagram

```
Kubernetes Probe -> continuumDoormanService: GET /grpn/healthcheck
continuumDoormanService -> continuumDoormanService: File.exist?("heartbeat.txt")
continuumDoormanService --> Kubernetes Probe: 200 OK or 503

Operator -> continuumDoormanService: GET /status.json
continuumDoormanService -> runtimeInfo: Read bootedAt, sha, version
runtimeInfo --> continuumDoormanService: RuntimeInfo data
continuumDoormanService --> Operator: {bootedAt, environment, serverTime, sha, version}
```

## Related

- Related flows: [SAML Authentication Initiation](saml-authentication-initiation.md)
- Runbook: [Runbook](../runbook.md)
- Architecture component view: `components-doorman_components`
