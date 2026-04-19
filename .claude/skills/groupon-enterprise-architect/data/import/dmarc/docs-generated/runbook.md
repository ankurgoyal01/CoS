---
service: "dmarc"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` | HTTP (returns `200 OK`, body `OK\n`) | Kubernetes default | Kubernetes default |
| `GET /` (catch-all) | HTTP (returns `200 OK`, body `OK\n`) | — | — |

The heartbeat HTTP server listens on port `8080` and is started as a goroutine at process startup, before any Gmail polling begins.

## Monitoring

### Metrics

> No evidence found in codebase. The service does not emit Prometheus, StatsD, or Datadog metrics. Operational visibility is provided entirely through ELK log analysis.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| DMARC Processing | ELK (Kibana) | `https://logging-us.groupondev.com/goto/a69682a0-eaa1-11ee-873b-8d61e2168108` |

### Alerts

> No evidence found in codebase. Alert configuration is managed externally (not visible in this repository). Recommended alert candidates based on log patterns:

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Gmail API fetch failure | `log.Fatalf("Error Creating Client")` or `log.Fatalf("Server Error")` appears in logs | critical | Check Gmail OAuth token validity; rotate if expired |
| No records written | Zero `JsonRecord` lines written in a polling window | warning | Check Gmail query returns results; verify Filebeat is running |
| Log file not growing | Filebeat source file stale for > 5 minutes | warning | Check container disk space; verify log writer goroutine is alive |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment: `kubectl get deployment -n dmarc-{production|staging}`
2. Roll out a restart: `kubectl rollout restart deployment/dmarc -n dmarc-{production|staging}`
3. Monitor rollout: `kubectl rollout status deployment/dmarc -n dmarc-{production|staging}`
4. Verify health endpoint responds: `curl http://<pod-ip>:8080/grpn/healthcheck`

### Scale Up / Down

Scaling is HPA-managed. To adjust bounds:
1. Update `minReplicas` / `maxReplicas` in the appropriate per-environment YAML (e.g., `.meta/deployment/cloud/components/app/production-us-west-2.yml`)
2. Redeploy via DeployBot or the Jenkins pipeline.

Note: The service polls a single shared Gmail mailbox. Running more than one replica in production means multiple pods will concurrently query the same unread message set — this may cause duplicate processing. Confirm idempotency behaviour before increasing `minReplicas` above 1.

### Database Operations

> Not applicable. The DMARC service does not own a relational database. The only "data store" is the rotating log file on the container's local filesystem, managed by lumberjack automatically.

### Rotating Gmail OAuth2 Credentials

1. Generate a new OAuth2 token for `svc_dmarc@groupon.com` using the existing `credentials.json`.
2. Update the `token/token.json` secret in the internal secrets repository at the path referenced by `.meta/.raptor.yml`.
3. Redeploy so the new secret is mounted into the container.

## Troubleshooting

### Service exits immediately on startup

- **Symptoms**: Container enters `CrashLoopBackOff`; logs show `Cannot open config file` or `Unable to parse client secret file`
- **Cause**: `config.toml` not present in working directory, or `credentials/credentials.json` secrets volume not mounted
- **Resolution**: Verify `config.toml` is baked into the image (`COPY config.toml /app/config.toml`); confirm the secrets volume is correctly mounted at `/app/credentials/` and `/app/token/`

### No DMARC records being written

- **Symptoms**: Log file exists but no new lines added; Gmail inbox shows unread messages
- **Cause**: OAuth2 token expired; Gmail query not matching; attachment parsing failure
- **Resolution**: Check logs for `"Error Creating Client"` or `"Unable to retrieve labels"` — if seen, rotate the `token.json`. Check for `"Error Parsing Gzip"` or `"Error Creating Zip"` — indicates unsupported attachment format from a sending mail server.

### High volume of `No Attachment, continuing....` log lines

- **Symptoms**: Repeated log entries for messages skipped due to missing attachment
- **Cause**: Non-DMARC emails delivered to the `svc_dmarc@groupon.com` mailbox, or DMARC reports with inline (non-attached) XML
- **Resolution**: Refine the Gmail query in `config.toml` to filter more precisely; manually delete non-DMARC messages from the inbox.

### GeoIP lookups returning empty country codes

- **Symptoms**: `country_code: ""` in all log records
- **Cause**: `GeoIP.dat` failed to open (log: `"Could not open GeoIP database"`)
- **Resolution**: Verify `GeoIP.dat` is present in the image at `/app/GeoIP.dat`. The file is bundled at build time (`COPY GeoIP.dat /app/GeoIP.dat`). Rebuild the image if the file is missing or corrupted.

### Filebeat not shipping logs

- **Symptoms**: DMARC records accumulate in `/app/logs/dmarc_log.log` but do not appear in ELK
- **Cause**: Filebeat sidecar container crash or misconfiguration
- **Resolution**: Inspect the Filebeat sidecar container logs within the pod: `kubectl logs <pod> -c filebeat -n dmarc-{env}`. Verify `logConfig` in `common.yml` matches the actual log file path.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Gmail API unreachable; no DMARC data ingested | Immediate | MTA team on-call |
| P2 | Partial processing failure; some reports not parsed | 30 min | MTA team |
| P3 | ELK not receiving logs; data delayed but not lost | Next business day | MTA team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Gmail API | Implicit per-poll — errors logged; poller retries on next tick (1 min) | No fallback; records are not processed until Gmail is reachable |
| GeoIP database | Checked at startup; missing DB logs a warning and continues with empty country codes | Empty string `""` returned for `country_code` field |
| Filebeat / ELK | Not checked by application | Log lines are buffered on disk (up to ~2 GB across 10 × 200 MB files) before oldest are rotated out |
