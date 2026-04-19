---
service: "web-metrics"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| Readiness: `exec echo 'true'` | exec | 5 s | N/A |
| Liveness: `exec echo 'true'` | exec | 15 s | N/A |

Because this is a CronJob (not a long-running server), probes are simple echo commands. The real health signal is whether the job runs to completion and metric data appears in Wavefront.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `perf.crux.*` | gauge | CrUX loading experience metrics per page/platform/country (LCP, CLS, FCP, FID percentiles and distributions) | Configured in Wavefront |
| `perf.crux.lighthouse.*` | gauge | Lighthouse audit scores embedded in PSI response (performance score, accessibility score, per-audit values) | Configured in Wavefront |
| `perf.lighthouse.*` | gauge | Standalone Lighthouse lab data (currently disabled in production) | Configured in Wavefront |
| iTier instrumentation counters | counter | Internal run telemetry: `run` timer per service name, `service loaded`, `service tested` events | Configured in Wavefront |

Metric tags applied to every data point: `appname`, `country`, `platform`, `path`, `env`, `perfrun`, `group`, `component`, `az`, `source`, `atom`, `service`.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Web Metrics | Wavefront | https://groupon.wavefront.com/dashboards/Web-Metrics |
| PageSpeedInsight CrUX | Wavefront | https://groupon.wavefront.com/dashboards/PagesSpeedInsight-Crux |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Missing CrUX data | Metric points absent for >2 CronJob cycles | warning | Check pod logs; trigger one-off job; see "Data is missing from dashboard" section below |
| Pod crash loop | CronJob restarts exceed backoff limit (6) | critical | Delete active pod to force fresh start; inspect termination logs |
| SRE alert channel | `seo_alerts@groupon.com` / GChat space `AAAANlivtII` | varies | Triage via Splunk (sourcetype `web-metrics_cron-job`, index `steno`) |

## Common Operations

### Trigger a One-Off Job

To run the CronJob immediately without waiting for the scheduled time:

```sh
kubectl create job oneoff --from=cronjob/web-metrics--cron-job--default
```

### Restart / Kill Active Pod

Kill the active pod so Kubernetes starts a fresh one:

```sh
kubectl delete pod {podId}
```

Replace `{podId}` with the active pod name from `kubectl get pods -n web-metrics-<env>`.

### Tail Live Logs

```sh
kubectl logs --follow web-metrics--cron-job--default-<hash>-<id> main
```

### View Previous Pod Termination Logs

Useful when a pod has already exited:

```sh
kubectl logs --previous web-metrics--cron-job--default-<hash>-<id> main
```

### List Available Artifacts

```sh
npx nap artifacts --available staging us-central1
```

### Local Dry Run

Run against a config file without sending data to Telegraf:

```sh
./cli.js start --config input-example-global-seo.json --appName global-seo --dryRun
```

### Scale Up / Down

Scaling is controlled via Helm values (`minReplicas`/`maxReplicas`). Because this is a CronJob, replica scaling determines how many concurrent job pods can run, not long-running capacity. Submit a Deploybot deployment with updated values to change limits.

### Database Operations

> Not applicable — this service has no database.

## Troubleshooting

### Data is missing from the dashboard

- **Symptoms**: Wavefront dashboards show gaps; `perf.crux.*` metrics absent for expected time window
- **Cause**: Pod crashed (OOM, Chrome crash, unhandled exception) and the CronJob exceeded its backoff limit, or the PSI API was unavailable
- **Resolution**:
  1. Check pod status: `kubectl get pods -n web-metrics-<env>`
  2. If pods are in `Error` or `CrashLoopBackOff`: `kubectl delete pod {podId}` to force a new start
  3. If the issue persists, check logs with `kubectl logs --previous ...`
  4. Verify Telegraf gateway is reachable from within the cluster
  5. Confirm PSI API key is valid and not quota-exhausted

### Pod keeps restarting or stalling

- **Symptoms**: CronJob restarts detected; backoff exceeded; pods terminating repeatedly
- **Cause**: Chrome subprocess crash, Node.js OOM, or Lighthouse timeout
- **Resolution**:
  1. Inspect termination reason: `kubectl describe pod {podId}`
  2. Check `kubectl logs --previous` for OOM killer or timeout messages
  3. If OOM: increase `memory.main.limit` in the relevant deploy config and redeploy
  4. If Chrome crash: the retry logic in `lighthouseRunner.js` handles up to 5 retries; if it still fails, check Chrome flags or temporarily disable the affected perfRun config

### PSI API returning errors

- **Symptoms**: `psi api error` log entries in Splunk (sourcetype `web-metrics_cron-job`)
- **Cause**: API quota exceeded, network issue, or invalid URL in config
- **Resolution**:
  1. Search Splunk for `psi api error` to identify which `perfRun`/`cruxRun` is failing
  2. Verify the URL is reachable from production environments
  3. Check Google API Console for quota usage on the key in `lib/defaultConfigs.js`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Complete loss of metric data for all pages | Immediate | SEO team (seo-dev@groupon.com), SRE (seo_alerts@groupon.com) |
| P2 | Partial metric data loss (some pages/regions missing) | 30 min | SEO team (seo-dev@groupon.com) |
| P3 | Occasional gaps; non-critical pages missing | Next business day | SEO team via GSEO Jira ticket |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Google PageSpeed Insights API | Per-run error catch in `pageSpeedInsightsRunner.js`; check API status at https://developers.google.com/speed/pagespeed/insights/ | Failed run is skipped; remaining runs continue |
| Telegraf metrics gateway (`metrics-gateway-vip.snc1`) | Write error catch in `lib/telegraph.js` | Data for that invocation is lost; no retry on write failure |
| Kubernetes CronJob scheduler | `kubectl get cronjob -n web-metrics-<env>` | Trigger one-off job manually |
