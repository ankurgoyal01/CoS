---
service: "bhuvan"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | http | Readiness: 5s, Liveness: 15s | Not specified (k8s default) |
| `GET /grpn/status` (port 8080) | http | On demand | - |
| Liveness probe (Kubernetes) | http | Period: 15s, Initial delay: 30s | - |
| Readiness probe (Kubernetes) | http | Period: 5s, Initial delay: 20s | - |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM heap usage | gauge | JVM heap utilization tracked via `MIN_RAM_PERCENTAGE` / `MAX_RAM_PERCENTAGE` | 90% (configured via env vars) |
| HTTP request rate | counter | Incoming HTTP requests per endpoint (SMA http-in dashboard) | Operational procedure to be defined by service owner |
| HTTP error rate | counter | 4xx/5xx response counts per endpoint | Operational procedure to be defined by service owner |
| DB query latency | histogram | Postgres query duration (SMA db-out dashboard) | Operational procedure to be defined by service owner |
| HTTP upstream latency | histogram | Outbound HTTP call durations to external providers (SMA http-out dashboard) | Operational procedure to be defined by service owner |
| Experimentation metrics | counter | Experiment bucketing decisions emitted via `ExperimentMetrics` | Operational procedure to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Bhuvan main dashboard | Wavefront | https://groupon.wavefront.com/dashboard/bhuvan |
| Bhuvan SMA dashboard | Wavefront | https://groupon.wavefront.com/u/S4kNQjg5fw?t=groupon |

> Dashboard definitions are in `doc/_dashboards/` (SMA components: cloud, JVM, on-prem, http-in, http-out, db-out).

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Health check failures | P1 | Page geo-bhuvan@groupon.pagerduty.com immediately |
| High error rate | Sustained 5xx rate | P2 | Check logs, dependency health, and restart if needed |
| High memory usage | JVM heap > 90% for extended period | P2 | Investigate memory leak; scale up if needed |
| Dependency failure | Postgres / Redis unreachable | P1 | Check DaaS/RaaS status; page on-call if infra issue |

## Common Operations

### Restart Service

```bash
# Kubernetes rolling restart (staging example)
kubectl rollout restart deployment/bhuvan-app -n bhuvan-staging

# Verify rollout
kubectl rollout status deployment/bhuvan-app -n bhuvan-staging
```

### Scale Up / Down

```bash
# Manual scaling override (Kubernetes)
kubectl scale deployment/bhuvan-app --replicas=<N> -n bhuvan-<env>

# HPA auto-scales between minReplicas (3) and maxReplicas (10–17) at 60% CPU target.
# Adjust HPA target if sustained high load requires different scaling behavior.
```

### Database Operations

#### Run DB Migrations

```bash
java -jar target/bhuvan-<version>.jar migrate <config-file.yml>
# Example:
java -jar target/bhuvan-1.0.local-SNAPSHOT.jar migrate development.yml
```

#### Clean DB

```bash
java -jar target/bhuvan-<version>.jar clean <config-file.yml>
```

#### Rebuild Geo Spatial Index (via API)

```bash
POST /indexes/rebuild?index_name=<index-name>
# WARNING: This is computationally expensive and may cause performance degradation.
# Example:
POST /indexes/rebuild?index_name=Geoplaces-Divisions
```

#### Rebuild Geo Spatial Index (via CLI)

```bash
java -jar bhuvan-<version>.jar geo-spatial-index -i <index-name> <config-file.yml>
# Available index names:
#   Geoplaces-Divisions
#   Geoplaces-Localities
#   Geoplaces-Neighborhoods
#   Geoplaces-Postalcodes
#   Geoplaces-Timezones
```

#### Build Geo Entity Relationships

```bash
java -jar bhuvan-<version>.jar relationship-build -e <entity-type> [-t <thread-count>] [-r <max-radius>] <config-file.yml>
# Example:
java -jar bhuvan-1.0.local-SNAPSHOT.jar relationship-build -e Postalcodes -t 50 -r 250 development.yml
```

## Troubleshooting

### High Memory / OOM Kills
- **Symptoms**: Pods being OOM-killed, JVM heap alerts firing.
- **Cause**: JVM virtual memory explosion (glibc arena fragmentation in multi-threaded JVM) or genuine memory leak.
- **Resolution**: Ensure `MALLOC_ARENA_MAX=4` is set (prevents vmem explosion). Check GC logs. If heap is genuinely growing, investigate for memory leaks in cache or geo data loading. Scale up pod memory limits if necessary.

### Slow or Failed Geo Queries
- **Symptoms**: High latency on `/v1.x/divisions`, `/places`, or similar endpoints; 503/504 errors.
- **Cause**: Redis spatial index not populated, Postgres query overload, or external provider timeout.
- **Resolution**: Verify Redis spatial index is populated (call `POST /indexes/rebuild?index_name=Geoplaces-Divisions` if needed). Check Postgres query performance in Wavefront dashboards. Check Bhoomi / Maps API availability.

### Autocomplete Not Returning Results
- **Symptoms**: Autocomplete endpoints return empty results or errors.
- **Cause**: ElasticSearch index not populated or ES cluster unreachable.
- **Resolution**: Verify ElasticSearch cluster health. Rebuild autocomplete index via `geo-spatial-indexer` command or `POST /indexes/rebuild`. Check ES client configuration in the active YAML config.

### Cache Stale Data
- **Symptoms**: Geo entity updates not reflected in API responses.
- **Cause**: Redis response cache holding stale entries.
- **Resolution**: Use the internal cache administration endpoint (via `CacheResource`) to invalidate or flush affected cache entries. Check `GET /api/internal/cache` endpoints for cache stats.

### IP Geolocation Failures
- **Symptoms**: `ipaddress` parameter queries returning incorrect or no results.
- **Cause**: MaxMind database file outdated, or Bhoomi service unreachable.
- **Resolution**: Check that `GEO_MAXMIND_PACKAGE` in the Dockerfile is up-to-date and the `.mmdb` file is present at `/var/groupon/maxmind/GeoIP2-City.mmdb`. Verify Bhoomi service health if fallback is also failing.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down | Immediate | geo-bhuvan@groupon.pagerduty.com; #geo-services Slack (CF9BSHL1M) |
| P2 | Degraded performance / partial outage | 30 min | Geo Services team (geo-team@groupon.com) |
| P3 | Minor impact / single feature degraded | Next business day | Geo Services team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Postgres (DaaS) | Check `/grpn/healthcheck` response; verify DaaS status page | No fallback — service degraded without Postgres |
| Redis (RaaS) | Check Wavefront Redis metrics; verify RaaS status | Cache misses fall through to Postgres; spatial queries may be unavailable |
| ElasticSearch | Check ES cluster health endpoint; verify index existence | Autocomplete disabled or degraded; falls back to Postgres-based search if configured |
| Bhoomi Geocoding | Check Bhoomi service health via service portal | Falls back to MaxMind GeoIP2 local database |
| Google Maps / MapTiler / Avalara | Check external API error rates in Wavefront http-out dashboard | Returns error or degraded geo details response |
| MaxMind GeoIP2 | File existence check at `/var/groupon/maxmind/GeoIP2-City.mmdb` | Falls back to Bhoomi service for IP resolution |

## Additional Resources

- Owner's Manual: https://groupondev.atlassian.net/wiki/spaces/CA1/pages/80836133107/Owner+s+manual
- Runbook (Confluence): https://groupondev.atlassian.net/wiki/spaces/CA1/pages/81363828743/Bhuvan+-+Runbook
- ORR: https://docs.google.com/document/d/1hGLism7_1w1e1EyxzT-FdgxMBtZW93wMrhXRWmx27E8
- PagerDuty: https://groupon.pagerduty.com/services/PL9ZARS
