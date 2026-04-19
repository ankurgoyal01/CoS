---
service: "mvrt"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/status.json` | http | Configured in `.service.yml` (currently `disabled: true`) | — |
| Kubernetes pod readiness | TCP port 8000 | Kubernetes default | Kubernetes default |
| Wavefront dashboards | metrics-based | Continuous | — |

> The `/status.json` endpoint is configured in `.service.yml` but marked `disabled: true`. Health monitoring relies on Kubernetes pod status and Wavefront metrics.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Request error rate | counter | HTTP 5xx errors across all endpoints | Alert: `mvrt_api_errors` — error rate exceeds expected count |
| Redemption failure count | counter | Count of failed voucher redemptions | Alert: `mvrt_redemption_failure` — failure count exceeds expected |
| Inventory product ID not found | counter | Count of vouchers missing inventory product ID | Alert: `mvrt_inventory_product_id_not_found` |
| Page load time TP50 | histogram | 50th percentile page load latency | SLA: 5 seconds |
| Page load time TP95 | histogram | 95th percentile page load latency | SLA: 12 seconds |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MVRT Endpoints Dashboard | Wavefront | https://groupon.wavefront.com/dashboard/mvrt |
| MVRT System Metrics | Wavefront | https://groupon.wavefront.com/u/bqMv8sBpln?t=groupon |
| DUB1 MVRT Dashboard | Wavefront | https://groupon.wavefront.com/dashboard/dub1-mvrt |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `mvrt_api_errors` | Error rate for an API exceeds expected count | P2 | Page corresponding API team (e.g., Candler/Voucher Inventory team) |
| `mvrt_inventory_product_id_not_found` | Inventory product ID missing for vouchers | P2 | Page Candler team |
| `mvrt_redemption_failure` | Redemption failure count exceeds expected | P2 | Check Splunk logs; if failure originates from API, page Candler team |

PagerDuty service: `https://groupon.pagerduty.com/services/PEGTTFB`

## Logging

- **Log aggregation**: ELK (Elasticsearch/Kibana)
  - EU-WEST-1 (production): https://logging-dub1.groupondev.com/goto/40a0506b1043d3316a9f6b73b135fa6a
  - STABLE US-WEST-2 (staging): https://logging-preprod.groupondev.com/goto/b787cca8e1acc1d7efddd9e134a4d764
- **Splunk query**: `index=steno sourcetype=mvrt_itier`
- **Trace keys in code**: `[JOB-INFO]`, `[JOB-ERROR]`, `[MAIL-SENT]`, `[MAIL-NOT-SENT]`, `[MAIL-RESEND]`, `[S3-BUCKET-INFO]`, `[S3-BUCKET-ERROR]`, `[FILE-UPLOAD-SUCCESS]`, `[FILE-UPLOAD-FAILURE]`, `[UNITS-REDEEM-ERROR]`, `[RedemptionBatch - DONE]`, `[JSON-PARSE-ERROR]`, `[API-ERROR]`, `[LDAP-FILTER-ENV]`, `[FAILED-PROCESSING-FILE]`

## Common Operations

### Restart Service

1. Authenticate: `kubectl cloud-elevator auth`
2. Set context: `kubectl config use-context mvrt-production-sox-eu-west-1`
3. Identify pods: `kubectl get pods -n mvrt-production-sox`
4. Delete pod to trigger restart: `kubectl delete pod <pod-name> -n mvrt-production-sox`
5. Verify new pod starts: `kubectl get pods -n mvrt-production-sox`
6. Monitor logs: `kubectl logs <new-pod-name> app -n mvrt-production-sox`

### Scale Up / Down

- Horizontal scaling is managed via Deploybot and Kubernetes HPA (min 2 / max 3 in production).
- Manual scale: `kubectl scale deployment mvrt --replicas=<N> -n mvrt-production-sox`
- Adding legacy on-prem capacity: procure servers, roll hosts with `skeletor_node` hostclass, add to `deploy.json`, deploy code, test, add to load balancer.

### Database Operations

> Not applicable. MVRT owns no relational database. All persistent data lives in downstream Continuum services. AWS S3 cleanup (stale report files) is handled manually if needed.

## Troubleshooting

### Offline Job Not Processing

- **Symptoms**: Users report that offline search results are not arriving by email; queue files accumulate in `CodesForOfflineSearch/Json_Files/`
- **Cause**: Lock file `CodesForOfflineSearch/sample.lock` may be stale (left over from a crashed job); or the node-schedule cron is not running
- **Resolution**: Log into the pod (`kubectl exec -it <pod-name> --container app -- /bin/bash`); check for stale lock file (stale after 4 hours); check cron logs for `[JOB-INFO]` entries every minute; remove stale lock file if present and verify the next cycle runs

### S3 Upload Failures

- **Symptoms**: Offline jobs complete search but fail to deliver reports; `[FILE-UPLOAD-FAILURE]` or `[S3-BUCKET-ERROR]` in logs
- **Cause**: Expired or invalid AWS S3 credentials in the secrets file; S3 bucket permissions changed; network connectivity from pod to S3
- **Resolution**: Verify S3 credentials in Kubernetes secrets; re-deploy after rotating credentials; check AWS S3 bucket policy; check VPC egress rules

### Redemption API Errors

- **Symptoms**: `mvrt_redemption_failure` alert fires; users see "Failed" status for vouchers
- **Cause**: Voucher Inventory Service (Candler) returning non-201 responses; voucher already redeemed; downstream outage
- **Resolution**: Check Splunk for `[UNITS-REDEEM-ERROR]` or `[API-ERROR]` entries; if failure is from Candler API, escalate to Candler team; check Candler/VIS dashboards

### Authentication Failures

- **Symptoms**: Users cannot log in or see unexpected access denials by country
- **Cause**: Okta group membership not matching expected Conveyor LDAP group prefix (`grp_conveyor_production_mvrt_` or `grp_mvrt.groupondev.com`); user not in correct country group
- **Resolution**: Verify user's Okta group membership in OGWALL; check `feature_flags.MVRT.ldap.group_env` matches the environment; see MVRT cloud runbook for LDAP group details

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; no redemptions possible | Immediate | MVRT team (mvrt-team@groupon.com), PagerDuty PEGTTFB |
| P2 | Degraded redemption success rate or offline jobs not processing | 30 min | MVRT team on-call |
| P3 | Minor impact (e.g., CSV download errors, single-country issue) | Next business day | MVRT team via Slack CG3QC2NR1 |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumVoucherInventoryService` | Check Candler service dashboards; verify `/units/search` responses in Splunk | No redemptions possible if down; display error to user |
| `continuumDealCatalogService` | Check Deal Catalog service dashboards | Deal metadata unavailable; search results will show partial data |
| `continuumM3MerchantService` | Check M3 Merchant service dashboards | Merchant name unavailable; search results will omit merchant name |
| AWS S3 | AWS Console or `aws s3 ls` from pod | Offline job cannot deliver reports; users receive error email |
| Rocketman | Check Rocketman service status | Email delivery silently fails; users do not receive report notification (retried 3 times) |
