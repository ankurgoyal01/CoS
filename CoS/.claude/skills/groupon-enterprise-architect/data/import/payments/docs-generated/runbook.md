---
service: "payments"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/health` or `/actuator/health` (inferred) | http | > No evidence found in codebase. | > No evidence found in codebase. |

> Health check endpoint inferred from Spring Boot Actuator conventions. Actual endpoint should be verified against the service's source code.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `payments.authorization.count` | counter | Number of payment authorization attempts | > No evidence found in codebase. |
| `payments.authorization.latency` | histogram | Latency of payment authorization calls to PSPs | > No evidence found in codebase. |
| `payments.capture.count` | counter | Number of payment capture attempts | > No evidence found in codebase. |
| `payments.capture.latency` | histogram | Latency of payment capture calls to PSPs | > No evidence found in codebase. |
| `payments.gateway.errors` | counter | Errors returned from external payment gateways | > No evidence found in codebase. |

> Metric names above are inferred from the service's domain. The architecture model confirms the Payments Service publishes metrics to `metricsStack` via Stats/OTel. Actual metric names should be verified against the service's instrumentation code.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Payments Service | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Payment gateway high error rate | Gateway error rate exceeds threshold | critical | Investigate gateway health; check PSP status pages; escalate to Payments Team |
| Payment authorization latency spike | P99 authorization latency exceeds threshold | warning | Check gateway response times; review recent deployments; check DB connection pool |
| Payments DB connection pool exhaustion | Active DB connections at limit | critical | Scale service replicas; check for long-running queries; restart affected pods |

> Alert configurations above are inferred from common payment service operational patterns. Actual alert definitions should be verified against the monitoring configuration.

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard Kubernetes pod restart expected: `kubectl rollout restart deployment/payments-service -n <namespace>`.

### Scale Up / Down

> Operational procedures to be defined by service owner. Standard Kubernetes HPA or manual scaling expected.

### Database Operations

- **Migrations**: > No evidence found in codebase for migration tooling. Standard JPA/Flyway or Liquibase expected for a Spring Boot service.
- **Backfills**: > Operational procedures to be defined by service owner.
- **PCI considerations**: All database operations must comply with PCI-DSS requirements. Direct production database access should be restricted and audited.

## Troubleshooting

### Payment Authorization Failures

- **Symptoms**: Orders failing at checkout with payment errors; increased error counts on `payments.gateway.errors` metric
- **Cause**: External payment gateway unavailability, invalid credentials, or network issues
- **Resolution**: Check PSP status pages and provider health; verify gateway credentials; review Provider Client logs for error details; if transient, the Orders Service retry daemons will reattempt

### High Payment Latency

- **Symptoms**: Slow checkout experience; increased P99 latency on authorization and capture operations
- **Cause**: Slow PSP response times, database connection pool saturation, or resource contention
- **Resolution**: Check gateway response times; review Payments DB connection pool metrics; check JVM heap and GC activity; consider scaling the service horizontally

### Database Connection Issues

- **Symptoms**: JDBC connection errors in logs; payment operations failing with database exceptions
- **Cause**: DaaS MySQL instance unavailable, connection pool exhaustion, or network partition
- **Resolution**: Check DaaS health; review connection pool configuration; check for long-running transactions or lock contention; escalate to DBA team if instance-level issue

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Payment processing completely down; all transactions failing | Immediate | Payments Team, Orders Team, On-Call SRE |
| P2 | Degraded payment processing; elevated error rates or latency | 30 min | Payments Team |
| P3 | Minor impact; intermittent errors or single-provider issues | Next business day | Payments Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Payment Gateways (`paymentGateways`) | Monitor gateway error rates and latency via `payments_providerClient` metrics | Orders Service retries via daemon schedulers; no in-service fallback documented |
| Payments DB (`continuumPaymentsDb`) | JDBC connection health / Spring Actuator DB health indicator | No fallback; service cannot operate without its database |
| Logging Stack (`loggingStack`) | Async emission; non-blocking | Log loss acceptable; does not impact payment processing |
| Metrics Stack (`metricsStack`) | Stats/OTel push; non-blocking | Metric loss acceptable; does not impact payment processing |
| Tracing Stack (`tracingStack`) | OpenTelemetry push; non-blocking | Trace loss acceptable; does not impact payment processing |
