---
service: "scs-jtier"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/grpn/status` (port 8080) | HTTP | Kubernetes liveness/readiness default | Default |
| Admin port 8081 (Dropwizard health checks) | HTTP | On-demand | Default |
| Hybrid Boundary UI — us-central1 | Dashboard | Continuous | — |
| Hybrid Boundary UI — eu-west-1 | Dashboard | Continuous | — |

- Hybrid Boundary (app, us-central1): `https://hybrid-boundary-ui.prod.us-central1.gcp.groupondev.com/services/shopping-cart-service-jtier/shopping-cart-service-jtier`
- Hybrid Boundary (app, eu-west-1): `https://hybrid-boundary-ui.prod.eu-west-1.aws.groupondev.com/services/shopping-cart-service-jtier/shopping-cart-service-jtier`

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `shopping.cart.service.custom` (tag: `type=abandoned.cart.publish.success`) | counter | Successful abandoned cart event publications per job run | Sudden drop to 0 |
| `shopping.cart.service.custom` (tag: `type=abandoned.cart.publish.failure`) | counter | Failed abandoned cart event publications | Any non-zero value |
| MySQL VIP status (`MySQL_VIP_goods_cart_svc_prod`) | gauge | MySQL VIP health — should remain OK | Any non-OK status |
| MySQL replication delay (`MySQL_Replication_Delay_goods_cart_svc_prod`) | gauge | Replication lag between primary and read replica | Excessive lag |
| MySQL connections (`MySQL Connections goods_cart_svc_prod`) | gauge | Number of active MySQL connections — must not reach limit | Near-max connections |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Application Metrics | Grafana | `https://stable-grafana.us-central1.logging.stable.gcp.groupondev.com/d/ae7pzovd5kr9cc/coreapps-app-metrics?var-service=shopping-cart-service-jtier` |
| Conveyor Cloud Metrics | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/fe7dii805648wc/conveyor-cloud-customer-metrics?var-namespace=shopping-cart-service-jtier-production` |
| DB Metrics | Grafana | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/d/ee7qj9jg2nv9cb/coreapps-db-metrics?var-service=shopping-cart-service-jtier` |
| ELK/Splunk (us-central1) | Kibana | `https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com/app/r/s/ltGa8` |
| ELK/Splunk (eu-west-1) | Kibana | `https://logging-prod-eu-unified1.grpn-logging-prod.eu-west-1.aws.groupondev.com/goto/f2d61d40-b405-11f0-b710-07c186712e87` |
| Wavefront (legacy) | Wavefront | `https://groupon.wavefront.com/dashboards/Shopping-Cart-Service-JTier-ELK-and-Splunk` |

Log source type: `cart_service_jtier` (configured via `stenoSourceType` in deployment manifests).

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | HTTP health check failing on all pods | P1 | Page on-call via PagerDuty (`https://groupon.pagerduty.com/services/PO3EK4Y`); check pod status with `kubectl get pods`; review logs |
| MySQL VIP down | `MySQL_VIP_goods_cart_svc_prod` reports non-OK | P1 | Contact GDS team (gds@groupon.com); check replication status |
| MySQL replication lag high | `MySQL_Replication_Delay_goods_cart_svc_prod` exceeds threshold | P2 | Contact GDS team; reads may return stale data |
| Abandoned cart publish failures | `abandoned.cart.publish.failure` counter non-zero | P2 | Check Mbus connectivity; review worker pod logs; verify `abandoned.carts` destination config |

PagerDuty: `https://groupon.pagerduty.com/services/PO3EK4Y`
Slack channel: `ugc` (channel ID in `.service.yml`)

## Common Operations

### Restart Service

1. Authenticate: `kubectl cloud-elevator auth`
2. Select context: `kubectl config use-context shopping-cart-service-jtier-production-us-central1`
3. Get all pods: `kubectl get pods -o wide`
4. View logs: `kubectl logs -f <pod_name>`
5. Execute shell in container: `kubectl exec -it <container_name> -c main -- /bin/sh`
6. For rolling restart: follow the [Rolling Restart Runbook](https://groupondev.atlassian.net/wiki/spaces/SCAS/pages/80769516059/Troubleshooting+Guide+for+a+Rolling+Restart)

### Scale Up / Down

1. Open `.meta/deployment/cloud/components/app/<environment>.yml`
2. Update `maxReplicas` to the desired value
3. Commit and redeploy the same image version via Deploybot — new pods will launch automatically

### Database Operations

- Database is managed by GDS team — contact gds@groupon.com for schema migrations or backfill operations
- Monitor VIP and replication delay metrics (listed above) after any schema change
- Full database documentation: `https://confluence.groupondev.com/display/SCAS/Database`

## Troubleshooting

### Incorrect Deal Setup
- **Symptoms**: Cart items failing purchasability validation; items being auto-removed from carts unexpectedly
- **Cause**: Deal data returned from `continuumDealService` is incorrect or missing
- **Resolution**: Verify deal configuration in the deal catalog; check deal service response in service logs (`cart_service_jtier` sourcetype); use `disable_auto_update=true` in requests to bypass auto-removal while investigating

### MySQL Connection Exhaustion
- **Symptoms**: Database timeouts or connection errors in logs; `MySQL Connections goods_cart_svc_prod` metric near maximum
- **Cause**: Too many concurrent requests holding open connections; connection pool misconfiguration
- **Resolution**: Reduce pod count if overloaded; verify connection pool settings in the YAML config; contact GDS for DaaS-level intervention

### Abandoned Cart Job Not Publishing
- **Symptoms**: `abandoned.cart.publish.failure` counter increasing; Regla team reports no abandoned cart emails
- **Cause**: Mbus connectivity issue; `abandoned.carts` destination misconfigured; `IS_CRON_ENABLED=false` on worker pods
- **Resolution**: Verify `IS_CRON_ENABLED=true` on `worker` component pods; check Mbus destination config; review worker pod logs for `publish_abandoned_carts_to_mbus_job_started` / `publish_abandoned_carts_to_mbus_job_success` events

### Cloud Conveyor / Kubernetes Access Issues
- **Symptoms**: Unable to connect to pods; `kubectl` commands fail
- **Resolution**:
  1. `brew install kubernetes-cli`
  2. `brew tap groupon/engineering git@github.groupondev.com:engineering/homebrew-groupon.git && brew install cloud-elevator`
  3. `kubectl cloud-elevator auth`
  4. `kubectx` — list available contexts (look for `shopping-cart-service-jtier-*`)
  5. `kubectl config use-context <context>` — select target environment

Full troubleshooting guide: `https://groupondev.atlassian.net/wiki/spaces/SCAS/pages/59871113661/Troubleshooting+Steps`

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — cart operations unavailable for customers | Immediate | UGC-Dev on-call via PagerDuty (`cart-jtier-alerts@groupon.pagerduty.com`) |
| P2 | Degraded — increased error rates or database issues | 30 min | UGC-Dev on-call; optionally GDS team for DB issues |
| P3 | Minor impact — non-critical job failures (e.g., abandoned carts) | Next business day | UGC-Dev team via `ugc` Slack channel |

SLA: 99.99% uptime; p99 response time < 1 second; criticality tier 2.

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumScsJtierReadMysql` | MySQL VIP metric; `MySQL_Replication_Delay_goods_cart_svc_prod` | No automatic fallback — reads will fail if replica is down |
| `continuumScsJtierWriteMysql` | MySQL VIP metric; connection count metric | No automatic fallback — writes will fail if primary is down |
| `continuumDealService` | Review downstream service health via its own dashboards | If down, purchasability validation fails; `disable_auto_update=true` can limit user impact |
| `continuumGoodsInventoryService` | Review downstream service health | Same as deal service |
| `continuumVoucherInventoryService` | Review downstream service health | Same as deal service |
| Mbus (message bus) | Review worker pod logs for publish events | Cart mutations still succeed; events are lost if Mbus is unavailable |
