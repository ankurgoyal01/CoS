---
service: "getaways-partner-integrator"
title: "Health Check and Monitoring"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "health-check-and-monitoring"
flow_type: synchronous
trigger: "Kubernetes liveness/readiness probe or operator admin request"
participants:
  - "continuumGetawaysPartnerIntegrator"
  - "getawaysPartnerIntegrator_persistenceLayer"
  - "continuumGetawaysPartnerIntegratorDb"
architecture_ref: "components-getawaysPartnerIntegratorComponents"
---

# Health Check and Monitoring

## Summary

Kubernetes periodically probes the Dropwizard health check endpoint to determine whether the service instance is alive and ready to serve traffic. The Dropwizard health check framework verifies the status of all registered health indicators — primarily the MySQL database connection via `continuumGetawaysPartnerIntegratorDb`. A healthy response allows Kubernetes to route traffic to the pod; an unhealthy response causes Kubernetes to restart or remove the pod from the load balancer.

## Trigger

- **Type**: schedule (automated probe) or manual (operator admin request)
- **Source**: Kubernetes liveness and readiness probes; on-call engineer or monitoring system
- **Frequency**: Periodic — determined by Kubernetes probe interval configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes (or operator) | Initiates liveness/readiness probe | External — Kubernetes infrastructure |
| Getaways Partner Integrator | Hosts Dropwizard health check and admin endpoints | `continuumGetawaysPartnerIntegrator` |
| Persistence Layer | Validates MySQL connectivity as part of DB health check | `getawaysPartnerIntegrator_persistenceLayer` |
| Getaways Partner Integrator DB | MySQL — primary dependency checked by health check | `continuumGetawaysPartnerIntegratorDb` |

## Steps

1. **Issues health probe**: Kubernetes liveness or readiness probe issues an HTTP GET to the Dropwizard health check endpoint (`/healthcheck`).
   - From: Kubernetes probe
   - To: `continuumGetawaysPartnerIntegrator` (Dropwizard admin port)
   - Protocol: HTTP

2. **Evaluates registered health checks**: Dropwizard runs all registered health check implementations in the service.
   - From: `continuumGetawaysPartnerIntegrator` (health check framework)
   - To: Internal health check registry
   - Protocol: Direct (in-process)

3. **Checks MySQL connectivity**: The database health check verifies that the MySQL connection pool can successfully acquire a connection and execute a validation query against `continuumGetawaysPartnerIntegratorDb`.
   - From: `getawaysPartnerIntegrator_persistenceLayer`
   - To: `continuumGetawaysPartnerIntegratorDb`
   - Protocol: JDBC / MySQL

4. **Returns health status**: Dropwizard aggregates all health check results and returns an HTTP response — 200 if all checks pass, 500 if any check fails.
   - From: `continuumGetawaysPartnerIntegrator`
   - To: Kubernetes probe (or operator)
   - Protocol: HTTP (JSON health report)

5. **Kubernetes acts on result**:
   - If healthy (HTTP 200): Pod remains in service and continues to receive traffic.
   - If unhealthy (HTTP 500): Liveness failure triggers pod restart; readiness failure removes pod from load balancer rotation.
   - From: Kubernetes
   - To: Pod / Service mesh
   - Protocol: Kubernetes control plane

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL connection pool exhausted | DB health check fails; returns 500 | Kubernetes marks pod unhealthy; liveness probe triggers restart |
| MySQL instance unreachable | JDBC connection attempt times out; health check fails | Pod restarted or removed from rotation; alert triggered |
| Health check endpoint unreachable (port not listening) | Kubernetes TCP probe fails | Kubernetes marks pod as failed; restart triggered |
| Dropwizard admin port blocked by misconfigured network policy | Kubernetes probe timeout | Pod considered unhealthy; service disruption |

## Sequence Diagram

```
Kubernetes -> dropwizard: GET /healthcheck (admin port)
dropwizard -> persistenceLayer: Run DB health check
persistenceLayer -> MySQL: Validate connection (ping/query)
MySQL --> persistenceLayer: OK / Error
persistenceLayer --> dropwizard: Healthy / Unhealthy
dropwizard --> Kubernetes: HTTP 200 (healthy) or HTTP 500 (unhealthy)
Kubernetes -> Kubernetes: Route traffic (healthy) or Restart pod (unhealthy)
```

## Related

- Architecture dynamic view: `components-getawaysPartnerIntegratorComponents`
- Related flows: [Runbook](../runbook.md) — see Health Checks and Troubleshooting sections
- See [Deployment](../deployment.md) for Kubernetes probe configuration context
