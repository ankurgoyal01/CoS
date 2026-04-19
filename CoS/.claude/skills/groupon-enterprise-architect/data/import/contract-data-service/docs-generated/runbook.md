---
service: "contract-data-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /healthcheck` (Dropwizard admin) | http | per Kubernetes liveness probe | per probe config |
| `ContractDataServiceHealthCheck` | exec (Dropwizard HealthCheck) | on admin poll | — |

The registered `ContractDataServiceHealthCheck` performs a trivial arithmetic check (`2 + 2 == 4`). Real health is indicated by database connectivity (JDBI connection pool status visible via Dropwizard admin at port 8081).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate | counter | Inbound requests per resource (via JTier SMA) | Per Wavefront dashboard |
| HTTP error rate | counter | 4xx/5xx responses | Per Wavefront dashboard |
| JVM heap usage | gauge | JVM memory utilization | Per Wavefront dashboard |
| DB connection pool | gauge | JDBI/Postgres pool active/idle connections | Per Wavefront dashboard |

Metrics are emitted via the JTier SMA (Steno Metrics Agent) framework. Dashboard definitions live in `doc/_dashboards/`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| SmaugCat SMA Dashboard | Wavefront | https://groupon.wavefront.com/dashboards_/contract-data-service--sma |
| Conveyor Cloud Customer Metrics | Wavefront | https://groupon.wavefront.com/u/W8S2yvqrSJ?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service unavailable | Pods in CrashLoopBackOff | critical | Check main container logs; see "Pod in CrashLoopBackOff" below |
| Opsgenie alert | Per Opsgenie policy | critical/warning | See CoDS Opsgenie: https://groupondev.app.opsgenie.com/service/222b7dcf-5f55-46c4-9869-b53199ddae31 |

## Common Operations

### Restart Service

There is generally no need to restart the service. To force a restart, delete the pod and let Kubernetes recreate it:

```bash
# Set context
kubectx contract-data-service-[staging|production]-sox-us-central1

# Find pod name
kubectl get pods

# Delete pod (Kubernetes will recreate)
kubectl --namespace contract-data-service-[staging|production]-sox delete pod <name-of-pod>
```

### Scale Up / Down

Scaling is managed through Deploybot and Conveyor Cloud. To change replica counts, update the min/max replica values in `.meta/deployment/cloud/components/app/[staging|production]-us-central1.yml` and redeploy.

Current limits:
- Staging: 1–2 replicas
- Production: 1–6 replicas

### Database Operations

**Run Flyway migrations** (manual):
```bash
mvn flyway:migrate -Denv=<environment>
```
Migration scripts are located at `src/main/resources/db/migration`. The Flyway plugin is configured with `cleanDisabled=true` to prevent accidental data loss.

**Local DB setup**:
```bash
docker run --name cods-db -p 5432:5432 -e POSTGRES_USER=root -e POSTGRES_PASSWORD=${POSTGRES_PASSWORD} -d postgres:9.4
psql -h 0.0.0.0 -p 5432 -U root
# CREATE DATABASE contract_data_service_stg;
```

### Access Pod Logs

```bash
# Application logs
kubectl logs <pod-name> main

# Steno structured logs (filebeat sidecar)
kubectl logs <pod-name> main-tail-log
```

Kibana log links:
- Pre-prod: https://logging-preprod.groupondev.com/goto/5a01432bae4b3e98a2cd815837d95fc0
- Staging: Kibana stable unified (index: `us-*:filebeat-contract-data-service--*`)
- Production: Kibana prod unified (index: `us-*:filebeat-contract-data-service--*`)

### Port Forwarding for Local Debug

```bash
kubectl port-forward <pod-name> 8080:8080
curl -v http://localhost:8080/v1/contract/1234
```

## Troubleshooting

### Pod in CrashLoopBackOff
- **Symptoms**: Pods do not start; `kubectl get pods` shows `CrashLoopBackOff` state
- **Cause**: Application fails to start — most commonly a bad configuration value or missing secret causing `ContractDataServiceConfiguration` to fail validation (Postgres or Retrofit config required fields are null)
- **Resolution**: Run `kubectl logs <pod-name> main` to see the startup exception. Verify `JTIER_RUN_CONFIG` points to a valid file and that all required secrets are mounted.

### HTTP 403 / 500 / 503 Errors
- **Symptoms**: Clients receive connection-related errors
- **Cause**: Access policies, Hybrid Boundary misconfiguration, or upstream service unavailability
- **Resolution**: Follow the [Conveyor Cloud Troubleshooting Guide](https://confluence.groupondev.com/display/EE/Troubleshooting+Guide#TroubleshootingGuide-DebuggingHTTPerrorcodes). Contact CMF or Hybrid Boundary teams if unresolved.

### Backfill Returns Error Map
- **Symptoms**: `GET /v1/backfillDeal/{historicalContractNumber}/{dealUUID}` returns a non-empty list of error strings
- **Cause**: One of the backfill validation steps or DMAPI/Deal Catalog calls failed. Common errors include `SECONDARY_DEAL_ERROR`, `BACKFILL_ABORTED`, `BACKFILL_FAILED`
- **Resolution**: Check structured logs for `event=BACKFILL_ABORTED` or `event=BACKFILL_FAILED` with the deal UUID. Verify DMAPI and Deal Catalog are healthy. Check that the `historicalContractNumber` maps to a valid deal with both v1 and v2 data in DMAPI.

### 404 on GET Endpoints
- **Symptoms**: `GET /v1/contractTerm/{id}` or similar returns 404
- **Cause**: Requested entity does not exist in the read-only Postgres replica; throws `NoSuchElementException` mapped to 404 by `NoSuchElementExceptionMapper`
- **Resolution**: Confirm the UUID/ID is correct. Check whether the write succeeded earlier (query the primary directly if needed).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (all endpoints unavailable) | Immediate | FED team via Opsgenie |
| P2 | Degraded (backfill failing, elevated error rate) | 30 min | FED team via Opsgenie |
| P3 | Minor impact (single endpoint degraded) | Next business day | FED team via Slack `#contract-service-notifications` |

Service portal: https://services.groupondev.com/services/contract-data-service

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumContractDataServicePostgresRw` | Dropwizard admin health endpoint (port 8081) | Writes fail; API returns 500 |
| `continuumContractDataServicePostgresRo` | Dropwizard admin health endpoint (port 8081) | Reads fail; GET endpoints return 500 |
| `continuumDealManagementApi` | No dedicated health check in CoDS source | Backfill endpoint returns error map; normal contract CRUD unaffected |
| `continuumDealCatalogService` | No dedicated health check in CoDS source | Backfill of secondary deals fails; normal contract CRUD unaffected |
