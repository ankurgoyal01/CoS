---
service: "unit-tracer"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard health check (`/healthcheck` on port 8081) | http | JTier default | JTier default |
| `UnitTracerHealthCheck` (registered as "math") | exec (internal) | On-demand via `/healthcheck` | N/A |

The `UnitTracerHealthCheck` always returns healthy (validates `2 + 2 == 4`). It does not probe downstream services. Downstream service health must be assessed by inspecting report `errors` and `steps` arrays in unit reports.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JTier JVM metrics | gauge | Standard JVM metrics (heap, GC, threads) exposed via Dropwizard Metrics on admin port 8081 | JTier platform defaults |
| Steno structured logs | — | Structured JSON logs written under source type `unit-tracer_app` (Filebeat → Kafka) | — |

> Specific application-level metrics beyond JTier defaults are not defined in the codebase. Operational procedures to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Telegraf metrics (local debug) | Telegraf | See README — `https://metrics-docs.groupondev.com/test_env/` |

> Production dashboards are managed externally by the Finance Engineering team. Links to be confirmed by service owner.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Build failure on `main` | Jenkins build fails on `main` branch | warning | Email sent to `financial-engineering-alerts@groupon.com`; investigate build logs at `cloud-jenkins.groupondev.com/job/finance-engineering/job/unit-tracer/` |

> Application-level alerting configuration is managed externally. Operational procedures to be defined by service owner.

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. As a Kubernetes-managed service, a restart can be performed via `kubectl rollout restart deployment/unit-tracer` in the appropriate namespace (`unit-tracer-production` or `unit-tracer-staging`).

### Scale Up / Down

Operational procedures to be defined by service owner. Scaling is configured via `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/<environment>.yml`. For immediate scaling, use `kubectl scale deployment/unit-tracer --replicas=<N>` in the appropriate namespace.

### Database Operations

> Not applicable. Unit Tracer owns no data stores. No migration or backfill operations are required.

## Troubleshooting

### Unit report shows empty inventory section

- **Symptoms**: `UnitReport.inventoryUnit` is null; errors array contains entries from `Third Party Inventory Service`, `Voucher Inventory Service`, and/or `Groupon Live Inventory Service`
- **Cause**: The unit UUID or Groupon code was not found in any of the three inventory services, or all three returned HTTP errors
- **Resolution**: Verify the unit ID is valid; check the `steps` array for HTTP response codes from each inventory service call; verify connectivity to inventory service VIPs from the Unit Tracer pod

### Unit report shows empty accounting section

- **Symptoms**: `UnitReport.accountingServiceUnitResponse` is null; errors contain "Unable to lookup Unit - no UUID" or an Accounting Service error
- **Cause**: Either inventory lookup failed (no UUID was resolved) or Accounting Service returned a non-2xx response
- **Resolution**: First resolve any inventory lookup errors; then verify the unit UUID exists in Accounting Service (`GET /api/v3/units/{id}`); check `steps` for the Accounting Service HTTP response code

### Unit report shows empty ledger section

- **Symptoms**: `UnitReport.messageToLedgerLifeCycleResponse` is null; errors contain "Unable to lookup message2ledger - no UUID"
- **Cause**: Inventory lookup failed to resolve a UUID, so Message to Ledger could not be called
- **Resolution**: Resolve the inventory lookup issue first; if UUID is present, check that Message to Ledger service is reachable (`GET /admin/units/{unitId}/lifecycle`)

### Service returns 400 / constraint violation on `/unit`

- **Symptoms**: HTTP 400 or constraint validation error returned
- **Cause**: `unitIds` query parameter is empty or missing (`@NotEmpty` constraint enforced by Dropwizard)
- **Resolution**: Ensure `unitIds` is provided in the request with at least one valid UUID or Groupon code

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; finance engineers unable to investigate unit history | Immediate | Finance Engineering team (`financial-engineering-alerts@groupon.com`) |
| P2 | Partial degradation — reports missing data from one or more upstream services | 30 min | Finance Engineering team |
| P3 | Minor impact — individual unit lookups returning errors for isolated IDs | Next business day | Finance Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Third Party Inventory Service | Check `steps` in unit report for HTTP response code; verify TPIS VIP reachability | Service falls back to Voucher Inventory Service |
| Voucher Inventory Service | Check `steps` in unit report for HTTP response code | Service falls back to Groupon Live Inventory Service |
| Groupon Live Inventory Service | Check `steps` in unit report for HTTP response code | No further fallback; inventory section will be empty |
| Accounting Service | Check `steps` in unit report for accounting entries | No fallback; accounting section will be empty |
| Message to Ledger | Check `steps` in unit report for Message2Ledger entry | No fallback; ledger section will be empty |
