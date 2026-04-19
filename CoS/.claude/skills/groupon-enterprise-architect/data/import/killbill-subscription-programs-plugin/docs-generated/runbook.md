---
service: "killbill-subscription-programs-plugin"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /plugins/sp-plugin/healthcheck/cloud` | http | 10s (readiness) / 15s (liveness) | 20s |
| `GET /plugins/sp-plugin/healthcheck` | http | On-demand | N/A |

The healthcheck reports healthy when all configured MBus listener threads are running. If any `MBusListener` thread is not running, the response is `unhealthy` with a message indicating how many of the total listeners are down (e.g., `1/3 MBus listener(s) down`).

- Readiness probe: `delaySeconds: 20`, `periodSeconds: 10`, `timeoutSeconds: 20`
- Liveness probe: `delaySeconds: 30`, `periodSeconds: 15`, `timeoutSeconds: 20`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Order create failure rate | counter (Splunk/Wavefront) | Tracks `step='createOrder.callGAPI.failure'` log events | Alert: [Order create failure in Subscription Engine](https://groupon.wavefront.com/alerts/1670926776672) |
| Order sync failure rate | counter (Splunk) | Tracks `step='syncOrder.callOrders.failure'` log events | See Splunk alerts |
| HTTP response time (tp90) | histogram | GET: target < 50ms; POST: target < 500ms | Wavefront dashboards |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Kill Bill Subscription Engine (on-prem) | Wavefront | https://groupon.wavefront.com/dashboard/kb-se |
| Kill Bill Subscription Engine Staging (on-prem) | Wavefront | https://groupon.wavefront.com/dashboard/kb-se_staging |
| Subscription Engine SP Cloud Production | Wavefront | https://groupon.wavefront.com/dashboards/Subscription-Engine-SP-Cloud-Production |
| Conveyor Cloud Production | Wavefront | https://groupon.wavefront.com/dashboards/se_conveyor_cloud_production |
| Conveyor Cloud Staging | Wavefront | https://groupon.wavefront.com/dashboards/se_conveyor_cloud_staging |
| Hybrid Boundary Production | Wavefront | https://groupon.wavefront.com/dashboards/se_hybrid_boundary_production_service |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Order create failure in Subscription Engine | Elevated `createOrder.callGAPI.failure` log step rate | critical | Check Kibana logs; escalate to Orders and GAPI teams if needed |
| Pod restart / CrashLoopBackOff | Kubernetes pod restart events | critical | Check `kubectl describe pod/$POD-NAME`; look for OOMKilled (exit 137) |
| MBus listener down | Healthcheck returns unhealthy | critical | Restart pod; check MBus broker connectivity |

## Common Operations

### Restart Service

**Cloud (Kubernetes):**
```
kubectl cloud-elevator auth
kubectx production-us-west-1        # or stable-us-west-1 for staging
kubens subscription-engine-production-sox
kubectl rollout restart deployment/subscription-engine--app--default
```

**On-premises (Ansible/Tomcat):**
```
# Start
sudo -p -H -u tomcat CATALINA_HOME=/opt/apache-tomcat-8.5.16 CATALINA_BASE=/var/groupon/apache-tomcat CATALINA_PID=/var/groupon/apache-tomcat/tomcat.pid JAVA_HOME=/usr/local /opt/apache-tomcat-8.5.16/bin/catalina.sh start

# Stop
sudo -p -H -u tomcat CATALINA_HOME=/opt/apache-tomcat-8.5.16 CATALINA_BASE=/var/groupon/apache-tomcat CATALINA_PID=/var/groupon/apache-tomcat/tomcat.pid JAVA_HOME=/usr/local /opt/apache-tomcat-8.5.16/bin/catalina.sh stop

# Check status
ps -ef | grep tomcat
```

### Scale Up / Down

Adjust `minReplicas` / `maxReplicas` in `.meta/deployment/cloud/components/app/production-us-central1.yml` and redeploy. HPA target utilization is `80%` CPU. Minimum production replicas is `2`; maximum is `8`.

### Manually Trigger an Order

If an invoice failed to trigger an order automatically, use:
```
curl -v \
    -u admin:password \
    -H "X-Killbill-ApiKey: GrouponPaidSub" \
    -H "X-Killbill-ApiSecret: GrouponPaidSub" \
    -H "Content-Type: application/json" \
    -H "X-Killbill-CreatedBy: $(whoami)" \
    -X POST \
    "http://kb-subscriptions1.snc1:8080/plugins/sp-plugin/orders/v1?invoiceId=<KB INVOICE ID>"
```

### Refresh Invoice State for an Order

Use when the invoice payment state needs to be re-synchronized with the Orders system:
```
curl -v \
    -u admin:password \
    -H "X-Killbill-ApiKey: GrouponPaidSub" \
    -H "X-Killbill-ApiSecret: GrouponPaidSub" \
    -H "Content-Type: application/json" \
    -X POST \
    "http://kb-subscriptions1.snc1:8080/plugins/sp-plugin/orders/v1/refresh?invoiceId=<KB INVOICE ID>"
```

### Database Operations

The plugin does not manage Kill Bill core schema migrations. Plugin-specific DDL is at `src/main/resources/ddl.sql`. To reinstall the plugin schema in a clean environment:
```
mysql -uroot killbill < src/main/resources/ddl.sql
```

## Troubleshooting

### createOrder Failures (GAPI errors)

- **Symptoms**: `ORDER_FAILED` custom field appears on invoices; Wavefront alert fires; Splunk step `createOrder.callGAPI.failure`
- **Cause**: GAPI (`api-lazlo`) returned a non-200 response or timed out; invalid billing record, user not found, or GAPI service degradation
- **Resolution**:
  1. Search Splunk: `index=main sourcetype="kb_se_tomcat" host="kb-subscriptions*" step="'createOrder.callGAPI.failure'"`
  2. Identify the `userId`, `subscriptionId`, `billingRecordId`, and `orderId` from the log
  3. Check with the GAPI/Orders team if a service degradation is occurring
  4. Manually re-trigger the order once the underlying issue is resolved using the `POST /plugins/sp-plugin/orders/v1?invoiceId=` endpoint

### MBus Listener Down

- **Symptoms**: Healthcheck returns unhealthy; ledger events are not being processed; invoice payment states are not updating
- **Cause**: MBus broker connectivity lost; listener thread died unexpectedly
- **Resolution**: Restart the pod (`kubectl rollout restart deployment/subscription-engine--app--default`); verify MBus broker is reachable from the pod network

### Pod OOMKilled (Exit Code 137)

- **Symptoms**: Kubernetes pod restart with exit code 137; `OOMKilled` in pod events
- **Cause**: JVM heap or native memory exceeded the container memory limit (16Gi)
- **Resolution**: Increase memory limit in `.meta/deployment/cloud/components/app/production-us-central1.yml`; redeploy via DeployBot

### Splunk Log Search

General application errors:
```
index=main sourcetype="kb_se_tomcat" host="kb-subscriptions*" log!="'PaymentRefresher'" log!="'PushNotificationListener'" log!="'BeatrixListener'" th!="'analytics_notifications-th'"
```

Trace a specific request by `rId`:
```
index=main sourcetype="kb_se_tomcat" host="kb-subscriptions*" rId='<request_id>'
```

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down; no subscription orders being created | Immediate | Select team on-call via `select-dev@groupon.pagerduty.com`; PagerDuty service `PRWGPNR` |
| P2 | Degraded; some orders failing; MBus listener partially down | 30 min | Select team on-call; Slack `#groupon-select-engg` |
| P3 | Minor impact; individual invoice failures | Next business day | Select team via `select-dev@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Lazlo GAPI (`api-lazlo`) | Splunk: `step='createOrder.callGAPI.failure'`; Wavefront alerts | Writes `ORDER_FAILED` on invoice; no automatic retry |
| Orders Service | Splunk: `step='syncOrder.callOrders.failure'` | Retry via Kill Bill notification queue (`sp_notifications`) |
| Groupon MBus | Plugin healthcheck endpoint | Events queue on MBus broker; listener reconnects on restart |
| MySQL (`daas_mysql`) | Kill Bill platform health; JDBC connection pool | Kill Bill platform handles DB reconnect |
