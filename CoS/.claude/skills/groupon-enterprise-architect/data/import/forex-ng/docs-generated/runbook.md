---
service: "forex-ng"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP | JTier default (heartbeat-based) | Not explicitly configured |
| S3 sentinel file `grpn/healthcheck` | S3 read/write | After every rate refresh | Per S3 operation timeout |
| Dropwizard health check registry (`ForexHealthCheck`) | Internal | On-demand via admin port | Immediate (arithmetic check) |

The service exposes a heartbeat file at `./heartbeat.txt` (configured in `development.yml`). The S3 health check sentinel is written and verified after every rate update in `AWSS3ForexStore.updateConversionRates()`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Quartz job execution (JTier default) | counter | Count of `ExchangeRatesUpdaterJob` executions | Operational procedures to be defined by service owner |
| JVM memory usage | gauge | Heap and non-heap memory utilization | Operational procedures to be defined by service owner |
| HTTP request rate/latency (JTier default) | histogram | Dropwizard metrics on `/v1/rates/` endpoint | Operational procedures to be defined by service owner |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Forex Production EU West 1 | Wavefront | https://groupon.wavefront.com/dashboards/forex-prod-eu-west-1 |
| Forex Production US West 1 | Wavefront | https://groupon.wavefront.com/dashboards/forex-prod-us-west-1 |
| Forex Staging US West 1 | Wavefront | https://groupon.wavefront.com/dashboards/forex-staging-us-west-1 |
| Forex Staging US West 2 | Wavefront | https://groupon.wavefront.com/dashboards/forex-staging-us-west-2 |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Rate refresh failure | Quartz job throws `DataProviderException` or `SanityFailedException` | critical | Check NetSuite API reachability; inspect Steno logs for error details; manually trigger `refresh-rates` CLI |
| S3 write failure | `AWSS3Client.writeData` returns false after 3 retries | critical | Check AWS credentials (IRSA token); verify `FOREXS3_S3_BUCKET_NAME`; check S3 bucket permissions |
| Sanity check failure | `AWSS3Sanity.doSanity` throws `SanityFailedException` | critical | Inspect `tmp_rates/` or `v1/rates/` for missing or stale JSON files; verify NetSuite data freshness |
| PagerDuty service | Any P1/P2 alert | critical | https://groupon.pagerduty.com/services/P4TZ4L9 |

Alert notifications: `forex-alerts@groupon.com`

## Common Operations

### Restart Service

For Kubernetes cron job deployments: the service runs as a one-shot cron job pod. There is no long-running pod to restart. To force an immediate rate refresh:

1. Trigger the `refresh-rates` CLI command manually via `kubectl exec` or a one-off Kubernetes job.
2. Alternatively, trigger a new cron job execution via the DeployBot UI or `kubectl create job --from=cronjob/forex`.

For legacy snc1 deployments: follow standard JTier service restart procedures (`jtier restart forex`).

### Scale Up / Down

Scaling is not applicable to the cron job component — each run is a single pod executing `refresh-rates` then exiting. To adjust resource allocation, update CPU/memory values in `.meta/deployment/cloud/components/cron-job/production-{region}.yml` and redeploy.

### Force Rate Refresh

Run the `refresh-rates` Dropwizard command:
```
java -jar forex.jar refresh-rates /path/to/config.yml
```

Or trigger a one-off Kubernetes job from the cron job template. This is also accessible via the admin endpoint `GET /v1/rates/data` on the HTTP server instance.

### Database Operations

> Not applicable. No relational database or schema migrations exist. All data is in S3 object storage.

To inspect the current rate files:
- Read from S3 bucket: `aws s3 ls s3://{FOREXS3_S3_BUCKET_NAME}/v1/rates/`
- Read a specific rate: `aws s3 cp s3://{FOREXS3_S3_BUCKET_NAME}/v1/rates/USD.json -`

## Troubleshooting

### Rate data is stale or missing

- **Symptoms**: API consumers receive 200 but with a `timestamp` older than 24 hours; or the API returns `null`/empty content
- **Cause**: The rate refresh job has not run successfully; NetSuite returned empty data; or S3 copy failed and `v1/rates/` was not updated
- **Resolution**:
  1. Check Wavefront dashboards for job execution metrics
  2. Search Steno logs for `DataProviderException`, `SanityFailedException`, or `SanityFailedException` entries
  3. Verify S3 bucket contents: `v1/rates/` should have one `.json` file per configured currency
  4. Verify `grpn/healthcheck` sentinel exists and contains `OK`
  5. Trigger a manual `refresh-rates` execution and observe logs

### API returns HTTP 400 for valid currencies

- **Symptoms**: `GET /v1/rates/USD.json` returns 400
- **Cause**: Missing `.json` extension in the request path; or the regex `[A-Za-z]{6}|[A-Za-z]{3}` does not match (e.g., numeric characters, wrong length)
- **Resolution**: Confirm the request URL includes the `.json` extension and uses a valid 3- or 6-letter uppercase currency code

### NetSuite API call failures

- **Symptoms**: Log entries: `error occured while fetching data from netsuite`; `Netsuite call failed`
- **Cause**: NetSuite endpoint unreachable; authentication token (`h` parameter) expired; network timeout
- **Resolution**:
  1. Verify connectivity to `https://1202613.extforms.netsuite.com/` from within the pod
  2. Check if `maxRetryCount` retries have been exhausted (inspect log for retry attempt counts)
  3. Contact the Orders team to verify NetSuite scriptlet configuration

### AWS S3 write failures

- **Symptoms**: Log entries: `Skipping updation of the following files after retry attempts`; rate refresh completes without updating `v1/rates/`
- **Cause**: IAM role permissions insufficient; wrong bucket name; AWS credential expiry
- **Resolution**:
  1. Verify pod is running with the correct service account and `AWS_ROLE_ARN` is set
  2. Check IAM role `forex-job` has `s3:PutObject`, `s3:GetObject`, `s3:CopyObject`, `s3:DeleteObject` on the forex bucket
  3. Confirm `FOREXS3_S3_BUCKET_NAME` matches the actual provisioned bucket name

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — API returning errors or rates unserved | Immediate | Orders team (`forex-alerts@groupon.com`); PagerDuty P4TZ4L9 |
| P2 | Degraded — rates stale but API responding | 30 min | Orders team via Slack `#orders-and-payments` |
| P3 | Minor impact — single region refresh failure | Next business day | forex@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| NetSuite Exchange Rates API | Make a test call to `/app/site/hosting/scriptlet.nl` with a known currency and today's date | No automatic fallback — the refresh job aborts and existing `v1/rates/` files remain unchanged |
| AWS S3 | Read `grpn/healthcheck` sentinel file; check AWS console or `aws s3 ls` on bucket | No automatic fallback — API reads from S3 will fail if the bucket is unreachable |

Full operational runbook (cloud): https://groupondev.atlassian.net/wiki/spaces/OO/pages/49646224425/Forex+Runbook+Cloud
