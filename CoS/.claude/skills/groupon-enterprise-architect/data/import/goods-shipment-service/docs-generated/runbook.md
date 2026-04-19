---
service: "goods-shipment-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `http://{host}:8080/grpn/status` | HTTP | Platform-managed | Platform-managed |
| Admin port `8081` | HTTP (Dropwizard admin) | — | — |

The status endpoint is defined in `.service.yml` as `path: /grpn/status` on port `8080`. The `sha_key` is `commitId`. The status endpoint is currently marked `disabled: true` in the service registry configuration, meaning the environment poller does not poll it automatically.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Carrier API call count | counter | Tagged per carrier (`Grapher=apiCountPerCarrier`); logged on every carrier poll | No evidence found in codebase for specific threshold |
| Mbus write errors | counter | Logged as ERROR when `ShipmentNotificationSenderService` or `OrderFulfillmentNotificationSenderService` throws `MessageException` | No evidence found in codebase for specific threshold |
| CI tracking update failures | counter | Logged as ERROR when Commerce Interface HTTP call fails | No evidence found in codebase for specific threshold |

> Operational metric thresholds to be defined by service owner.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Service dashboard | Not discoverable | See `.service.yml` sre.dashboards for configured links |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| PagerDuty service | goods-shipment-service@groupon.pagerduty.com | P1/P2 | See https://groupon.pagerduty.com/services/goods-shipment-service |

> Specific alert conditions are not discoverable from the codebase. Operational alert configuration to be defined by service owner.

## Common Operations

### Restart Service

Operational procedures to be defined by service owner. For Kubernetes deployments, a rolling restart can be triggered via `kubectl rollout restart deployment/<deployment-name> -n goods-shipment-service-<env>-sox` using the appropriate Kube context.

### Scale Up / Down

Update `minReplicas` / `maxReplicas` in the relevant environment Helm values file (`.meta/deployment/cloud/components/app/<env>.yml`) and redeploy via DeployBot. HPA manages auto-scaling within the configured bounds; VPA manages resource requests.

### Manually Trigger Jobs (Admin Endpoints)

- Refresh carrier status for all shipments: `PUT /admin/shipments/refreshCarrier`
- Refresh specific shipments: `PUT /admin/shipments/refreshShipments?shipmentUuids=<uuid1>&shipmentUuids=<uuid2>`
- Send email notifications: `POST /admin/shipments/sendNotifications?shipmentUuids=<uuid>`
- Send mobile notifications: `POST /admin/shipments/sendMobileNotifications?shipmentUuids=<uuid>`
- Send order fulfilment notification: `POST /admin/shipments/sendOrderFulfillment?orderUuids=<uuid>`

All admin endpoints require a valid `clientId` query parameter.

### Database Operations

Schema migrations are managed by Flyway via `jtier-migrations`. The `flywayMigrationsEnabled` config flag controls whether migrations run on startup. Quartz scheduler tables are managed by `jtier-quartz-mysql-migrations`. Contact the service team before running manual migrations against production.

## Troubleshooting

### Shipments Not Updating

- **Symptoms**: Shipment status is stuck; no carrier status updates appearing in the database
- **Cause**: Carrier refresh job is disabled (`featureFlags.shipmentRefreshJob=false`), carrier API credentials are expired, or carrier API is unavailable
- **Resolution**: Verify `featureFlags.shipmentRefreshJob` is enabled. Check carrier OAuth2 token validity (Auth Token Refresh Job). Manually trigger via `PUT /admin/shipments/refreshCarrier?carrier=<carrier>`. Review logs for `Carrier not supported` or timeout errors.

### Aftership Webhook Returning 401

- **Symptoms**: Aftership webhook deliveries fail with HTTP 401
- **Cause**: `aftership.webhookSecret` or `aftership.webhookAuthToken` mismatch between configured values and what Aftership is sending
- **Resolution**: Verify HMAC-SHA256 secret and `auth_token` in the secrets config match the values registered in the Aftership dashboard.

### Mobile Notifications Not Delivered

- **Symptoms**: Consumers not receiving push notifications for SHIPPED/OUT_FOR_DELIVERY/DELIVERED status
- **Cause**: `featureFlags.shipmentUpdateMobileNotificationJob` disabled; Token Service unavailable; Event Delivery Service unreachable; or `eventDeliveryService.clientId` incorrect
- **Resolution**: Check feature flag. Test Token Service health. Verify Event Delivery Service endpoint and `clientId`. Review service logs for `Mobile notification call failed` errors.

### Mbus Publish Errors

- **Symptoms**: `ShipmentNotificationSendingException` in logs; downstream consumers not receiving shipment events
- **Cause**: Mbus configuration incorrect or Mbus broker unavailable
- **Resolution**: Verify `mbusShipmentNotification` config block destinations (`goodsShipmentNotification`, `orderFulfillmentNotification`) are correctly configured. Check Mbus broker health.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no shipment tracking updates processing | Immediate | goods-shipment-service@groupon.pagerduty.com; goods-eng-seattle Slack |
| P2 | Degraded — specific carrier or notification channel failing | 30 min | goods-eng-seattle@groupon.com |
| P3 | Minor impact — individual shipment errors; admin endpoint failures | Next business day | goods-eng-seattle@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumGoodsShipmentDatabase` | JDBI connection pool health via Dropwizard healthcheck | No fallback — service cannot operate without MySQL |
| `aftershipApi` | Aftership API ping / webhook delivery failure rate | Aftership Create Shipment Job retries up to `retryForHours` (default 480h) |
| Carrier APIs (UPS, FedEx, DHL, etc.) | Carrier refresh job error logs | Refresh job skips failed carriers and continues to next; job re-runs on Quartz schedule |
| `rocketmanService` | HTTP response code in `RocketmanClient` | No fallback; error logged and email notification skipped |
| `eventDeliveryService` | HTTP response code in `EventDeliveryServiceClient` | No fallback; error logged and mobile notification skipped |
| `tokenService` | HTTP response in `TokenServiceClient` | No fallback; mobile notification cannot be sent without a push token |
