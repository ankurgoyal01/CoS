---
service: "partner-attributes-mapping-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /healthcheck` (Dropwizard admin) | http | Kubernetes liveness probe interval | Kubernetes probe timeout |
| `math` health check | exec (in-process) | Checked on each `/healthcheck` call | N/A |
| PostgreSQL pool health | http (Dropwizard admin) | Checked on each `/healthcheck` call | Configured by DaaS pool |

The Dropwizard admin port (8081) exposes `/healthcheck` and `/metrics`. The service registers:
- A custom `ServiceHealthCheck` named `math` — a baseline liveness check.
- PostgreSQL connection pool health checks automatically registered by `jtier-daas-postgres` for both the read-write and read-only pools.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM memory consumption | Monitor via Elastic APM (APM enabled in all cloud envs) |
| HTTP request rate / latency | histogram | Inbound request throughput and response time | Configured in SMA dashboards (`doc/_dashboards/sma.js`) |
| HTTP error rate (4xx / 5xx) | counter | Error responses per endpoint | Configured in SMA dashboards |
| PostgreSQL connection pool | gauge | Active/idle connections | Registered via `jtier-daas-postgres` health checks |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SMA HTTP In/Out | Custom SMA dashboard | `doc/_dashboards/sma.js` (Groupon internal) |
| Cloud metrics | Cloud dashboard | `doc/_dashboards/components/cloud.js` |
| JVM metrics | JVM dashboard | `doc/_dashboards/components/jvm.js` |
| Custom metrics | Custom dashboard | `doc/_dashboards/components/custom.js` |
| Elastic APM | Elastic APM | APM enabled; see Groupon APM platform (https://groupondev.atlassian.net/wiki/spaces/CSRE/pages/80717348991) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service health check failing | `/healthcheck` returns unhealthy | critical | Check PostgreSQL connectivity; restart pod if DB is healthy |
| High 5xx error rate | Elevated HTTP 500 responses | critical | Check logs in Splunk/Elastic; verify PostgreSQL connection pool |
| HPA at max replicas | `maxReplicas` reached | warning | Investigate traffic spike; consider raising `maxReplicas` via Helm values |
| PostgreSQL pool exhausted | Pool health check failing | critical | Check DB load; scale service or optimize queries |

Alert notifications are sent to `#clo-notifications` Slack channel (configured in `Jenkinsfile` and DeployBot).

## Common Operations

### Restart Service

1. Identify the target Kubernetes namespace: `partner-attributes-mapping-service-staging` or `partner-attributes-mapping-service-production`.
2. Rolling restart via `kubectl rollout restart deployment/<deployment-name> -n partner-attributes-mapping-service-<env>`.
3. Monitor rollout: `kubectl rollout status deployment/<deployment-name> -n partner-attributes-mapping-service-<env>`.
4. Verify `/healthcheck` returns healthy on the new pods via the admin port (8081).

### Scale Up / Down

- Adjust `minReplicas` / `maxReplicas` in the relevant Helm values file (`.meta/deployment/cloud/components/app/<env>.yml`) and redeploy via DeployBot, OR
- Manually patch the HPA: `kubectl patch hpa <hpa-name> -n partner-attributes-mapping-service-<env> --patch '{"spec":{"maxReplicas":<N>}}'`.

### Add a New Partner

1. Generate a partner secret using the Rake automation in the [partner-signature-service-secrets repo](https://github.groupondev.com/clo/partner-signature-service-secrets).
2. Call `POST /v1/partners/{partner_name}/secrets/generate` with the appropriate `client-id` and request body.
3. The `PartnerRegistry` is automatically refreshed after secret creation.
4. Alternatively, add the partner entry to `partnerSecretsConfig` in the environment YAML config and redeploy.

### Database Operations

- **Run migrations**: Migrations execute automatically at service startup via `PostgresMigrationBundle` (Flyway). No manual step required on deployment.
- **Local DB setup**: Create a PostgreSQL database named `pams_dev` and start the service; migrations will create the necessary tables.
- **DaaS requests**: Infrastructure requests (new DB instances, VIPs, whitelisting) are submitted via [ops-request.groupondev.com](https://ops-request.groupondev.com). Original DaaS tickets: staging GDS-15483, production GDS-15425.

## Troubleshooting

### Mapping creation returns 409 Conflict
- **Symptoms**: `POST /v1/mapping` returns HTTP 409 with `DuplicateMappingsException` body
- **Cause**: One or more of the provided `grouponId` or `partnerId` values already exist in `partner_attributes_map` for the given `partner_namespace` and `entity_type`
- **Resolution**: Use `PUT /v1/groupon_mappings` or `PUT /v1/partner_mappings` to update existing mappings, or remove duplicate IDs from the request payload

### Signature returns 404 Brand not found
- **Symptoms**: `POST /v1/signature` or `POST /v1/signature/validation` returns HTTP 404
- **Cause**: The `X-BRAND` header value does not match any registered partner in the `PartnerRegistry` (neither in the `partner_secrets` DB table nor in the `partnerSecretsConfig` YAML block)
- **Resolution**: Register the partner via `POST /v1/partners/{partner_name}/secrets/generate`, or add the partner to the `partnerSecretsConfig` YAML and redeploy

### Signature returns 400 Digest not supported
- **Symptoms**: `POST /v1/signature` returns HTTP 400
- **Cause**: The `digest` field in the request body specifies an algorithm not in the supported map (currently only `HMAC-SHA1` is supported)
- **Resolution**: Ensure callers pass `"digest": "HMAC-SHA1"` in the request body

### 403 Forbidden on mapping endpoints
- **Symptoms**: Mapping endpoints return HTTP 403
- **Cause**: The `client-id` header is missing from the request; enforced by `HeadersValidationFilter`
- **Resolution**: Ensure all callers include the `client-id` header in their requests

### Update/delete returns 401 Unauthorized
- **Symptoms**: `PUT` or `DELETE` mapping endpoints return HTTP 401
- **Cause**: The `X-Brand` partner namespace is not listed in the `partnerConfig.updatable` or `partnerConfig.deletable` lists in the active configuration YAML
- **Resolution**: Add the partner namespace to the appropriate list in the config file and redeploy

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; partner ID translations failing | Immediate | CLO on-call (clo-alerts@groupon.com); `#clo-notifications` |
| P2 | Degraded — high error rates or elevated latency | 30 min | CLO Engineering |
| P3 | Minor impact — individual endpoint issues or sporadic errors | Next business day | CLO Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPartnerAttributesMappingPostgres` (read-write) | Dropwizard admin `/healthcheck` — pool health registered by `jtier-daas-postgres` | No fallback; write operations fail with 500 |
| `continuumPartnerAttributesMappingPostgres` (read-only) | Dropwizard admin `/healthcheck` — read-only pool health | No fallback; search/lookup operations fail with 500 |
