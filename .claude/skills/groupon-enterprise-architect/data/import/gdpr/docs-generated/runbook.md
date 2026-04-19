---
service: "gdpr"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP — returns `ok` with HTTP 200 | Not specified in codebase | Not specified in codebase |

The health check endpoint has no dependencies — it returns `ok` unconditionally and does not verify downstream service connectivity.

## Monitoring

### Metrics

> No evidence found in codebase. No metrics instrumentation (Prometheus, Wavefront agent, etc.) is implemented in application code. Infrastructure-level metrics may be available via the Kubernetes cluster.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| GDPR Tool | Wavefront | https://groupon.wavefront.com/dashboard/gdpr-tool |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service on-call notification | PagerDuty service `PP81B2K` fires | Critical | Notify `application-operations@groupon.pagerduty.com`; check pod health, downstream service connectivity, and Wavefront dashboard |

## Common Operations

### Restart Service

1. Identify the Kubernetes namespace for the target environment: `gdpr-production` (production) or `gdpr-staging` (staging)
2. Use `kubectl` or the Groupon internal platform tools to rolling-restart the deployment:
   ```
   kubectl rollout restart deployment/gdpr -n gdpr-production
   ```
3. Monitor the rollout: `kubectl rollout status deployment/gdpr -n gdpr-production`
4. Verify the health check: `curl http://<pod-ip>:8080/grpn/healthcheck`

### Scale Up / Down

The service runs with a fixed replica count (`minReplicas: 1`, `maxReplicas: 1`). No HPA is configured. Scaling requires a change to the Helm values in `.meta/deployment/cloud/components/app/common.yml` or an environment-specific override file, followed by a new deployment.

### Database Operations

> Not applicable. This service is stateless and owns no database. All temporary files are automatically cleaned up after each export request completes.

### Triggering a Manual Export (CLI Mode)

The binary supports a `manual` subcommand for command-line export without the web UI:

```bash
./gdpr manual \
  -consumer_uuid=<uuid> \
  -consumer_country=<country-code> \
  -consumer_email=<email> \
  -agent_id=<agent-id> \
  -agent_email=<agent@groupon.com>
```

All five flags are required. The output ZIP archive is written to `os.TempDir()/<consumer_uuid>/`.

## Troubleshooting

### Export Fails with HTTP 500

- **Symptoms**: Agent receives a JSON error response from `POST /data` (e.g., `{"Orders error": "..."}`)
- **Cause**: One of the downstream service calls failed — most commonly the token service, Lazlo, or subscription service
- **Resolution**: Check the container logs for the specific downstream service error. Verify the service is reachable from the pod. Confirm `config/config.toml` is correctly mounted with valid API keys and hosts. Check the Wavefront dashboard for error rate spikes.

### Missing or Empty CSV in ZIP Archive

- **Symptoms**: The returned ZIP archive is missing one or more CSV files, or a CSV file contains only the header row
- **Cause**: The downstream service returned an empty dataset or a partial response
- **Resolution**: Verify the consumer UUID is valid and exists in the relevant systems. Check whether the consumer has data of that type (e.g., no reviews, no subscriptions). Review container logs for any warnings during data collection.

### `config/config.toml` Not Found at Startup

- **Symptoms**: Service fails to start with `log.Fatalln(err.Error())` — TOML decode error in logs
- **Cause**: The Kubernetes secret containing `config.toml` is not correctly mounted at `/app/config/config.toml`
- **Resolution**: Verify the Kubernetes secret exists in the correct namespace and that the volume mount in the Helm-generated manifest is correct. Redeploy after correcting the secret.

### Subscriptions Collector Panics

- **Symptoms**: Container crashes or restarts; logs show `panic` during subscription data collection
- **Cause**: `global-subscription-service` returned a response that could not be JSON-unmarshalled (e.g., HTML error page, malformed JSON)
- **Resolution**: Verify `global-subscription-service` is healthy and returning valid JSON. Check that the subscription service host in `config.toml` is correct for the environment.

### Agent Email Validation Failure

- **Symptoms**: Form re-renders with the message "Agent Email must be @groupon"
- **Cause**: The `agent_email` field submitted in the form does not contain the string `groupon`
- **Resolution**: Ensure the submitting agent uses their `@groupon.com` email address.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — agents cannot fulfil GDPR requests | Immediate | `application-operations@groupon.pagerduty.com` (PagerDuty `PP81B2K`); Slack `#gdpr-tool` |
| P2 | Partial failure — some export types failing (e.g., subscriptions) | 30 min | `application-operations@groupon.pagerduty.com`; Slack `#gdpr-tool` |
| P3 | Degraded performance — slow exports | Next business day | `aa-dev@groupon.com`; Slack `#gdpr-tool` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `cs-token-service` | Call `POST /api/v1/{country}/token` with test credentials | None — export aborts if token cannot be obtained |
| `api-lazlo` | Call a lightweight Lazlo endpoint with a known consumer | None — export aborts if Lazlo is unreachable |
| `global-subscription-service` | Call `GET /v2/subscriptions/user/{uuid}` | None — panic possible on malformed response |
| `ugc-api-jtier` | Call `GET /v1.0/users/{uuid}/reviews` | None — export aborts on failure |
| `m3-placeread` | Call `GET /placereadservice/v3.0/places/{uuid}` | None — export aborts on failure |
| `consumer-data-service` | Call `GET v1/consumers/{uuid}/locations` | None — export aborts on failure |

> Operational procedures to be defined by service owner for dependency health verification.
