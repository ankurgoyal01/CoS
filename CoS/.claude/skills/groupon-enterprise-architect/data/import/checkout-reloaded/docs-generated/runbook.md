---
service: "checkout-reloaded"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /health` | http | > No evidence found in codebase. | > No evidence found in codebase. |

The `/health` endpoint is used by Kubernetes readiness and liveness probes to determine pod availability.

## Monitoring

### Metrics

> No evidence found in codebase. Specific metric names and alert thresholds are not documented in the service inventory. Metrics are likely emitted via the `itier-server` framework or Node.js process instrumentation.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| > No evidence found in codebase. | — | — | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | — | — |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| > No evidence found in codebase. | — | — | — |

> Operational procedures to be defined by service owner. Monitoring and alerting configuration is managed externally and not documented in the service inventory.

## Common Operations

### Restart Service

Restart is handled via the Kubernetes/Conveyor deployment platform.

1. Identify the pod(s) to restart using `kubectl get pods -n <namespace> -l app=checkout-reloaded`
2. Roll out a restart: `kubectl rollout restart deployment/checkout-reloaded -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/checkout-reloaded -n <namespace>`
4. Confirm `/health` returns 200 on new pods before traffic is restored

### Scale Up / Down

Scaling is managed via Kubernetes HPA (min: 2, max: 10 replicas, 70% CPU target).

- Manual override: `kubectl scale deployment/checkout-reloaded --replicas=<N> -n <namespace>`
- Review HPA status: `kubectl get hpa -n <namespace>`

### Database Operations

checkout-reloaded delegates persistent state to `continuumCheckoutReloadedDb` (PostgreSQL) via the `checkoutReloaded_repository` component.

> No evidence found in codebase. Migration tooling, backfill procedures, and schema management details are not documented in the service inventory. Contact the Checkout / Consumer Experience team for database operational procedures.

## Troubleshooting

### Checkout Page Fails to Render

- **Symptoms**: Consumers see a blank or error page on `GET /checkout`; server logs show upstream call failures
- **Cause**: One or more required downstream services (Cart Service, Pricing Service, Deal Catalog) is unavailable or returning errors
- **Resolution**: Check downstream service health via their respective health endpoints; inspect Winston logs at `LOG_LEVEL=debug` for the specific failing call; confirm `API_PROXY_BASE_URL` is correctly set

### Payment Authorization Fails at Submit

- **Symptoms**: POST /checkout/submit returns an error state; consumers see a payment failure message
- **Cause**: Adyen API returning a decline or error; misconfigured `ADYEN_API_KEY` or `ADYEN_MERCHANT_ACCOUNT`; `checkout.adyenDropIn` feature flag state mismatch
- **Resolution**: Check Adyen merchant dashboard for decline reason codes; verify `ADYEN_API_KEY` and `ADYEN_MERCHANT_ACCOUNT` secrets are correctly injected; confirm `checkout.adyenDropIn` flag state in Keldor

### Feature Flag Behavior Unexpected

- **Symptoms**: A checkout variant (new payment flow, Adyen drop-in, post-purchase upsell) is not activating as expected
- **Cause**: Keldor flag misconfiguration; `KELDOR_CONFIG_SOURCE` pointing to wrong environment endpoint
- **Resolution**: Verify flag values directly in the Keldor admin interface; check `KELDOR_CONFIG_SOURCE` env var value against the target environment; inspect service startup logs for Keldor client initialization errors

### High Memory / OOM on Pods

- **Symptoms**: Pods are OOMKilled by Kubernetes; Node.js process crashes under load
- **Cause**: Insufficient `NODE_OPTIONS=--max-old-space-size` setting for the SSR rendering workload
- **Resolution**: Increase `--max-old-space-size` via `NODE_OPTIONS` env var; review `UV_THREADPOOL_SIZE` for I/O contention; scale out horizontally via HPA before increasing memory limits

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Checkout completely unavailable — consumers cannot complete purchases | Immediate | Checkout / Consumer Experience Team + SRE |
| P2 | Checkout degraded — subset of consumers experiencing errors or slow renders | 30 min | Checkout / Consumer Experience Team |
| P3 | Minor impact — single feature flag variant misbehaving, no revenue impact | Next business day | Checkout / Consumer Experience Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Cart Service | Check via API Proxy; inspect logs for cart load errors | Checkout page renders error state; consumer cannot proceed |
| Pricing Service | Check via API Proxy; inspect logs for pricing validation errors | Checkout page renders error state |
| Order Service | Check via API Proxy; inspect logs for finalization errors | POST /checkout/submit returns error; payment not charged (Adyen auth may need reversal) |
| Adyen Payment Gateway | Check Adyen merchant dashboard status page | Payment step fails; consumer shown payment error; order not placed |
| Keldor | Inspect startup logs for Keldor client errors | Feature flags fall back to defaults; service continues with baseline behavior |
| `continuumCheckoutReloadedDb` | Check PostgreSQL connection; inspect repository layer logs | Checkout session persistence fails; BFF cannot restore in-progress sessions |
