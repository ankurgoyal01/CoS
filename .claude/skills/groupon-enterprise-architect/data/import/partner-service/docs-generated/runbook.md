---
service: "partner-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (Dropwizard standard) | http | JTier platform managed | JTier platform managed |
| `/ping` (Dropwizard standard) | http | JTier platform managed | JTier platform managed |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM heap memory utilization | Platform-defined |
| HTTP request rate | counter | Inbound requests per second across all endpoints | Platform-defined |
| HTTP error rate (5xx) | counter | Count of 5xx responses indicating service errors | Platform-defined |
| Database connection pool | gauge | Active JDBC connections to `continuumPartnerServicePostgres` | Platform-defined |
| MBus message processing lag | gauge | Delay between message publish and consumer processing | Platform-defined |
| Flyway migration status | gauge | Reports failed migrations on startup | Any failure = critical |

> Operational procedures to be defined by service owner. Specific metric names and alert thresholds are managed in the JTier/Continuum observability platform.

### Dashboards

> Operational procedures to be defined by service owner. Dashboard links are managed in the JTier/Continuum observability platform.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service health check failing | `/healthcheck` returns non-200 | critical | Inspect logs, check DB connectivity, check MBus connectivity |
| High 5xx rate | Error rate exceeds threshold | critical | Check upstream requests, inspect application logs |
| Database connection pool exhausted | All JDBC connections in use | critical | Check for long-running queries; restart service if pool does not recover |
| Flyway migration failure | Migration fails on startup | critical | Review migration script; roll back deployment if breaking |
| MBus disconnection | JMS/STOMP broker unreachable | warning | Check MBus broker health; `jtier-messagebus-client` will attempt reconnect |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow standard JTier deployment restart procedures for the target environment.

1. Confirm no active long-running partner workflows are in progress (check audit log)
2. Initiate rolling restart via JTier platform tooling
3. Monitor `/healthcheck` until all instances report healthy
4. Verify MBus connectivity is re-established post-restart

### Scale Up / Down

> Operational procedures to be defined by service owner. Instance counts are managed by the JTier platform team. Raise a platform ticket to adjust minimum/maximum instance counts.

### Database Operations

- **Schema migrations**: Flyway runs automatically on service startup. To run manually, use the Flyway CLI with the production `DATABASE_URL` and credentials.
- **Connection check**: Query `continuumPartnerServicePostgres` with a simple `SELECT 1` to confirm connectivity.
- **Audit log query**: Audit log entries can be queried directly from the `continuumPartnerServicePostgres` database when investigating partner operation history.

## Troubleshooting

### Partner Onboarding Workflow Stuck

- **Symptoms**: Partner onboarding initiated but does not progress; no completion event published to MBus
- **Cause**: Failure in one of the workflow steps (Salesforce sync, Deal Catalog call, ePOS sync); workflow state stored in `continuumPartnerServicePostgres`
- **Resolution**: Check application logs for the partner ID; identify the failing workflow step; resolve the dependency issue (check Salesforce, Deal Catalog, ePOS health); resubmit the workflow via the API or MBus event

### Mapping Reconciliation Failures

- **Symptoms**: Deal-to-division mappings are stale or missing; reconciliation job producing errors
- **Cause**: `continuumDealCatalogService` or `continuumDealManagementApi` returning errors or being unavailable
- **Resolution**: Confirm target services are healthy; check application logs for HTTP error responses from integration clients; re-trigger reconciliation once dependencies are restored

### Database Migration Failure on Startup

- **Symptoms**: Service fails to start; Flyway migration error in startup logs
- **Cause**: A new migration script has a syntax error or conflicts with current schema state
- **Resolution**: Roll back the deployment to the previous version; review the failing migration script; fix and redeploy

### MBus Messages Not Processing

- **Symptoms**: Partner workflow events accumulating without processing; partner state not updating
- **Cause**: MBus broker connectivity lost or `partnerSvc_mbusAndScheduler` consumer thread failure
- **Resolution**: Check MBus broker health; restart the service to re-initialize JMS consumers; verify `jtier-messagebus-client` reconnects successfully

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no partner management or onboarding possible | Immediate | SOX Inscope / 3PIP Team |
| P2 | Degraded — partial functionality (e.g., simulator unavailable, metrics not reporting) | 30 min | SOX Inscope / 3PIP Team |
| P3 | Minor impact — non-critical integration (e.g., Google Sheets import failing) | Next business day | SOX Inscope / 3PIP Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumPartnerServicePostgres` | JDBC connection test via Dropwizard health check | No fallback — service cannot operate without database |
| `messageBus` | MBus connectivity check via `jtier-messagebus-client` | Async workflows queued; reconnect attempted automatically |
| `continuumDealCatalogService` | HTTP GET health endpoint | Mapping and reconciliation operations fail; retry on next scheduled run |
| `continuumDealManagementApi` | HTTP GET health endpoint | Onboarding steps that require deal lifecycle operations fail |
| `continuumEpodsService` | HTTP GET health endpoint | Merchant/inventory sync steps skip or fail; retry on next run |
| `continuumGeoPlacesService` | HTTP GET health endpoint | Product-place mapping steps fail; geo data unavailable |
| `continuumUsersService` | HTTP GET health endpoint | User/contact lookups return errors; partner records may be incomplete |
| `salesForce` | HTTPS connectivity check | Salesforce sync steps fail; retried on next workflow execution |
