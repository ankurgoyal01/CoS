---
service: "grouponlive-inventory-service-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Dropwizard health check (JTier default endpoint) | HTTP | JTier default | JTier default |
| `GliveInventoryServiceJtierHealthCheck` (application-level) | In-process | On request | Immediate |
| Provenue ping (`GET /v2/test/ping`) | HTTP (via `ProvenueVendorSyncJob`) | Scheduled (Quartz) | Retrofit timeout |

The application-level health check (`GliveInventoryServiceJtierHealthCheck`) is a trivial sanity check. Operational health depends on MySQL connectivity, Redis connectivity, and partner API reachability.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | Gauge | Java heap memory consumption | Container memory limit (2Gi staging / 4Gi production) |
| HTTP request rate | Counter | Inbound API request volume | Operational procedures to be defined by service owner |
| HTTP error rate | Counter | 4xx/5xx response rate from inbound requests | Operational procedures to be defined by service owner |
| Partner API error rate | Counter | Failures when calling Provenue/Telecharge/AXS/TM | Operational procedures to be defined by service owner |
| Quartz job failures | Counter | `PurchaseJob` / `ReserveJob` execution failures | Operational procedures to be defined by service owner |

Metrics are published via the JTier metrics framework (Wavefront/Telegraf integration available per README).

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service metrics (Wavefront) | Wavefront | Operational procedures to be defined by service owner |
| Log aggregation (ELK) | ELK / Kibana | Operational procedures to be defined by service owner |
| APM traces | Elastic APM | Staging: `elastic-apm-http.logging-platform-elastic-stack-staging.svc.cluster.local:8200` / Production: `elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Third-party purchase error | Purchase to Provenue/Telecharge/AXS fails | Critical | Triggers `PUT /alerts/splunk/third_party_purchase_error` on `glive-inventory-rails`; investigate partner API logs and order records |
| Reservation expired without purchase | Reservation `expires_at` passed, order not completed | Warning | Investigate Quartz `PurchaseJob` queue backlog |
| Quartz job execution failure | `JobExecutionException` thrown in `ReserveJob` or `PurchaseJob` | Critical | Check Quartz job store in MySQL; review Steno logs for `purchase.job` or `reservations.job` events |
| Provenue API version mismatch | `ProvenueVendorSyncJob` detects API version change | Info | Review Provenue changelog; validate reservation and purchase flows against new version |

## Common Operations

### Restart Service

1. Via Deploybot: trigger a re-deploy of the current release to the target environment.
2. Via Kubernetes (if direct cluster access is available): `kubectl rollout restart deployment/glive-inventory-jtier-app -n glive-inventory-jtier-production-sox`

### Scale Up / Down

1. Update `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` (or staging equivalent).
2. Commit, push to `release` branch, and promote through Deploybot.

### Database Operations

- **Run migrations**: Flyway migrations are applied automatically at startup from `src/main/resources/db/migration/`. New migration files must be added following the `V{N}__Description.sql` naming convention.
- **Check pending migrations**: `mvn flyway:info` with production DB credentials.
- **Manual query access**: Connect to `grouponlive-inventory-service-rw-na-production-db.gds.prod.gcp.groupondev.com`, database `glive_inventory_production`.

### Quartz Job Management

- The Quartz admin interface is exposed at `/quartz` (admin port 8081).
- Jobs `ReserveJob` and `PurchaseJob` are triggered programmatically (not cron) via the `enqueue_job` API endpoint.
- `ProvenueVendorSyncJob` is scheduled periodically and syncs Provenue vendor API versions.

## Troubleshooting

### Purchase fails with partner error

- **Symptoms**: `POST /v1/purchases` returns an error; `third_party_error_message` written to the `orders` table; Splunk alert triggered on `glive-inventory-rails`
- **Cause**: External partner API (Provenue or Telecharge) rejected the purchase request (insufficient inventory, authentication failure, or partner downtime)
- **Resolution**: Check Steno logs for `ExternalPartnerException` detail; verify partner API credentials in secrets; check partner status pages; if authentication failure, verify OAuth token generation for Provenue or credential rotation for Telecharge

### Reservation not found after creation

- **Symptoms**: `GET /v1/reservations/{reservationUuid}` returns 404 after a successful `POST /v1/reservations`
- **Cause**: Reservation UUID mismatch, or `ReserveJob` failed before committing to MySQL
- **Resolution**: Check Quartz job execution logs (Steno log event `reservations.job`); query `reservations` table by UUID directly; verify MySQL connectivity

### Redis connection failures

- **Symptoms**: Partner OAuth tokens not cached; repeated token generation calls to Provenue; increased latency
- **Cause**: Redis endpoint unavailable or connection timeout (2000 ms threshold)
- **Resolution**: Check Redis Memorystore instance in GCP; verify endpoint configuration matches the correct environment; check network policies in the Kubernetes namespace

### High memory / OOM kills

- **Symptoms**: Kubernetes pod OOM-killed; `MALLOC_ARENA_MAX` is set to 4 to mitigate glibc arena growth
- **Cause**: JVM heap growth due to large Quartz job queue or high concurrency
- **Resolution**: Review JVM heap settings in the JTier base image; increase memory limit in the deployment YAML if needed; investigate thread pool sizes (`maxThreads: 50`, Quartz `threadCount: 50`)

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down; no reservations or purchases can be processed | Immediate | Groupon Live Engineering on-call |
| P2 | Degraded; specific partner (e.g., Telecharge) not responding; other partners functional | 30 min | Groupon Live Engineering |
| P3 | Minor impact; elevated error rate on non-critical endpoints | Next business day | Groupon Live Engineering |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MySQL (`continuumGliveInventoryDatabase`) | JTier DaaS health check (connection pool check) | No fallback; service is non-functional without database |
| Redis (`continuumRedisCache`) | Jedis connection check at startup | Partial degradation; partner API calls may succeed but will re-authenticate on every request |
| Provenue API | `ProvenueVendorSyncJob` calls `GET /v2/test/ping` | No automated fallback; purchase/reservation requests for Provenue products will fail |
| Telecharge API | No dedicated health check | No automated fallback; purchase/reservation requests for Telecharge products will fail |
| glive-inventory-rails | No dedicated health check | Purchase error alerts and event updates will fail silently if Rails service is down |
