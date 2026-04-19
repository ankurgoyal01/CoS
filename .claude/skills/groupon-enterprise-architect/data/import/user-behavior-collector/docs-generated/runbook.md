---
service: "user-behavior-collector"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `checkBatchJob` cron script | exec (grep log for "EC batch job succeeded") | Daily — NA: 18:00 UTC, EMEA: 06:00 UTC | N/A |
| `ps aux | grep user-behavior-collector-jar-with-dependencies.jar` | exec | Manual | N/A |
| `tail -100 /var/groupon/log/user-behavior-collector/production.log.latest` | log inspection | Manual | N/A |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `custom.ubc.spark.api-proxy` | counter | HTTP response counts for GAPI calls; tagged by `http.resp` code | No evidence found in codebase |
| `custom.ubc.spark.deal-catalog` | counter | HTTP response counts for Deal Catalog calls | No evidence found in codebase |
| `custom.ubc.spark.voucher-inventory` | counter | HTTP response counts for VIS calls | No evidence found in codebase |
| `custom.ubc.spark.ams` | counter | HTTP response counts for Audience Management Service calls | No evidence found in codebase |
| `custom.ubc.spark.wishlist-service` | counter | HTTP response counts for Wishlist Service calls | No evidence found in codebase |
| `custom.ubc.spark.api-proxy.exception` | counter | Exception counts for GAPI calls | No evidence found in codebase |
| `custom.ubc.spark.ams.exception` | counter | Exception counts for Audience API calls | No evidence found in codebase |

All metrics are tagged with `service=user-behavior-collector`, `source=ubc_gcp_spark`, and `env`.

### Dashboards

> No evidence found in codebase. Metrics are sent to InfluxDB via Telegraf; dashboards would be in Grafana/InfluxDB but are not referenced in the repository.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `[EC] Batch job failed` | Job exits with non-zero status | critical | PagerDuty page to `targeted-deal-message@groupon.pagerduty.com`; check `[EC] Job Result` email for failure step |
| `EC NA batch may not finish. Please Check.` | `checkBatchJob` script does not find "EC batch job succeeded" in log | warning | Alert to `targeted-deal-message-alerts@groupon.com`; check log and rerun |
| `[EC] Batch job failed to publish audience` | `publish_audience` script exits non-zero | critical | PagerDuty; rerun with `-publishAudienceOnly` |
| `[EC] Batch job failed to update wishlist` | `update_wishlist` script exits non-zero | critical | PagerDuty; rerun with `-updateWishlistOnly` |

## Common Operations

### Restart Service

The service has no persistent daemon; it runs as a cron-triggered JAR. To trigger a manual run:

1. SSH into the production host (`emerging-channels-utility3.snc1` for NA, `emerging-channels-emea4.snc1` for EMEA)
2. Edit the relevant script in `/var/groupon/user-behavior-collector/` to set desired skip flags
3. Temporarily modify the cron in `/etc/cron.d/user-behavior-collector` to a time 5 minutes in the future
4. Revert cron and script after the job completes

### Scale Up / Down

Spark parallelism is controlled by the gdoop YARN cluster configuration. To limit files processed per run, pass `--maxFiles <N>` to the Spark job arguments (modify the cron script temporarily).

### Database Operations

**Advance the Kafka file pointer manually** (if Spark job fails and files must be skipped):

1. SSH into the production host
2. Connect to the production PostgreSQL database (`deal_view_notification`)
3. Update `key-value-store` table: set `value` to the desired next Janus file path for key `next-kafka-file`

**Cleanup aged records** (EMEA: runs via `cleanupDB` cron daily at 02:00; NA: no automated cleanup cron observed):

- `clearOldSendlog(normalSendlogRetentionDays, wishlistSendLogRetentiondays)` in `AppDataConnection`
- `clearOldEmailOpen(emailOpenRetentionDays)` in `AppDataConnection`

## Troubleshooting

### Batch Job Fails at Spark Step

- **Symptoms**: `[EC] Job Result` email does not contain "Saved user search data" or "Saved email open data" log lines; PagerDuty alert received
- **Cause**: Spark job failure (YARN unavailable, HDFS error, OOM on driver, bad input file)
- **Resolution**:
  1. Check `/var/groupon/log/user-behavior-collector/stderr.log` for Java stack trace
  2. If too late to retry that day's Spark job, advance `next-kafka-file` in `key-value-store` table to skip
  3. If retrying: modify `update_deal_views` script to add `-skipUpdateHistoryData` if only deal info step needed; otherwise rerun full job

### Batch Job Fails at Deal Info Step

- **Symptoms**: `[EC] Job Result` email does not contain "Dealinfo persist to redis" or "Dealinfo table populated"
- **Cause**: GAPI, Deal Catalog, or Redis unavailability
- **Resolution**: Check dependency health; rerun with `-skipUpdateHistoryData` to skip Spark and go directly to deal info refresh

### Batch Job Fails at Wishlist Step

- **Symptoms**: `[EC] Job Result` email does not contain "Wishlist info updated"
- **Cause**: Wishlist Service connectivity issues
- **Resolution**: Rerun with `-updateWishlistOnly`

### Batch Job Fails at Audience Publish Step

- **Symptoms**: `[EC] Job Result` email does not contain "Finish audience publishing"
- **Cause**: AMS API unavailable; Cerebro HDFS write failure; retry exhausted after 3 attempts
- **Resolution**: Rerun with `-publishAudienceOnly`

### Batch Job Did Not Finish On Time

- **Symptoms**: `checkBatchJob` alert email "EC NA/EMEA batch may not finish. Please Check." received
- **Cause**: Job still running (slow Spark cluster) or job silently failed without exit code
- **Resolution**:
  1. SSH to host; run `ps aux | grep user-behavior-collector-jar-with-dependencies.jar`
  2. If running: check `tail -100 /var/groupon/log/user-behavior-collector/production.log.latest` for progress
  3. If not running: check stderr.log and rerun appropriately

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Batch job completely fails; audience not published; notifications not triggered | Immediate | Emerging Channels on-call via PagerDuty (`targeted-deal-message@groupon.pagerduty.com`) |
| P2 | Individual step fails (wishlist, audience only); partial impact on notification campaigns | 30 min | Emerging Channels on-call |
| P3 | Metrics not emitting; checkBatchJob warning without actual failure | Next business day | Emerging Channels team (`emerging-channels@groupon.com`) |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumDealViewNotificationDb` (PostgreSQL) | Connect on startup (`AppDataConnection` constructor) | Job fails immediately; PagerDuty alert |
| `continuumDealInfoRedis` | Jedis connection attempt | No evidence of explicit health check; write failures logged |
| GAPI | HTTP 200 check per deal call | Returns `Optional.absent()`; deal skipped |
| Wishlist Service | HTTP 200 check per consumer | Returns empty list; wishlist not updated for that consumer |
| VIS | HTTP 200 check per availability request | Returns `false`; deal not marked back-in-stock |
| AMS (Audience API) | HTTP response per API call | Retried 3x with exponential backoff; throws RuntimeException if all retries fail |
| YARN / HDFS | Spark job submission | Job fails; full batch failure; PagerDuty alert |
