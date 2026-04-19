---
service: "billing-record-options-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` on port 8080 | http | Platform default | Platform default |
| Admin port 8081 | http | Platform default | Platform default |

The `/grpn/status` endpoint returns a JSON payload including a `commitId` field (git SHA) used for version verification. Configured in `.service.yml` with `sha_key: commitId`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Payment method request counter | counter | Emitted per request, tagged by country, client type, brand, exchange flag, and inventory service type (via `PaymentMethodMetrics`) | Operational procedures to be defined by service owner |
| JVM heap usage | gauge | Standard JTier JVM metrics (memory request: 2-4Gi, limit: 4-8Gi) | Operational procedures to be defined by service owner |
| HTTP request latency | histogram | Standard JTier Dropwizard HTTP request timing | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| BROS main dashboard | Wavefront | `https://groupon.wavefront.com/dashboard/bros` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Health check on `/grpn/status` fails | P1 | Page on-call via PagerDuty (P6H79CS); check pod status and logs |
| High error rate | Elevated 5xx responses on `/paymentmethods` | P2 | Check database connectivity and cache availability; review application logs |
| Database unreachable | PostgreSQL connection failures in logs | P1 | Verify DaaS connectivity; check regional DB endpoints (see [Data Stores](data-stores.md)) |

**PagerDuty**: https://groupon.pagerduty.com/services/P6H79CS
**Alert email**: bros@groupon.pagerduty.com
**Google Chat**: space `AAAAXNgz0P4`

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. General approach for Kubernetes-managed services:
1. Identify the deployment in the appropriate Kubernetes namespace (`bros-<environment>`)
2. Issue a rolling restart: `kubectl rollout restart deployment/bros-app -n bros-<environment>`
3. Monitor rollout: `kubectl rollout status deployment/bros-app -n bros-<environment>`
4. Verify health at `/grpn/status`

### Scale Up / Down

Scaling is controlled by HPA configuration in `.meta/deployment/cloud/components/app/<env>.yml`. To manually override:
1. Update `minReplicas` / `maxReplicas` in the appropriate environment YAML and redeploy via Deploybot
2. HPA target utilization is set to 25% CPU for production environments

### Database Operations

#### Flyway Migrations

Run migrations using the `flyway-migrate` CLI command:

```sh
java -jar target/billing-record-options-service-1.0.<version>.jar flyway-migrate <config-file-path>
```

The `AUTOMIGRATE` environment variable controls whether migrations run automatically on startup (`true`) or must be run manually (`false` — production default).

#### Accessing Databases

See [Data Stores](data-stores.md) for regional PostgreSQL endpoints. Credentials are stored in the `billing-record-options-service-secrets` repository.

## Troubleshooting

### Service Returns Empty Payment Methods List

- **Symptoms**: `GET /paymentmethods/{countryCode}` returns `count: 0` or empty `paymentMethods` array
- **Cause**: Country code may be inactive in the `countries` table (`active = false`), no payment providers configured for that country, or filter criteria exclude all providers
- **Resolution**: Verify the country record exists and is active in the `countries` table; check `payment_providers` for the country ISO code; review `include_filters` and `exclude_filters` on provider records

### Database Connection Failures

- **Symptoms**: `500` errors on all endpoints; connection pool exhaustion in logs
- **Cause**: DaaS PostgreSQL endpoint unreachable, credentials rotated without restart, or connection pool saturation
- **Resolution**: Verify database endpoint accessibility (see regional endpoints in [Data Stores](data-stores.md)); check credentials in secrets submodule; restart pods to pick up new credentials; review DaaS status page

### Cache Miss Storms

- **Symptoms**: Elevated database load; high response latency
- **Cause**: Cache eviction or RAAS Redis restart leading to all requests hitting PostgreSQL
- **Resolution**: Cache will warm automatically as requests are served. Verify RAAS Redis endpoint is healthy; check RAAS-139 / RAAS-192 provisioning status

### Incorrect Client Type Resolution

- **Symptoms**: Wrong payment methods returned for mobile clients; `touch` client type not applied
- **Cause**: User-agent string does not match `user_agent_regex` patterns in the `client_types` table; `X-CLIENT-ROLES` header not set to `touch`
- **Resolution**: Review `client_types` table regex patterns; ensure callers set appropriate `userAgent` query param or `X-CLIENT-ROLES` header

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — checkout cannot determine payment methods | Immediate | Global Payments team (bros@groupon.pagerduty.com) |
| P2 | Degraded — elevated errors or incorrect payment methods | 30 min | Global Payments team (cap-payments@groupon.com) |
| P3 | Minor impact — single country or filter issue | Next business day | Global Payments team (cap-payments@groupon.com) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `daasPostgresPrimary` | Query a simple count from `payment_providers`; check DaaS platform health dashboard | No database fallback — requests fail if DB is unavailable |
| `raasRedis` | Check RAAS platform health; verify Redis connectivity via `payment-cache` SDK logging | Falls back to direct database read on cache miss |
