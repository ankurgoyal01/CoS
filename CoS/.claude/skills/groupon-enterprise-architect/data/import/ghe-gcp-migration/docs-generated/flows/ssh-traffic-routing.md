---
service: "ghe-gcp-migration"
title: "SSH Traffic Routing"
generated: "2026-03-03"
type: flow
flow_name: "ssh-traffic-routing"
flow_type: synchronous
trigger: "Inbound SSH connection on port 22 or 122 from a Groupon engineer or CI/CD system"
participants:
  - "continuumSshLoadBalancer"
  - "continuumGithubInstanceGroup"
  - "continuumGithubVm"
architecture_ref: "dynamic-ghe-gcp-migration"
---

# SSH Traffic Routing

## Summary

This flow describes how git SSH operations (clone, fetch, push) and administrative SSH connections reach GitHub Enterprise. SSH connections on ports 22 or 122 arrive at the GCP global TCP load balancer, pass through a TCP proxy, and are routed to the GHE managed instance group, ultimately landing on the `github-core` instance. The TCP proxy preserves the raw SSH protocol without HTTP-layer inspection.

## Trigger

- **Type**: api-call
- **Source**: Groupon engineer running `git clone git@github.groupon.com:...`, `git push`, or SSHing to the GHE admin console; CI/CD runner executing git operations
- **Frequency**: Per-request (continuous during development and CI/CD pipeline execution)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineer / CI/CD system | Initiates SSH connection to GHE | — |
| SSH TCP Load Balancer | Accepts TCP on ports 22 and 122; routes via TCP proxy | `continuumSshLoadBalancer` |
| GCP Firewall Rules | Enforces IP allowlist for SSH ports | `continuumGcpFirewallRules` |
| GitHub Instance Group | Managed instance group target for SSH backend | `continuumGithubInstanceGroup` |
| GitHub Core VM | GHE instance handling SSH git protocol and admin SSH | `continuumGithubVm` |

## Steps

1. **Client initiates SSH connection**: Engineer or CI/CD runner connects to the external IP of forwarding rule `github-ssh-lb` on port 22 (git SSH) or port 122 (GHE admin SSH)
   - From: `Client (engineer workstation or CI runner)`
   - To: `continuumSshLoadBalancer` (forwarding rule `github-ssh-lb`)
   - Protocol: TCP (SSH handshake)

2. **Firewall evaluates ingress**: GCP firewall rule `allow-world-access` checks the source IP against the allowlist for TCP ports 22 and 122; non-allowlisted sources are dropped
   - From: `continuumGcpFirewallRules`
   - To: `continuumGithubVm`
   - Protocol: TCP stateful evaluation

3. **Forwarding rule selects TCP proxy**: The forwarding rule `github-ssh-lb` (port range 22, 122) directs traffic to TCP target proxy `github-proxy`
   - From: `continuumSshLoadBalancer` (forwarding rule)
   - To: `continuumSshLoadBalancer` (TCP proxy `github-proxy`)
   - Protocol: TCP

4. **TCP proxy routes to GHE backend**: TCP proxy `github-proxy` forwards the connection to backend service `github-backend` (protocol TCP, port `ssh`), which targets the `github-core-manager` instance group
   - From: `continuumSshLoadBalancer` (TCP proxy)
   - To: `continuumGithubInstanceGroup` (backend service `github-backend`)
   - Protocol: TCP

5. **GHE instance handles SSH session**: The active instance in the `github-core-manager` group (i.e., `github-core` VM) receives the SSH connection; GHE's sshd authenticates the user via SSH key and handles the git protocol or admin session
   - From: `continuumGithubInstanceGroup`
   - To: `continuumGithubVm`
   - Protocol: SSH

6. **Session completes and closes**: Git operation or admin session completes; TCP connection is torn down cleanly
   - From: `continuumGithubVm`
   - To: `Client`
   - Protocol: SSH / TCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client IP not in firewall allowlist | GCP drops TCP SYN at firewall | Client receives `Connection refused` or `Network unreachable` |
| GHE instance unhealthy / not yet ready | GCP backend health check marks `github-backend` unhealthy | Client receives TCP connection failure; retry after GHE boot completes |
| SSH key not authorized on GHE | GHE sshd rejects authentication | Client receives `Permission denied (publickey)` |
| Autoscaler launched extra replica without shared disk | Second GHE instance lacks repository data | git operations fail with repository not found; only primary instance should serve traffic |

## Sequence Diagram

```
Client -> github-ssh-lb_ForwardingRule: TCP SYN (port 22 or 122)
github-ssh-lb_ForwardingRule -> GCP_Firewall: check source IP against allow-world-access
GCP_Firewall --> github-ssh-lb_ForwardingRule: allowed
github-ssh-lb_ForwardingRule -> github-proxy_TCPProxy: forward TCP stream
github-proxy_TCPProxy -> github-backend_BackendService: route to github-core-manager
github-backend_BackendService -> github-core_VM: TCP connection (SSH)
github-core_VM -> github-core_VM: authenticate SSH key, serve git protocol
github-core_VM --> Client: SSH session data (git pack objects / admin output)
Client -> github-core_VM: git push data / admin commands
github-core_VM --> Client: SSH session close
```

## Related

- Architecture dynamic view: `dynamic-ghe-gcp-migration`
- Related flows: [HTTP/HTTPS Traffic Routing](http-traffic-routing.md), [GHE Autoscaling](ghe-autoscaling.md), [Infrastructure Provisioning](infrastructure-provisioning.md)
