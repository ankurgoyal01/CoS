---
service: "getaways-payment-reconciliation"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | HTTP | — | — |
| Kubernetes readiness probe | HTTP | 5 s period (60 s initial delay) | 60 s |
| Kubernetes liveness probe | HTTP | 15 s period (60 s initial delay) | 60 s |
| Admin port 8081 | HTTP | — | JTier Dropwizard admin metrics/health |

> The `.service.yml` sets `status_endpoint.disabled: true` for the environment poller; health is observed via Kubernetes probes only.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM memory / heap usage | gauge | Monitored via Elastic APM and JMX (port 8009) | No specific threshold documented |
| Worker reconciliation runs | counter | Periodic reconciliation worker executions | No specific threshold documented |
| Invoice import runs | counter | Email-triggered invoice import executions | No specific threshold documented |
| HTTP response codes (API) | counter | 4xx / 5xx rates on REST endpoints | No specific threshold documented |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Application logs | Kibana | `https://logging-us.groupondev.com/app/kibana#/discover` (index: `us-*:filebeat-getaways-payment-reconciliation_app*`, `us-*:filebeat-getaways-payment-reconciliation_worker*`) |
| APM traces | Elastic APM | Endpoint: `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200` |
| Service dashboards | Service Portal | `http://link.to/your/dashboard` (placeholder from `.service.yml`) |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty — service down | App or worker pods not running / health probe failing | P1 | Page on-call via `getaways-payment-reconciliation@groupon.pagerduty.com` |
| Invoice import failure | `invoice_importer_status.status = 'FAILURE'` for a given invoice date | P2 | Check Kibana worker logs; check Gmail inbox for malformed attachment |
| Reconciliation worker error | Exception in reconciliation worker logged to Kibana | P2 | Check Kibana app logs; verify Accounting Service and Maris availability |

## Common Operations

### Restart Service

```bash
kubectl cloud-elevator auth
kubectx production-us-central1
kubens getaways-payment-reconciliation-production-sox
kubectl rollout restart deployment/getaways-payment-reconciliation-app
kubectl rollout restart deployment/getaways-payment-reconciliation-worker
```

### Scale Up / Down

Edit `.meta/deployment/cloud/components/app/production-us-central1.yml` or `worker/production-us-central1.yml` and change `minReplicas` / `maxReplicas`. Redeploy via Deploybot. Verify with:

```bash
kubectl get pods -n getaways-payment-reconciliation-production-sox
kubectl describe pod <pod-name> -n getaways-payment-reconciliation-production-sox
```

### Database Operations

- Schema migrations run automatically on startup via `jtier-migrations`.
- To verify migration state, check JTier migration logs in Kibana on service startup.
- Manual DB access requires DaaS credentials from the Kubernetes secret; use `kubectl exec` to a pod and run `mysql` CLI.

### Manual Invoice Import

Pass a local file as the third argument to `InvoiceImporter.py` to bypass Gmail download:

```bash
python3 InvoiceImporter.py <config_yaml> <invoice_file_path>
```

## Troubleshooting

### Invoice import not running / no new invoice data

- **Symptoms**: `travel_ean_invoice` table not updated; `invoice_importer_status` shows no recent SUCCESS entries
- **Cause**: Gmail attachment not received; OAuth2 refresh token expired; `workerIsActive=false` in config; attachment file name does not match `attachment_regex`
- **Resolution**: Check worker Kibana logs (`us-*:filebeat-getaways-payment-reconciliation_worker*`); verify Gmail inbox for unprocessed emails; check OAuth2 token validity; confirm `workerIsActive` in JTier run config

### Reconciliation worker not running

- **Symptoms**: No periodic reconciliation log entries; merchant invoices not advancing to paid status
- **Cause**: `reconciliationWorkerIsActive=false`; Accounting Service unavailable (`isAccountingServiceEnabled=false`); DB connectivity issue
- **Resolution**: Check app Kibana logs; verify `reconciliationWorkerIsActive` and `isAccountingServiceEnabled` in JTier run config; verify Accounting Service availability

### MBus consumer not processing reservation events

- **Symptoms**: Reservation table not updated; reconciliation mismatches grow
- **Cause**: MBus topic connectivity issue; `marisUrl` misconfiguration
- **Resolution**: Check worker logs for JMS connection errors; verify Maris API reachability; check `marisMessageBusConsumer` config in JTier YAML

### OOMKilled pods

- **Symptoms**: Pods restarting with `OOMKilled` reason
- **Cause**: `MALLOC_ARENA_MAX` too high; heap size not tuned
- **Resolution**: Increase memory limits in `worker/production-us-central1.yml`; verify `MALLOC_ARENA_MAX=4` is set; check JVM heap flags in JTier parent POM

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down (no API, no reconciliation) | Immediate | getaways-payment-reconciliation@groupon.pagerduty.com; Slack: #getaways-cicd |
| P2 | Reconciliation delayed or invoice import failing | 30 min | Getaways Engineering on-call; getaways-eng@groupon.com |
| P3 | Minor: notification emails not sending; individual invoice errors | Next business day | Getaways Engineering via email alias |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Accounting Service | HTTP GET against service health endpoint (not explicitly configured); observe HTTP response codes in logs | `isAccountingServiceEnabled=false` disables calls; payments queue up |
| Maris Inventory API | Observe HTTP errors in Kibana worker logs | No fallback; MBus message processing fails and reservation is not persisted |
| Gmail IMAP/SMTP | Check worker logs for IMAP/SMTP exceptions | Invoice import skipped for the run; status recorded as FAILURE |
| MySQL | Kubernetes liveness probe fails if DB is unreachable | Pods restart; DaaS connection pool handles transient failures |

## Additional References

- Owners Manual: `OWNERS_MANUAL.md` in service repository
- Runbook (Confluence): `https://groupondev.atlassian.net/l/cp/V1YKVK7t`
- PagerDuty: `https://groupon.pagerduty.com/services/getaways-payment-reconciliation`
- Kibana logs (production): `https://logging-us.groupondev.com/app/kibana#/discover`
