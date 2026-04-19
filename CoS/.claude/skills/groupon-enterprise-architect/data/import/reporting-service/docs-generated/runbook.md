---
service: "reporting-service"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| No evidence found in architecture model | — | — | — |

> Operational procedures to be defined by service owner. Health check endpoints to be confirmed with the MX Platform Team.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Report generation duration | histogram | Time taken to generate a report from request to S3 upload | No evidence found |
| MBus consumer lag | gauge | Lag on PaymentNotification, ugc.reviews, VatInvoicing, BulkVoucherRedemption queues | No evidence found |
| S3 upload failures | counter | Number of failed S3 artifact uploads during report generation | No evidence found |
| Deal cap scheduler execution | counter | Successful and failed deal cap scheduler runs | No evidence found |
| Campaign scheduler execution | counter | Successful and failed weekly campaign report scheduler runs | No evidence found |

> Exact metric names and alert thresholds to be confirmed with the MX Platform Team.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| No evidence found | — | — |

> Dashboard configuration to be confirmed with the MX Platform Team.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Report generation failure | Report request remains in pending state beyond expected SLA | warning | Check S3 connectivity and external API availability; inspect logs for rendering errors |
| MBus consumer down | No messages processed for an extended period | critical | Verify MBus broker connectivity; check `reportingService_mbusConsumers` logs |
| Database connectivity loss | JDBC connection failure to any of six PostgreSQL instances | critical | Verify DB host reachability; check credentials; escalate to MX Platform Team |
| Deal cap scheduler failure | Scheduled job fails to complete | warning | Check ShedLock state; verify `continuumDealCapDb` connectivity and external API availability |

## Common Operations

### Restart Service

> Operational procedures to be defined by service owner. Restart procedure depends on the deployment orchestration used (see [Deployment](deployment.md)).

1. Drain in-flight requests via load balancer before stopping the instance.
2. Stop the WAR/servlet container process.
3. Verify all six PostgreSQL connections are released.
4. Start the servlet container with the WAR artifact.
5. Confirm health check passes before routing traffic.

### Scale Up / Down

> Operational procedures to be defined by service owner. Scaling procedure depends on the deployment orchestration. Confirm with MX Platform Team.

### Database Operations

- The service uses Hibernate 3.6.10 with six separate PostgreSQL data sources. Schema migrations are not managed by this service's repository (no migration path evidence found).
- To verify database connectivity: check JDBC connection pool status via JMX or application logs at startup.
- EhCache in-process cache can be cleared by restarting the service instance.

## Troubleshooting

### Report Not Downloadable After Generation

- **Symptoms**: `GET /reports/v1/reports/{id}` returns 404 or error after report was submitted
- **Cause**: S3 upload may have failed during `reportGenerationService` execution; `continuumFilesDb` may not have the file metadata record
- **Resolution**: Check `reportingService_s3Client` logs for upload errors; verify `continuumFilesDb` for file metadata entry; re-trigger report generation if needed

### Bulk Redemption CSV Upload Failing

- **Symptoms**: `POST /bulkredemption/v1/uploadcsvfile` returns error or vouchers not redeemed
- **Cause**: CSV format invalid, MBus publish failure, or downstream voucher service unavailable
- **Resolution**: Validate CSV format against expected schema; check `mbusProducer` logs for publish errors; verify MBus broker connectivity

### Deal Cap Scheduler Not Running

- **Symptoms**: Deal cap audit shows stale data; `GET /dealcap/v1/audit` returns outdated entries
- **Cause**: ShedLock 1.2.0 lock table contention, `continuumDealCapDb` connectivity issue, or `dealCapScheduler` exception
- **Resolution**: Check ShedLock lock table in `continuumDealCapDb`; release stale locks if necessary; review scheduler logs for exceptions

### MBus Consumer Falling Behind

- **Symptoms**: Delay in report data reflecting recent payments or reviews
- **Cause**: MBus broker backpressure, slow persistence via `reportingService_persistenceDaos`, or downstream trigger latency in `reportGenerationService`
- **Resolution**: Check MBus consumer group lag; inspect `reportingService_mbusConsumers` thread pool; verify `continuumReportingDb` write performance

### VAT Invoice Creation Failing

- **Symptoms**: `POST /vat/v1/invoices` returns error; VatInvoicing events not processed
- **Cause**: `continuumVatDb` connectivity issue, `fedVatApi` unavailable, or MBus VatInvoicing consumer exception
- **Resolution**: Verify `continuumVatDb` connectivity; check `fedVatApi` availability; inspect `reportingService_mbusConsumers` logs for VatInvoicing handler errors

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no reports accessible, MBus consumers not running | Immediate | MX Platform Team on-call |
| P2 | Degraded — report generation slow or failing for subset of merchants | 30 min | MX Platform Team |
| P3 | Minor impact — deal cap scheduler delayed, non-critical report failure | Next business day | MX Platform Team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumReportingDb` | JDBC connection pool status at startup and via JMX | No fallback; service cannot operate without core DB |
| `continuumDealCapDb` | JDBC connection pool status | Deal cap scheduling halts; audit endpoint unavailable |
| `continuumFilesDb` | JDBC connection pool status | Report download unavailable; generation may still succeed |
| `continuumVouchersDb` | JDBC connection pool status | Voucher reporting data unavailable for report generation |
| `continuumVatDb` | JDBC connection pool status | VAT invoicing endpoint unavailable |
| `continuumEuVoucherDb` | JDBC connection pool status | EU voucher reporting unavailable |
| `reportingS3Bucket` | AWS SDK connectivity check | Report artifacts not stored; download unavailable |
| `mbus` | Consumer group connectivity | Event-driven flows (payment, review, VAT) halt |
| `continuumPricingApi` | HTTP health check | Report generation fails for pricing-dependent report types |
