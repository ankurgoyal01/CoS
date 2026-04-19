---
service: "gims"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

> No evidence found in codebase. Standard Continuum services expose HTTP health check endpoints.

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` (inferred) | http | (not specified) | (not specified) |

## Monitoring

### Metrics

> No evidence found in codebase. Expected metrics for an image management service:

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `gims.image.upload.count` (inferred) | counter | Number of images uploaded | (not specified) |
| `gims.image.upload.latency` (inferred) | histogram | Upload request latency | (not specified) |
| `gims.image.retrieval.count` (inferred) | counter | Number of image retrieval requests | (not specified) |
| `gims.image.retrieval.latency` (inferred) | histogram | Image retrieval latency | (not specified) |
| `gims.cdn.cache.hit.ratio` (inferred) | gauge | Akamai CDN cache hit ratio | (not specified) |
| `gims.storage.usage` (inferred) | gauge | Total image storage consumption | (not specified) |

### Dashboards

> No evidence found in codebase. Service owner should provide links to monitoring dashboards.

| Dashboard | Tool | Link |
|-----------|------|------|
| GIMS Service Health | (not specified) | (not specified) |
| Akamai CDN Performance | Akamai (inferred) | (not specified) |

### Alerts

> No evidence found in codebase. Expected alerts:

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| GIMS high error rate | HTTP 5xx rate > threshold | critical | Check application logs; verify storage backend connectivity; check JVM health |
| GIMS high upload latency | p99 upload latency > threshold | warning | Check storage backend performance; verify network connectivity |
| CDN origin errors | Akamai origin error rate elevated | critical | Check GIMS service health; verify origin connectivity |
| Storage capacity warning | Storage usage approaching limit | warning | Review image retention policies; consider storage expansion |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Standard Continuum restart procedures apply — rolling restart via Kubernetes deployment to avoid downtime.

### Scale Up / Down

> Operational procedures to be defined by service owner. Horizontal scaling via Kubernetes HPA or manual replica count adjustment.

### Database Operations

> Operational procedures to be defined by service owner. Image metadata migrations and backfills should be coordinated with dependent services to avoid disruption.

## Troubleshooting

### Images not loading for consumers

- **Symptoms**: Broken image links on consumer-facing pages; CDN returning 404 or 502 errors
- **Cause**: GIMS origin may be down, storage backend unavailable, or CDN configuration issue
- **Resolution**: Check GIMS service health; verify storage backend connectivity; check Akamai origin pull configuration; review recent deployments for breaking changes

### Image upload failures from internal services

- **Symptoms**: Metro Draft, MyGroupons, or Messaging Service reporting image upload errors; HTTP 500 or timeout responses from GIMS
- **Cause**: GIMS service overloaded, storage backend write failures, or authentication issues
- **Resolution**: Check GIMS service health and resource utilization; verify storage backend write capacity; check service authentication configuration

### CDN cache not warming

- **Symptoms**: High origin load; Image Service Primer reporting failures; slow image loading for new content
- **Cause**: Image Service Primer unable to reach GIMS; CDN cache eviction policies too aggressive
- **Resolution**: Check Image Service Primer health; verify GIMS is responding to primer requests; review CDN cache TTL configuration

### Signed URL failures

- **Symptoms**: Merchant Page or Metro Draft reporting signed URL errors; map images or media content failing to load
- **Cause**: Signing key rotation, clock skew, or configuration mismatch
- **Resolution**: Check signing key configuration; verify server clock synchronization; review recent key rotations

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all image uploads and retrievals failing; consumer-facing images broken | Immediate | Media / Platform team |
| P2 | Degraded — elevated error rates or latency; some consumers seeing slow/missing images | 30 min | Media / Platform team |
| P3 | Minor impact — specific transformation type failing; non-critical image operations affected | Next business day | Media / Platform team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Akamai CDN | Akamai monitoring dashboard; origin pull health | CDN serves stale cached content; origin receives direct traffic (higher load) |
| Image storage backend | Storage service health metrics | Reads may serve from CDN cache; writes fail until storage recovers |
| Image metadata database | Database connection pool health; query latency | Service degraded — metadata lookups fail; images may still be served from CDN |

> Operational procedures to be defined by service owner.
