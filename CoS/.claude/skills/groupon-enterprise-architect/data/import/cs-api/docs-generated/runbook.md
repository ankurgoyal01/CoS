---
service: "cs-api"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | > No evidence found | > No evidence found |
| `/ping` | http | > No evidence found | > No evidence found |

> Dropwizard applications expose `/healthcheck` and `/ping` on the admin port by default. Confirm exact health check configuration with the service owner.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Requests per second to all CS API endpoints | > Operational procedures to be defined by service owner |
| HTTP error rate (5xx) | counter | Server-side error responses | > Operational procedures to be defined by service owner |
| HTTP latency | histogram | Request latency per endpoint | > Operational procedures to be defined by service owner |
| MySQL connection pool utilization | gauge | Active connections to `csApiMysql` | > Operational procedures to be defined by service owner |
| Redis connection pool utilization | gauge | Active connections to `csApiRedis` | > Operational procedures to be defined by service owner |
| Downstream call error rate | counter | Errors returned by downstream services (Zendesk, Salesforce, internal services) | > Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| CS API Service Dashboard | > No evidence found | > No evidence found |

> Dashboard links are not available in the central architecture model. Contact GSO Engineering (nsanjeevi) for monitoring dashboard locations.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High 5xx error rate | >5% of requests return 5xx | critical | Check downstream dependency health; review logs |
| MySQL connection pool exhausted | Pool utilization >90% | critical | Scale service; investigate slow queries |
| Redis unavailable | Redis health check fails | critical | Verify Redis connectivity; assess session impact |
| Zendesk call failures | Zendesk HTTP errors elevated | warning | Check Zendesk status page; alert CS operations |
| Salesforce call failures | Salesforce HTTP errors elevated | warning | Check Salesforce status page |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard JTier Kubernetes restart:

1. Identify the deployment in Kubernetes: `kubectl get deployment cs-api -n <namespace>`
2. Trigger a rolling restart: `kubectl rollout restart deployment/cs-api -n <namespace>`
3. Monitor rollout: `kubectl rollout status deployment/cs-api -n <namespace>`

### Scale Up / Down

> Operational procedures to be defined by service owner. Standard JTier Kubernetes scaling:

1. Scale replicas: `kubectl scale deployment/cs-api --replicas=<N> -n <namespace>`
2. Verify pods are running: `kubectl get pods -n <namespace> -l app=cs-api`

### Database Operations

> Operational procedures to be defined by service owner.

- **Migrations**: Run via Maven / Liquibase or Flyway against `csApiMysql`; migrations path is not captured in the central model
- **Read replica lag**: Monitor replication lag on `csApiRoMysql`; elevated lag may cause stale reads for memo/snippet lookups
- **Connection pool tuning**: Adjust `jtier-daas-mysql` pool settings in `config.yml` if connection pool exhaustion is observed

## Troubleshooting

### Agents Cannot Create Sessions

- **Symptoms**: POST `/sessions` returns 401 or 503; agents cannot log in to Cyclops
- **Cause**: JWT validation failure, `continuumCsTokenService` unavailable, or Redis session store unreachable
- **Resolution**: Check `authModule` logs; verify `continuumCsTokenService` health; verify Redis connectivity to `csApiRedis`

### Customer Data Not Loading

- **Symptoms**: GET `/customer-attributes` or `/orders` returns empty or 500
- **Cause**: One or more downstream services (`continuumUsersService`, `continuumOrdersService`, `continuumConsumerDataService`) is unavailable or returning errors
- **Resolution**: Check service logs for upstream call failures; verify health of downstream services; assess whether partial data can be returned

### Convert-to-Cash Failing

- **Symptoms**: POST `/convert-to-cash` returns 500 or 422
- **Cause**: `continuumIncentivesService` is unavailable or rejecting the request; or the order is ineligible
- **Resolution**: Check `serviceClients` logs for incentives call errors; verify `continuumIncentivesService` health; confirm order eligibility with CS team

### Memo or Snippet Operations Failing

- **Symptoms**: POST/PUT/DELETE on `/memos` or `/snippets` returns 500
- **Cause**: `csApiMysql` primary is unavailable or `csApi_repositories` has a connection issue
- **Resolution**: Check MySQL primary connectivity; review `csApi_repositories` error logs; verify connection pool health

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down; all CS agents cannot access Cyclops | Immediate | GSO Engineering (nsanjeevi) |
| P2 | Degraded functionality (some endpoints failing; partial data) | 30 min | GSO Engineering (nsanjeevi) |
| P3 | Minor impact (slow responses; non-critical features unavailable) | Next business day | GSO Engineering (nsanjeevi) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `csApiMysql` | Dropwizard DB health check on `/healthcheck` | Memo/snippet writes fail; read replica may serve reads |
| `csApiRedis` | Redis ping via Dropwizard health check | Session store unavailable; agent sessions cannot be created |
| `continuumCsTokenService` | HTTP call to service health endpoint | Authentication fails; no agent sessions possible |
| `continuumUsersService` | Monitor HTTP error rate in service logs | Customer profile data unavailable; degraded agent context |
| `continuumOrdersService` | Monitor HTTP error rate in service logs | Order history unavailable; agent cannot view orders |
| `zendesk` | Monitor HTTP error rate in service logs | Ticket creation and lookup unavailable |
| `salesForce` | Monitor HTTP error rate in service logs | CRM data unavailable; degraded merchant/customer context |
