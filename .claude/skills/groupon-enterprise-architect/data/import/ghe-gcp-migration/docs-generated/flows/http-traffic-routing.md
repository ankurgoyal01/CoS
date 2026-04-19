---
service: "ghe-gcp-migration"
title: "HTTP/HTTPS Traffic Routing"
generated: "2026-03-03"
type: flow
flow_name: "http-traffic-routing"
flow_type: synchronous
trigger: "Inbound HTTP or HTTPS request from a Groupon engineer or CI/CD system to the GCP global load balancer"
participants:
  - "continuumHttpLoadBalancer"
  - "continuumNginxVm"
  - "continuumGithubVm"
architecture_ref: "dynamic-ghe-gcp-migration"
---

# HTTP/HTTPS Traffic Routing

## Summary

This flow describes how inbound HTTP, HTTPS, and custom HTTPS (port 8443) traffic from engineers or CI/CD systems reaches GitHub Enterprise. Requests arrive at one of three GCP global forwarding rules, pass through a URL-mapped HTTP target proxy, reach the Nginx backend service, and are then proxied by Nginx to the GHE application instance.

## Trigger

- **Type**: api-call
- **Source**: Groupon engineer browser, GitHub API client, or CI/CD pipeline connecting to the GHE web interface or REST API
- **Frequency**: Per-request (continuous during working hours)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Engineer / CI/CD system | Initiates HTTP/HTTPS request to GHE | — |
| HTTP(S) Load Balancer | Accepts traffic on ports 80, 443, 8443; maps to Nginx backend | `continuumHttpLoadBalancer` |
| Nginx Core VM | Acts as HTTP reverse proxy; forwards requests to GHE | `continuumNginxVm` |
| GitHub Core VM | Serves the GitHub Enterprise web application and REST API | `continuumGithubVm` |
| GCP Firewall Rules | Enforces IP allowlist before traffic reaches instances | `continuumGcpFirewallRules` |

## Steps

1. **Client sends HTTP/HTTPS request**: Engineer or CI/CD system connects to the external IP of forwarding rule `http-lb` (port 80), `https-lb` (port 443), or `custom-https-lb` (port 8443)
   - From: `Client (engineer workstation or CI runner)`
   - To: `continuumHttpLoadBalancer`
   - Protocol: HTTP or HTTPS

2. **Firewall evaluates ingress**: GCP firewall rule `allow-world-access` checks the source IP against the allowlist (TCP 80, 443, 8443); non-allowlisted sources are dropped
   - From: `continuumGcpFirewallRules`
   - To: `continuumNginxVm`
   - Protocol: TCP (stateful evaluation)

3. **Load balancer resolves target proxy**: The forwarding rule (`http-lb`, `https-lb`, or `custom-https-lb`) directs traffic to HTTP target proxy `lb-proxy`
   - From: `continuumHttpLoadBalancer` (forwarding rule)
   - To: `continuumHttpLoadBalancer` (target proxy `lb-proxy`)
   - Protocol: HTTP

4. **URL map selects backend**: Target proxy `lb-proxy` evaluates URL map `lb-url-map`; all paths (`/*`) on all hosts (`*`) resolve to backend service `nginx-backend`
   - From: `continuumHttpLoadBalancer` (URL map `lb-url-map`)
   - To: `continuumNginxVm` (backend service `nginx-backend`)
   - Protocol: HTTP

5. **Nginx receives and proxies request**: The `nginx-core` instance receives the request on port 80 and proxies it to the GitHub Enterprise application
   - From: `continuumNginxVm`
   - To: `continuumGithubVm`
   - Protocol: HTTP (internal to VPC)

6. **GHE processes request and responds**: GitHub Enterprise serves the web page or API response; the response travels back through Nginx and the load balancer to the client
   - From: `continuumGithubVm`
   - To: `continuumNginxVm` -> `continuumHttpLoadBalancer` -> Client
   - Protocol: HTTP/HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Client IP not in firewall allowlist | GCP drops TCP connection at firewall | Client receives connection refused or timeout |
| Nginx instance unhealthy | GCP backend health check marks `nginx-backend` unhealthy | Load balancer returns 502/503 to client |
| GHE instance unavailable | Nginx returns upstream connection error | Client receives 502 Bad Gateway from Nginx |
| GHE boot not complete | GHE application not yet listening on port | Client receives 503 until GHE is ready |

## Sequence Diagram

```
Client -> http-lb_ForwardingRule: HTTP GET (port 80 / 443 / 8443)
http-lb_ForwardingRule -> GCP_Firewall: check source IP against allow-world-access
GCP_Firewall --> http-lb_ForwardingRule: allowed
http-lb_ForwardingRule -> lb-proxy_TargetProxy: forward request
lb-proxy_TargetProxy -> lb-url-map_URLMap: resolve path /*
lb-url-map_URLMap -> nginx-backend_BackendService: select nginx-backend
nginx-backend_BackendService -> nginx-core_VM: proxy request (HTTP)
nginx-core_VM -> github-core_VM: proxy to GHE (HTTP)
github-core_VM --> nginx-core_VM: GHE response
nginx-core_VM --> Client: HTTP response
```

## Related

- Architecture dynamic view: `dynamic-ghe-gcp-migration`
- Related flows: [SSH Traffic Routing](ssh-traffic-routing.md), [Infrastructure Provisioning](infrastructure-provisioning.md)
