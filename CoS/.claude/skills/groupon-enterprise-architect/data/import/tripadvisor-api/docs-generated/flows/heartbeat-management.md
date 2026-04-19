---
service: "tripadvisor-api"
title: "Heartbeat Management"
generated: "2026-03-03"
type: flow
flow_name: "heartbeat-management"
flow_type: synchronous
trigger: "PUT or DELETE to /resources/manage/heartbeat, or file-level operation on /var/groupon/run/ta-api/heartbeat.txt"
participants:
  - "continuumTripadvisorApiV1Webapp"
  - "utilityController"
architecture_ref: "dynamic-heartbeat-management"
---

# Heartbeat Management

## Summary

The heartbeat mechanism controls whether each application host is included in or excluded from the load balancer's VIP. The `utilityController` exposes HTTP endpoints to enable or disable the heartbeat by creating or removing a file at `/var/groupon/run/ta-api/heartbeat.txt`. The load balancer polls a heartbeat check endpoint; if the file is present and the application responds with HTTP 200, the host is considered healthy and receives traffic. This flow is used during deployments, scaling operations, and incident response.

## Trigger

- **Type**: api-call or manual
- **Source**: Capistrano deploy system, operator command, or direct HTTP call
- **Frequency**: On deployment events; on-demand during incidents

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Capistrano / Load Balancer | Initiates heartbeat enable or disable | External |
| TripAdvisor API v1 Webapp | Hosts the heartbeat management endpoints | `continuumTripadvisorApiV1Webapp` |
| Utility Controller | Handles heartbeat PUT/DELETE requests and heartbeat status polling | `utilityController` |

## Steps

### Enable Heartbeat (add host to LB rotation)

1. **Sends PUT request to heartbeat endpoint**: Operator or Capistrano sends `PUT /resources/manage/heartbeat` with HTTP Basic auth (`admin` / `heartbeat.passwd`).
   - From: Operator / Capistrano
   - To: `utilityController`
   - Protocol: HTTP (port 8080)

2. **Creates heartbeat file**: Controller creates the file at `heartbeat.location` (`/var/groupon/run/ta-api/heartbeat.txt` in staging/production).
   - From: `utilityController`
   - To: file system
   - Protocol: direct

3. **Returns 200 OK**: Controller confirms heartbeat is enabled.
   - From: `utilityController`
   - To: Operator / Capistrano
   - Protocol: HTTP

4. **Load balancer detects host as healthy**: On next health check poll, load balancer receives HTTP 200 from heartbeat endpoint; host begins receiving traffic.

### Disable Heartbeat (remove host from LB rotation)

1. **Sends DELETE request to heartbeat endpoint**: Operator or Capistrano sends `DELETE /resources/manage/heartbeat` with HTTP Basic auth.
   - From: Operator / Capistrano
   - To: `utilityController`
   - Protocol: HTTP (port 8080)

2. **Removes heartbeat file**: Controller deletes the file at `/var/groupon/run/ta-api/heartbeat.txt`.
   - From: `utilityController`
   - To: file system
   - Protocol: direct

3. **Returns 200 OK**: Controller confirms heartbeat is disabled.

4. **Load balancer detects host as unhealthy**: On next health check poll, load balancer no longer routes traffic to this host.

### Heartbeat Status Check (by load balancer or monitoring)

1. **Load balancer polls heartbeat**: Load balancer sends HTTP request to `/resources/manage/heartbeat` (or `gpn-mgmt.py` checks status).
   - From: Load balancer / monitoring
   - To: `utilityController`
   - Protocol: HTTP

2. **Controller checks file presence**: Returns HTTP 200 if heartbeat file exists, non-200 if absent.
   - From: `utilityController`
   - To: Load balancer / monitoring
   - Protocol: HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Wrong Basic auth credentials | Spring Security returns 401 Unauthorized | Request rejected; heartbeat state unchanged |
| File system error (cannot create/delete file) | IOException; 500 returned | Heartbeat state may be inconsistent; check file manually |
| Host reported FAILED by `gpn-mgmt.py test` | Script may report false positive for 302/301/203 responses | Verify HTTP status code is a genuine error before taking action |

## Sequence Diagram

```
Operator -> utilityController: PUT /resources/manage/heartbeat (Basic auth)
utilityController -> utilityController: Authenticate credentials
utilityController -> filesystem: touch /var/groupon/run/ta-api/heartbeat.txt
filesystem --> utilityController: File created
utilityController --> Operator: 200 OK (heartbeat enabled)
LoadBalancer -> utilityController: Poll heartbeat endpoint
utilityController -> filesystem: Check heartbeat file exists
filesystem --> utilityController: File present
utilityController --> LoadBalancer: 200 OK (host healthy)
```

## Related

- Architecture dynamic view: `dynamic-heartbeat-management` (not yet defined in `architecture/views/dynamics.dsl`)
- Related flows: [Deployment](../deployment.md)
- Runbook procedure: [Runbook — Enable/Disable Heartbeat](../runbook.md)
- Service status endpoint: `GET /resources/status.json` (port 8080, SHA key: `status/runningGitSha`)
