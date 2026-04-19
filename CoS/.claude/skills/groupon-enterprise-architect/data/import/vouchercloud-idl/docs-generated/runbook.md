---
service: "vouchercloud-idl"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/restful-api-heartbeat.html` | http (ALB health check) | 10 s | 5 s |
| `/vc-heartbeat.html` (Web tier) | http (ALB health check) | 10 s | 5 s |

- Healthy threshold: 3 consecutive successes
- Unhealthy threshold: 5 consecutive failures

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| ALB Latency | gauge | Average request latency (Release API) | Upper: 1 s triggers scale-up; Lower: 0.5 s triggers scale-down |
| CPUUtilization (Web) | gauge | Web tier CPU usage | Upper: 50% triggers scale-up; Lower: 20% triggers scale-down |
| CloudWatch custom timings | histogram | Buffered timing metrics submitted to CloudWatch (`CloudWatchTimingsBufferSize=10`) | Per-dashboard alert |
| Elastic APM transaction traces | histogram | Distributed traces for all incoming requests | Configured in Elastic APM UI |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Vouchercloud API (primary) | Wavefront | https://groupon.wavefront.com/u/3jkL07hXQl?t=groupon |
| Vouchercloud API (secondary) | Wavefront | https://groupon.wavefront.com/u/GWvJlp4tj9?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty: service degradation | ALB unhealthy instance or elevated error rate | P1/P2 | https://groupon.pagerduty.com/services/PZGV3HD — page on-call engineer |
| OpsGenie: vc-alerts | Infrastructure or dependency alert | P2/P3 | vc-alerts@groupondev.opsgenie.net |
| RewardsInitialiseFailed SNS | Giftcloud reward initialisation fails | P2 | Check Giftcloud API status; review SNS dead-letter for affected userIds |
| OfferRejection SNS | Volume spike in offer rejection events | P3 | Review MongoDB offer data quality; escalate to content team |

## Common Operations

### Restart Service

1. Open the AWS Elastic Beanstalk console for the environment (e.g., `vouchercloud-restful-api-release`).
2. Select "Restart App Server(s)" from the Actions menu.
3. Monitor the ALB health check endpoint (`/restful-api-heartbeat.html`) until all instances report healthy.
4. Verify Wavefront dashboard for error rate return to baseline.

### Scale Up / Down

- **Release (fixed fleet)**: Modify `MinSize` and `MaxSize` in `.aws/Release/IDL.Api.Restful.opt` and redeploy, or adjust directly in the EB console.
- **Staging (time-based)**: Scheduled auto-scaling is configured in `.ebextensions/staging-time-based-autoscaling-schedules.config` (scale down: `0 20 * * 1-5`, scale up: `0 6 * * 1-5` UTC).
- **Sprint/Feature**: Auto-scaling schedules in `.ebextensions/sprint-time-based-autoscaling-schedules.config` control dev environment capacity.

### Database Operations

- MongoDB: No migration tooling found in this repo. Schema changes are applied directly against MongoDB Atlas. Slow queries (>300 ms) are logged by the application (`SlowMongoQueryThresholdInMilliseconds=300`).
- SQL Server: No migration framework found in this repo. Schema changes applied via DBA tooling. Affiliate and main databases are separate credential sets.
- Redis: Cache invalidation is available via the internal `CacheService` (`/cache` endpoints with admin API key). Redis credentials are rotated via AWS Secrets Manager; instance restart required to pick up new credentials.

## Troubleshooting

### Service Fails to Start

- **Symptoms**: All ALB health checks fail immediately after deployment; instances cycle unhealthy.
- **Cause**: AWS Secrets Manager unreachable during boot, or PowerShell init script fails (check `.ebextensions/release-set-environment-variables.config`).
- **Resolution**: Check EC2 instance logs in EB console (`/var/log/` or Windows Event Viewer). Verify IAM role `idl-vpc-web-ec2-role` has `secretsmanager:GetSecretValue` permission for all required secrets. Re-trigger deployment after fixing IAM or network issue.

### High Latency on Offer Requests

- **Symptoms**: Wavefront shows p99 latency spike on offer/merchant endpoints; Elastic APM traces show MongoDB query times.
- **Cause**: Cache miss storm (Redis cold start or Redis failure); slow MongoDB queries exceeding 300 ms threshold (check NLog for slow query entries).
- **Resolution**: Verify Redis connectivity via EB environment logs. Trigger cache warm-up if needed. Check MongoDB Atlas for index usage and query plans. Review NLog for `SlowMongoQuery` entries.

### Giftcloud Rewards Failing

- **Symptoms**: `RewardsInitialiseFailed` SNS messages increasing; users unable to claim rewards.
- **Cause**: Giftcloud API outage; per-country credential expiry; test mode still enabled in production.
- **Resolution**: Verify `rewards.isTestMode="false"` in production `Web.config`. Check Giftcloud API status page. Rotate affected `GCAPI-{COUNTRY}-Live` secrets in AWS Secrets Manager and restart affected instances. Verify `IDL-VCAPI-GCAPI{country}*` env vars are correctly set post-restart.

### Algolia Search Returning No Results

- **Symptoms**: `/offers/search` returns empty results; no MongoDB errors in logs.
- **Cause**: Wrong `AlgoliaOfferIndexName` in config (staging index used in production); Algolia API key expired; index rebuild in progress.
- **Resolution**: Confirm `AlgoliaApplicationId` and `AlgoliaApiKey` in config match production Algolia dashboard. Verify index name (`OfferSearch_Production` vs `OfferSearch_Staging`). Check Algolia dashboard for index status.

### Authentication Failures (Apple / Facebook / Google)

- **Symptoms**: Social login requests returning 401; `AccessTokenVerificationService` errors in logs.
- **Cause**: Expired OAuth app secrets; Apple key rotation at `https://appleid.apple.com/auth/keys`; Facebook Graph API token validation failure.
- **Resolution**: For Apple: verify `oauth.apple.AppId` and JWT key URL is reachable. For Facebook: verify `oauth.facebook.AppId` and `AppSecret` in config. For Google: verify Google API credentials via `Google.Apis.Auth` configuration.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down (all health checks failing, no user traffic served) | Immediate | PagerDuty (`PZGV3HD`) + vc-techleads@groupon.com |
| P2 | Degraded (partial failures, rewards broken, search unavailable) | 30 min | PagerDuty + GChat space `AAAA547cZrg` |
| P3 | Minor impact (analytics events dropping, single country affected) | Next business day | GitHub issue at `https://github.groupondev.com/Coupons/vouchercloud-idl/issues/new` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MongoDB (`continuumVcMongoDb`) | Implicit: query success; NLog slow query log | No automatic fallback; API returns 500 if MongoDB unreachable |
| SQL Server (`continuumVcSqlDb`) | Implicit: session query success | No automatic fallback for sessions; user auth fails |
| Redis (`continuumVcRedisCache`) | Implicit: cache get/set success | `ISqlBackedCacheClient` provides SQL-backed fallback for sessions |
| Giftcloud API | HTTP response from `GCAPI-{country}-*` credentials | SNS `RewardsInitialiseFailed` published; rewards unavailable for affected country |
| Algolia | HTTP response from Algolia SDK | Search endpoint returns empty results; core offer listings unaffected |
| AWS SNS | AWS SDK success response | Notification events silently dropped; primary API response unaffected |
| AWS Secrets Manager | Boot-time only (PowerShell init) | Application fails to start if secrets unreachable at boot |
