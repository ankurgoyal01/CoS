---
service: "deal_centre_api"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /actuator/health` | http | 30s (Kubernetes liveness/readiness probe) | 5s |
| `GET /actuator/info` | http | — | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.server.requests` | histogram | HTTP request latency and count per endpoint | P99 > 2s |
| `jvm.memory.used` | gauge | JVM heap memory usage | > 85% of configured limit |
| `jvm.gc.pause` | histogram | GC pause duration | P99 > 500ms |
| `db.connection.pool.active` | gauge | Active PostgreSQL connections | > 80% of pool size |
| `mbus.consumer.lag` | gauge | Message Bus consumer lag for inventory and catalog topics | > 1000 messages |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Deal Centre API — Overview | Grafana / Datadog | See internal monitoring platform — link to be added by service owner |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| DealCentreApiDown | `/actuator/health` returns non-200 | critical | Restart pods; check PostgreSQL and MBus connectivity |
| DealCentreApiHighLatency | P99 request latency > 2s for 5 minutes | warning | Check downstream dependencies (DMAPI, Deal Catalog Service, PostgreSQL) |
| DealCentrePostgresUnavailable | DB connection pool exhausted or connection refused | critical | Verify `continuumDealCentrePostgres` health; check credentials |
| MBusConsumerLag | MBus consumer lag > 1000 messages | warning | Check `dca_messageBusIntegration` logs; verify MBus broker health |

## Common Operations

### Restart Service

Operational procedures to be defined by service owner.

Typical Kubernetes approach:
1. Identify the deployment: `kubectl get deployments -n <namespace>`
2. Perform a rolling restart: `kubectl rollout restart deployment/deal-centre-api -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/deal-centre-api -n <namespace>`

### Scale Up / Down

Operational procedures to be defined by service owner.

Typical Kubernetes approach:
1. Scale replicas: `kubectl scale deployment/deal-centre-api --replicas=<N> -n <namespace>`
2. Or adjust HPA min/max in Helm values and redeploy

### Database Operations

Operational procedures to be defined by service owner.

- **Migrations**: Run via Maven (Flyway or Liquibase) as part of the CI/CD pipeline before deploying new application version
- **Backfills**: Execute via one-off Kubernetes jobs or direct SQL against `continuumDealCentrePostgres`
- **Connection check**: `kubectl exec -it <pod> -- psql $DB_HOST -U $DB_USERNAME -d $DB_NAME -c "\l"`

## Troubleshooting

### Deals Not Updating in Deal Management API

- **Symptoms**: Merchant deal create/update requests return errors or deals do not appear in downstream systems
- **Cause**: `continuumDealManagementApi` is unreachable or returning errors from `dca_externalClients`
- **Resolution**: Check DMAPI health; verify `DMAPI_BASE_URL` environment variable; review `dca_externalClients` logs in the pod

### Catalog Lookups Failing

- **Symptoms**: Buyer deal browsing returns empty results or errors; admin catalog views unavailable
- **Cause**: `continuumDealCatalogService` is unreachable or returning errors
- **Resolution**: Check Deal Catalog Service health; verify `DEAL_CATALOG_SERVICE_BASE_URL` environment variable; review application logs

### Message Bus Consumer Lag

- **Symptoms**: Inventory or catalog state in `continuumDealCentrePostgres` is stale; MBus consumer lag alert fires
- **Cause**: `dca_messageBusIntegration` consumers are behind or stuck
- **Resolution**: Check application logs for MBus consumer errors; verify MBus broker connectivity via `MBUS_CONNECTION_URL`; restart pods if consumers are stuck

### Database Connection Exhaustion

- **Symptoms**: Requests fail with database connection pool errors; `/actuator/health` reports DB down
- **Cause**: `continuumDealCentrePostgres` pool exhausted due to connection leak or high traffic
- **Resolution**: Check active connections on PostgreSQL; verify connection pool configuration; restart pods to recycle connections

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — merchant and buyer workflows unavailable | Immediate | Deal Centre team on-call |
| P2 | Degraded — specific workflows failing (e.g., email, catalog) | 30 min | Deal Centre team |
| P3 | Minor impact — elevated latency, non-critical features affected | Next business day | Deal Centre team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealCentrePostgres` | `/actuator/health` DB indicator; direct connection check | No fallback — database unavailability causes service degradation |
| `continuumDealManagementApi` | Check DMAPI `/health` endpoint | Deal create/update operations fail; read-only deal browsing may remain available |
| `continuumDealCatalogService` | Check Deal Catalog Service `/health` endpoint | Catalog lookups fail; merchant deal workflows may continue |
| `messageBus` | Check MBus broker connectivity; monitor consumer lag | Async event processing pauses; synchronous API workflows unaffected |
| `continuumEmailService` | Check Email Service `/health` endpoint | Transactional emails not sent; deal workflows continue |
