---
service: "expy-service"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/healthcheck` | http | Standard JTier interval | Standard JTier timeout |
| `/ping` | http | Standard JTier interval | Standard JTier timeout |

> Standard Dropwizard/JTier health check endpoints are expected. Confirm exact paths and thresholds with the Optimize team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Bucketing request rate | counter | Number of POST `/experiments` calls per interval | Not defined |
| Bucketing error rate | counter | Failed bucketing decisions | Not defined |
| Datafile refresh success | counter | Successful Quartz datafile refresh executions | Not defined |
| Datafile refresh failure | counter | Failed Quartz datafile refresh executions | Any failure |
| S3 copy success | counter | Successful daily S3 backup copy executions | Not defined |
| S3 copy failure | counter | Failed daily S3 backup copy executions | Any failure |
| Datafile parse errors | counter | Parse errors logged to MySQL during datafile ingestion | Any increase |
| MySQL connection pool usage | gauge | Active connections to `continuumExpyMySql` | >80% pool capacity |
| Cache hit rate | gauge | In-memory cache hits vs misses for projects and datafiles | Not defined |

> Specific metric names and alert thresholds are not defined in the architecture model. Confirm with the Optimize team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Expy Service operational | Grafana / Datadog | Confirm with Optimize team |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Datafile refresh failure | Quartz job fails to refresh datafile from Optimizely CDN or Data Listener | warning | Check Optimizely CDN availability; inspect MySQL datafile parse error logs; verify network connectivity to external endpoints |
| S3 backup failure | Daily S3 copy job fails | warning | Check AWS credentials; verify S3 bucket permissions on `optimizelyS3Bucket_84a1` and `grouponS3Bucket_7c3d` |
| MySQL connectivity lost | Service cannot reach `continuumExpyMySql` | critical | Verify MySQL cluster health; check connection pool configuration; escalate to DBA if needed |
| High bucketing error rate | POST `/experiments` error rate elevated | warning | Check Optimizely SDK initialization; verify datafile freshness in cache; inspect service logs |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Follow standard Kubernetes pod restart procedures for the Continuum platform.

### Scale Up / Down

> Operational procedures to be defined by service owner. Adjust Kubernetes HPA min/max replica settings or manually scale the deployment via kubectl.

### Database Operations

- Quartz job tables are managed automatically by `jtier-quartz-bundle` — do not modify manually.
- Datafile records accumulate over time; confirm with the Optimize team whether a retention/cleanup policy exists.
- Schema migrations follow the standard JTier migration pattern — confirm migration tool (Flyway/Liquibase) with service owner.

## Troubleshooting

### Stale Datafiles Being Served

- **Symptoms**: `/datafile/{sdkKey}` returns an outdated datafile; bucketing decisions use old experiment config
- **Cause**: Quartz datafile refresh job has failed or is not running; CDN or Data Listener unreachable; datafile parse error logged
- **Resolution**: Check Quartz job execution logs in MySQL Quartz tables; verify connectivity to `optimizelyCdnSystem_9d42` and `optimizelyDataListenerSystem_5b7f`; inspect datafile parse error records in `continuumExpyMySql`; manually trigger a refresh if supported

### Bucketing Decisions Returning Errors

- **Symptoms**: POST `/experiments` returns 5xx or unexpected bucketing results
- **Cause**: Optimizely SDK not initialized (missing or invalid datafile); cache miss with no fallback; downstream Optimizely API unavailable
- **Resolution**: Verify datafile is present and parseable in MySQL; check `expyService_cacheLayer` initialization on service startup; confirm Optimizely SDK version compatibility (optimizely-core-api 4.1.1)

### S3 Copy Job Not Running

- **Symptoms**: Groupon S3 bucket (`grouponS3Bucket_7c3d`) does not have updated datafiles after expected daily schedule
- **Cause**: AWS credential expiry or IAM permission change; Quartz scheduler not firing; S3 bucket policy change
- **Resolution**: Verify AWS IAM credentials in service configuration; check Quartz job trigger state in `continuumExpyMySql`; test S3 access manually using AWS CLI

### MySQL Connection Exhaustion

- **Symptoms**: Service returns errors on all data-dependent requests; logs show connection pool exhaustion
- **Cause**: Quartz jobs or API requests holding connections too long; MySQL cluster degraded
- **Resolution**: Check `continuumExpyMySql` cluster health; review connection pool settings in JTier config; restart service pods if needed to reset pool state

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — all bucketing and feature-flag APIs unavailable | Immediate | Optimize team (optimize@groupon.com) |
| P2 | Degraded — stale datafiles or elevated error rate on bucketing | 30 min | Optimize team |
| P3 | Minor impact — S3 backup failure, non-critical scheduled job failure | Next business day | Optimize team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumExpyMySql` | JDBC connectivity check via JTier healthcheck | Service cannot serve data-dependent requests |
| `optimizelyCdnSystem_9d42` | HTTP GET to Optimizely CDN datafile URL | Last cached datafile in MySQL continues to be served |
| `optimizelyDataListenerSystem_5b7f` | HTTP connectivity check | Last cached event datafile continues to be served |
| `optimizelyS3Bucket_84a1` | AWS S3 SDK list/head object | Daily S3 copy job will fail; primary bucketing unaffected |
| `grouponS3Bucket_7c3d` | AWS S3 SDK head bucket | Daily backup not stored; primary bucketing unaffected |
| `canaryApiSystem_2e31` | HTTP health check to Canary API | Canary traffic management unavailable; standard bucketing proceeds |
