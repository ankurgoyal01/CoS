---
service: "vss"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/status` on port 8080 | HTTP | JTier default | JTier default |

- Production URL: `https://vss.production.service.us-west-1.aws.groupondev.com/grpn/status`
- Heartbeat file: `/var/groupon/jtier/heartbeat.txt` — remove to take a server out of load balancer rotation

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `http.in.total-time.p99` (operation `/v1/vouchers/search`) | histogram | P99 latency for voucher search endpoint | > 2 sec → SEVERE |
| `http.in.total-time.count` (status `4*`, operation `/v1/vouchers/search`) | counter | 4XX error count on search endpoint | > 50 → SEVERE |
| `http.in.total-time.count` (status `5*`, operation `/v1/vouchers/search`) | counter | 5XX error count on search endpoint | > 50 → WARN |
| `logging.elastic.vss.VssJMSMsgProcessorErrors.userUpdateErrorCount` | counter | JMS user update processing errors | WARN > 5, SEVERE > 10 |
| `logging.elastic.vss.VssJMSMsgProcessorErrors.unitUpdateErrorCount` | counter | JMS unit update processing errors | WARN > 400, SEVERE > 500 |
| `logging.elastic.vss.vss-jmsmsg-processor-failure.jmsUserFailure.jmsUserFailCount` | counter | JMS user message processor hard failures | WARN > 1, SEVERE > 100 |
| `logging.elastic.vss.vss-jmsmsg-processor-failure.jmsUnitFailure.jmsUnitFailCount` | counter | JMS unit message processor hard failures | WARN > 1, SEVERE > 100 |
| Envoy `upstream-rq-5xx` rate for `vss-*` | gauge | 5XX rate at edge proxy layer | > 2% → SEVERE |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| VSS Application Dashboard | Wavefront | https://groupon.wavefront.com/dashboard/vss |
| VSS SMA Dashboard | Wavefront | https://groupon.wavefront.com/dashboards/vss--sma |
| VSS System Metrics | Wavefront | https://groupon.wavefront.com/u/5fGwVY7zPP?t=groupon |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| VSS V1 Voucher Search P99 | P99 latency `> 2 sec` on `/v1/vouchers/search` | SEVERE | Check DB latency; check upstream VIS and Users Service; restart impacted pods if isolated to one instance |
| VSS V1 Voucher Search 4XX | 4XX count `> 50` on `/v1/vouchers/search` | SEVERE | Review logs for client misconfiguration or missing required params; check `clientIds` whitelist |
| VSS V1 Voucher Search 5XX | 5XX count `> 50` on `/v1/vouchers/search` | WARN | Check MySQL connectivity; check upstream dependency health |
| VSS JMS Msg processor Errors | `userUpdateErrorCount > 5` (WARN) or `> 10` (SEVERE) | WARN / SEVERE | Check Kibana logs for JMS processing errors; verify mbus subscription health |
| VSS JMS Msg processor Errors UnitUpdateError | `unitUpdateErrorCount > 400` (WARN) or `> 500` (SEVERE) | WARN / SEVERE | Check inventory event format; verify VIS message schema compatibility |
| VSS JMS Msg processor Failure | `jmsUserFailCount > 1` (WARN) or `> 100` (SEVERE) | WARN / SEVERE | Check mbus subscription status; verify MySQL write availability |
| VSS JMS Msg processor Failure jmsUnitFailCount | `jmsUnitFailCount > 1` (WARN) or `> 100` (SEVERE) | WARN / SEVERE | Check mbus subscription status; verify MySQL write availability |
| vss - hb 5xx - us | 5XX rate from Envoy edge proxy `> 2%` | SEVERE | Verify pod health; check logs for application errors |
| VSS HB 5xx Error Rate (us-central1) | 5XX rate `> 1%` (WARN), `> 2%` (SEVERE) | WARN / SEVERE | Same as above; check GCP us-central1 cluster health |

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
```
kubectl config use-context vss-gcp-production-us-central1
kubectl rollout restart deployment/<deployment-name> -n vss-production
```

**On-prem (single server):**
```
ssh vss-serviceN.snc1
sudo /sbin/reboot
```

To remove a server from load balancer rotation without restart:
```
sudo rm -rf /var/groupon/jtier/heartbeat.txt
```

### Scale Up / Down

Scale via DeployBot HPA configuration or by updating `minReplicas`/`maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` and re-deploying.

Kubernetes HPA targets 100% CPU utilization; production scales from 1 to 15 replicas automatically.

### Database Operations

**Manual backfill trigger:**
```
POST /v1/backfill/units?startDate=<ISO8601>&endDate=<ISO8601>&inventoryServiceId=vis
```

**Update redemption status (range):**
```
GET /v1/vouchers/updateRedemptionStatus?startId=<id>&endId=<id>
```

**Merge voucher user table script:**
```
bash merge_voucher_user_table_script.sh
```
(Located at repository root — used for data migration operations.)

**Schema migrations:** Run automatically on service startup via `jtier-migrations`.

## Troubleshooting

### High Search Latency (P99 alert)

- **Symptoms**: Wavefront alert fires for P99 `> 2 sec` on `/v1/vouchers/search`
- **Cause**: MySQL read replica overload, slow full-table scan, or a single pod with degraded performance
- **Resolution**:
  1. Check Wavefront latency by host to identify if a single pod is affected
  2. Check MySQL DaaS dashboard for replica lag or slow query log
  3. Restart the affected pod: `kubectl delete pod <pod-name> -n vss-production`
  4. If MySQL-wide: escalate to DaaS team

### JMS Message Processing Errors

- **Symptoms**: `VssJMSMsgProcessorErrors` alert fires; mbus dashboard shows unconsumed messages accumulating
- **Cause**: Message format change from upstream (VIS or Users Service), or MySQL write failure
- **Resolution**:
  1. Check Kibana logs: `index=main sourcetype=vss` filtered for ERROR level
  2. Verify mbus subscription health at mbus-dashboard links in `doc/owners_manual.md`
  3. Verify MySQL master write availability
  4. If due to schema mismatch, coordinate with upstream team; may require `mbusEnable=false` config change to stop consuming until fix is deployed

### 4XX Errors Spike

- **Symptoms**: Wavefront alert fires for 4XX `> 50` on search endpoint
- **Cause**: Missing required `clientId` or `merchantId` params; unregistered `clientId` in the `clientIds` whitelist
- **Resolution**:
  1. Check Kibana for the specific error responses
  2. Verify calling client is using correct params
  3. If `clientId` is valid but not whitelisted, add to `clientIds` config and redeploy

### Pod Not Receiving Traffic

- **Symptoms**: Load balancer reports one pod as unhealthy
- **Cause**: `/grpn/status` endpoint returning non-200, or heartbeat file missing
- **Resolution**:
  1. `kubectl logs <pod-name> main` to check for startup errors
  2. `kubectl exec -it <pod-name> --container main -- /bin/bash` to inspect pod state
  3. Verify heartbeat file: `/var/groupon/jtier/heartbeat.txt` must exist

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down — Merchant Centre voucher search unavailable | Immediate | geo-team via PagerDuty (`vss@groupon.pagerduty.com`); service PD: https://groupon.pagerduty.com/services/PK3CGBU |
| P2 | Degraded search performance or partial event processing failure | 30 min | geo-team Slack `#geo-services` |
| P3 | Single-host issue, elevated error rates within tolerable bounds | Next business day | geo-team email: `geo-team@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| VSS MySQL (continuumVssMySql) | Check DaaS MySQL dashboard; test connectivity via `kubectl exec` into pod | No fallback — MySQL is required for search and write operations |
| Users Service (continuumUsersService) | `GET /users/v1/accounts` with a known user ID | Backfill continues without user enrichment; existing cached user data serves search |
| VIS / VIS 2.0 | Health endpoint of respective service | Backfill fails for affected units; JMS-driven updates continue |
| mbus | mbus-dashboard subscription counts | Disable mbus via `mbusEnable=false` config and redeploy to stop consuming |

## Logging

| Environment | Log Tool | Link |
|-------------|----------|------|
| Production us-west-1 | Kibana | https://logging-us.groupondev.com/goto/61c26357b188783482175e310d24711c |
| Staging us-west-1 | Kibana | https://logging-stable-unified01.grpn-logging-stable.us-west-2.aws.groupondev.com/goto/3b82e4abe1d15b8f32ae63fe4f2d538a |
| Production Edge Proxy | Kibana | https://logging-us.groupondev.com/goto/f186e320-73e8-11ee-82f7-1f54a11f5b75 |

**Splunk queries (on-prem):**

Check HTTP status codes:
```
index=main sourcetype=vss
| spath name
| search name="http.in"
| timechart span=1m count by data.status
```

Check GET request latency:
```
index=main sourcetype=vss
| spath name
| search name="http.in"
| spath "data.method"
| search "data.method"=GET
| timechart perc99(data.time.total) as perc99, perc95(data.time.total) as perc95, avg(data.time.total) as avg span=1m
```
