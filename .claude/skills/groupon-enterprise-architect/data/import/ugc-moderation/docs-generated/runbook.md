---
service: "ugc-moderation"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/versions` | http | Per Kubernetes liveness/readiness probe schedule | Default Kubernetes |

To verify the service is up and check the running artifact version:

```
https://ugc-moderation.production.service.us-central1.gcp.groupondev.com/grpn/versions
```

A successful response returns a JSON object with `OK` status and the deployed `sha`.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| Pod availability | gauge | Number of running pods vs. desired replicas | Pods < minReplicas |
| HTTP error rate (5xx) | counter | Rate of 5xx responses per endpoint | Custom threshold (Wavefront alert) |
| HTTP request latency | histogram | Response time per route | Custom threshold (Wavefront alert) |

All alerts are tagged with `ugc-moderation.itier.production` in Wavefront.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| UGC Moderation (primary) | Wavefront | https://groupon.wavefront.com/dashboards/ugc-moderation |
| UGC Moderation (secondary) | Wavefront | https://groupon.wavefront.com/dashboard/ugc-moderation |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Pod count below minimum | Running pods < minReplicas | critical | Check Kubernetes pod logs; restart deployment |
| High 5xx error rate | Error rate above threshold on any endpoint | warning | Check ELK logs for upstream errors (ugc-service, merchant-data) |
| Service unreachable | `/grpn/versions` returns non-200 | critical | Restart deployment; check Hybrid Boundary logs |

Alerts are available via Wavefront at the tagged query: `ugc-moderation.itier.production`.

## Common Operations

### Restart Service

```bash
kubectl rollout restart deployment/<deployment_name> -n ugc-moderation-production
```

Or via Napistrano:

```bash
npx nap --cloud deploy --artifact <current-artifact> production us-west-1
```

A re-deploy of the current artifact effectively restarts pods.

### Scale Up / Down

Scaling is controlled via `.deploy-configs/<env>-<region>.yml` by adjusting `minReplicas` and `maxReplicas`, then redeploying. Maximum replicas by region are also configurable in `package.json` under `napistrano.environment.production`.

### Rollback a Deploy

**Via Deploybot (preferred):**
1. Visit https://deploybot.groupondev.com/UserGeneratedContent/ugc-moderation
2. Click the deployment to roll back (in the **Version** column)
3. Click **ROLLBACK**

**Via Napistrano CLI:**
```bash
npx nap --cloud rollback production us-west-1
```

Rollback deploys the most recently successfully deployed artifact prior to the current one.

### Database Operations

> Not applicable. UGC Moderation does not own a database. All data mutations are proxied to `continuumUgcService`.

## Troubleshooting

### User not having access to the application

- **Symptoms**: User receives 401 Unauthorized when accessing any restricted route
- **Cause**: The user's Okta username is not in the `ugcModeration.admins.oktaUsernames` or `ugcModeration.imageAdmins.oktaUsernames` list in `config/stage/production.cson`
- **Resolution**: Add the Okta username to the appropriate allowlist in `config/stage/production.cson` and redeploy through Deploybot

### UGC Lookup returns no results for a merchant UUID

- **Symptoms**: Merchant lookup page shows empty results despite a valid UUID
- **Cause**: `m3_merchant_service` may return an error or empty response for the given merchant ID
- **Resolution**: Check the `m3_merchant_service` response via Kibana using the request ID. Confirm the merchant UUID is valid and active.

### Service appears down or unresponsive

- **Symptoms**: `/grpn/versions` returns non-200 or times out
- **Resolution**:
  1. Check Wavefront graphs for error rate spikes
  2. Check ELK logs (index: `ugc-moderation_itier`) for stack traces
  3. Check Hybrid Boundary logs for routing issues
  4. Restart pods via `kubectl rollout restart`
  5. Escalate to `#hybrid-boundary` Slack channel if HB logs show issues

### Determining the running version

```
GET https://ugc-moderation.production.service.us-central1.gcp.groupondev.com/grpn/versions
```

The response JSON includes the deployed artifact SHA.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; moderation team cannot access tool | Immediate | ugc-dev@groupon.com; PagerDuty P057HSW |
| P2 | Degraded (some routes failing; users getting errors) | 30 min | ugc-dev@groupon.com; Slack #ugc-notifications |
| P3 | Minor (UI display issue; specific lookup failing for subset of data) | Next business day | Jira UGC project |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumUgcService` | Check Kibana for upstream API errors; confirm service health via its own `/grpn/versions` | No fallback — all moderation actions require the UGC API |
| `m3_merchant_service` | Check Kibana for `m3_merchant_service` error responses | Lookup and transfer flows fail gracefully with error message |
| Memcached | Check Wavefront for cache timeout spikes | Cache misses fall through to upstream API; service remains functional |

## Log Access

- **ELK Production US**: https://prod-kibana-unified.us-central1.logging.prod.gcp.groupondev.com (filter by `ugc-moderation_itier`)
- **ELK Production EU**: https://logging-eu.groupondev.com/app/kibana (index: `eu-*:filebeat-ugc-moderation_itier--*`)
- **CLI**: `npx nap --cloud logs --follow production us-west-1`

## Contacts

| Channel | Details |
|---------|---------|
| Email | ugc-dev@groupon.com |
| Slack | #ugc-notifications (channel ID: CF8G5UJLD) |
| PagerDuty | https://groupon.pagerduty.com/services/P057HSW |
| Jira | https://jira.groupondev.com/browse/UGC |
| Deploybot | https://deploybot.groupondev.com/UserGeneratedContent/ugc-moderation |
