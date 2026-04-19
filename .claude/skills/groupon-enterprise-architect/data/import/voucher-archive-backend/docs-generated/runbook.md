---
service: "voucher-archive-backend"
title: Runbook
generated: "2026-03-03T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/ls-voucher-archive/health` | http | > No evidence found in codebase. | > No evidence found in codebase. |
| `/ls-voucher-archive/health/db` | http | > No evidence found in codebase. | > No evidence found in codebase. |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `sonoma.voucher_archive.request.duration` | histogram | HTTP request duration across all endpoints | > No evidence found in codebase. |
| `sonoma.voucher_archive.request.count` | counter | Total HTTP request count | > No evidence found in codebase. |
| `sonoma.voucher_archive.resque.queue.depth` | gauge | Depth of the Resque job queue in Redis | > No evidence found in codebase. |
| `sonoma.voucher_archive.gdpr.erasure.processed` | counter | Count of GDPR erasure events processed | > No evidence found in codebase. |

> Metric names are derived from the sonoma-metrics 0.8.0 library pattern. Exact metric names require verification against service code.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| > No evidence found in codebase. | > No evidence found in codebase. | > No evidence found in codebase. |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High Resque queue depth | Resque queue depth exceeds threshold | warning | Check for failed workers; restart Resque workers |
| GDPR erasure failures | `RightToBeForgottenWorker` error rate elevated | critical | Inspect Resque failed queue; check Retcon Service health |
| Database connection failures | MySQL connection errors in application logs | critical | Verify database host reachability and credentials |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner.

1. Identify running container/process for `continuumVoucherArchiveBackendApp`
2. Issue a graceful restart (allow in-flight requests to complete)
3. Verify health endpoint `/ls-voucher-archive/health` returns 200
4. Monitor logs for startup errors

### Scale Up / Down

> Operational procedures to be defined by service owner.

Adjust the number of Puma workers in `config/puma.rb` or scale the deployment replicas via the orchestration platform. Resque worker counts may also need adjustment for background job throughput.

### Database Operations

- **Migrations**: Run via `bundle exec rake db:migrate` against the target database (specify `DATABASE_URL` for the correct database)
- **Backfills**: > No evidence found in codebase.
- **GDPR erasure verification**: Query the orders database to confirm PII fields have been overwritten after a `RightToBeForgottenWorker` run

## Troubleshooting

### Voucher retrieval returns 401 Unauthorized
- **Symptoms**: Consumers, merchants, or CSRs receive 401 responses
- **Cause**: Downstream auth service (Users Service, CS Token Service, or MX Merchant API) is unreachable or returning errors
- **Resolution**: Check connectivity to the relevant auth service; verify environment variable for service URL is correctly set

### GDPR erasure events not being processed
- **Symptoms**: `jms.topic.gdpr.account.v1.erased` events accumulate; no completion events published
- **Cause**: `RightToBeForgottenWorker` is not running, message bus connection is down, or Retcon Service is unavailable
- **Resolution**: Check Resque worker status in Redis; verify `MESSAGE_BUS_URL` and `RETCON_SERVICE_URL` environment variables; inspect failed jobs queue

### Voucher state transition failures (redeem/refund)
- **Symptoms**: PUT /redeem or /refund returns 422 or 500
- **Cause**: AASM state machine transition guard failing (voucher already redeemed, invalid state) or database write failure
- **Resolution**: Check application logs for AASM guard errors; verify orders database connectivity

### PDF / QR code generation failures
- **Symptoms**: GET /pdf or /qr_code returns 500
- **Cause**: pdfkit or rqrcode rendering failure, potentially a missing system dependency (wkhtmltopdf for pdfkit)
- **Resolution**: Verify wkhtmltopdf is installed in the container; check application logs for rendering errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no vouchers retrievable for consumers or merchants | Immediate | > No evidence found in codebase. |
| P2 | Degraded — partial failures (e.g., PDF generation, bulk redeem) | 30 min | > No evidence found in codebase. |
| P3 | Minor impact — background workers delayed, non-critical features unavailable | Next business day | > No evidence found in codebase. |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUsersService` | GET to Users Service health endpoint | Reject consumer requests with 503 |
| `continuumCsTokenService` | GET to CS Token Service health endpoint | Reject CSR requests with 503 |
| `continuumVoucherArchiveDealsDb` | `/ls-voucher-archive/health/db` | Return 503 on deal endpoints |
| `continuumVoucherArchiveOrdersDb` | `/ls-voucher-archive/health/db` | Return 503 on voucher/refund endpoints |
| `messageBus` | Message bus consumer connectivity check | GDPR events backlog on queue |
