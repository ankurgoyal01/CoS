---
service: "cs-token"
title: "Service Health Check"
generated: "2026-03-03"
type: flow
flow_name: "service-health-check"
flow_type: synchronous
trigger: "GET /heartbeat.txt from load balancer or monitoring"
participants:
  - "continuumCsTokenService"
architecture_ref: "dynamic-cs-token"
---

# Service Health Check

## Summary

The load balancer (Conveyor Cloud / Kubernetes ingress) polls `GET /heartbeat.txt` on each pod at regular intervals to determine whether the instance should remain in the service pool. CS Token Service responds with the contents of the `heartbeat.txt` file and HTTP 200 when healthy. If the file is missing (e.g., after a pod crash and incomplete startup), the controller returns HTTP 503, causing the load balancer to remove the instance from rotation.

## Trigger

- **Type**: schedule (load balancer polling)
- **Source**: Conveyor Cloud load balancer / Kubernetes liveness/readiness probe
- **Frequency**: Continuous, on the load balancer's configured polling interval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Load Balancer / Kubernetes | Polls heartbeat endpoint to assess pod health | External infrastructure |
| CS Token Service (Nginx sidecar) | Forwards request to Rails app on port 8000 | `continuumCsTokenService` |
| HeartbeatController | Reads `heartbeat.txt` from Rails root; returns contents or 503 | `continuumCsTokenService` |

## Steps

1. **Load balancer sends health probe**: Kubernetes liveness/readiness probe issues `GET /heartbeat.txt` to the pod's Nginx sidecar on port 8080.
   - From: Kubernetes load balancer
   - To: `continuumCsTokenService` (Nginx port 8080)
   - Protocol: HTTP

2. **Nginx proxies to Unicorn**: Nginx forwards the request to the Unicorn Rails process on port 8000 (railsPort).
   - From: Nginx sidecar
   - To: Unicorn / Rails (port 8000)
   - Protocol: HTTP (internal)

3. **HeartbeatController reads heartbeat file**: `HeartbeatController#ping` opens `Rails.root/heartbeat.txt` and reads its contents.
   - From: `HeartbeatController`
   - To: filesystem (`/var/groupon/cs-token-service/heartbeat.txt`)
   - Protocol: filesystem read

4. **Return health response**: If the file exists and is readable, returns HTTP 200 with plain text content. If the file does not exist (`Errno::ENOENT`), returns HTTP 503 `Not found`.
   - From: `continuumCsTokenService`
   - To: Kubernetes load balancer
   - Protocol: HTTP

5. **Load balancer acts on response**: HTTP 200 keeps the pod in the pool. HTTP 503 causes the load balancer to remove the pod and alert operators.
   - From: Kubernetes load balancer
   - To: routing table / alerting
   - Protocol: internal

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `heartbeat.txt` file missing | `Errno::ENOENT` rescued; returns HTTP 503 `Not found` | Pod removed from load balancer pool; incident may trigger if enough pods are affected |
| Rails/Unicorn process not responding | TCP connection failure or timeout at Nginx | Load balancer marks pod unhealthy; Kubernetes restarts pod |
| Pod in `CrashLoopBackoff` | Kubernetes restart loop | Multiple pod failures trigger alerts; requires ops intervention |

## Sequence Diagram

```
LoadBalancer -> NginxSidecar: GET /heartbeat.txt (port 8080)
NginxSidecar -> UnicornRails: GET /heartbeat.txt (port 8000)
UnicornRails -> HeartbeatController: route to #ping action
HeartbeatController -> Filesystem: read /var/groupon/cs-token-service/heartbeat.txt
Filesystem --> HeartbeatController: file contents OR Errno::ENOENT
HeartbeatController --> UnicornRails: HTTP 200 (text content) OR HTTP 503 ("Not found")
UnicornRails --> NginxSidecar: response
NginxSidecar --> LoadBalancer: HTTP 200 (healthy) OR HTTP 503 (unhealthy)
```

## Related

- Architecture dynamic view: `dynamic-cs-token`
- Related flows: [Token Creation](token-creation.md), [Token Verification](token-verification.md)
- Runbook: [Service Health Check Troubleshooting](../runbook.md)
