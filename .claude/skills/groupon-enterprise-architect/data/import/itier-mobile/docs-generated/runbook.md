---
service: "itier-mobile"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/_config` | HTTP GET | Per Kubernetes liveness/readiness probe | — |
| `/mobile` | HTTP GET (Pingdom synthetic) | External uptime monitoring per country | — |
| Status port: `8000` | TCP (`.service.yml` `status_endpoint.port`) | — | — |

> Verify health by visiting `/_config`, `/mobile`, and `/apple-app-site-association` post-deploy (per `package.json` napistrano logbook `verificationPlan`).

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `itier_mobile_twilio_sms_count` | Counter | Number of SMS messages sent from `/mobile` in the last 24 hours | SEV4 if > 2000 in 24 hours |
| `itier_mobile_twilio_sms_errors` | Counter | Number of SMS send errors from `/mobile` | SEV4 if > 10 in 3 hours |
| HTTP response time | Histogram | Avg: 120ms, P90: 180ms, P95: 210ms, P99: 270ms | — |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| itier-mobile main | Wavefront | https://groupon.wavefront.com/dashboard/itier-mobile |
| itier-mobile secondary | Wavefront | https://groupon.wavefront.com/u/s18GPklJ7w |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| `itier_mobile_twilio_sms_count` | > 2000 SMSs sent in last 24 hours | SEV4 | Identify frequent sender IPs via Splunk (`sourcetype=itier-mobile_json message="[TWILIO]"`); contact Global Security to block abusive IPs if confirmed non-promotional |
| `itier_mobile_twilio_sms_errors` | > 10 SMS errors in last 3 hours | SEV4 | Check Splunk (`sourcetype=itier-mobile_json message="[TWILIO-ERRORS]"`); determine if Twilio sender number is invalid; swap phone number in code and redeploy if needed |
| Mobile App Download-{country} (Pingdom) | `/mobile` endpoint down | SEV3 | Check Splunk errors; restart pods if needed; page `i-tier-mobile-redirect-page@groupon.pagerduty.com` |

Pingdom alerts exist for: AU, BR, DE, ES, FR, HK, IT, MY, NL, SE, SG, UK, US.

## Common Operations

### Restart Service

Roll back or redeploy via Deploybot:
1. Visit https://deploybot.groupondev.com/InteractionTier/itier-mobile
2. Click the deployment version to roll back
3. Click "ROLLBACK" button

Or via CLI:
```bash
npx nap --cloud rollback staging us-west-1
npx nap --cloud rollback production us-west-1
```

### Scale Up / Down

Scaling is managed by Conveyor Cloud (Kubernetes HPA). To increase capacity beyond the HPA maximum, contact the Conveyor Team to adjust `maxReplicas` in `.deploy-configs/*.yml` and redeploy.

During high-load situations, the `/mobile` routes can be offloaded to `citydeal_app` (legacyWeb) by requesting the GROUT team remove the `mobile_redirect` route group from the itier-mobile routing configuration.

### Database Operations

> Not applicable — this service is stateless and owns no database.

### Disk Space

If disk space alerts fire on a host:
1. Run `df -h` to confirm disk usage
2. Run `sudo du -max /var/groupon/ | sort -nr | head -10` to identify large files
3. Delete log files older than 7–10 days (log garbage collection is set to 15 days)

## Troubleshooting

### High SMS volume / suspected abuse

- **Symptoms**: `itier_mobile_twilio_sms_count` alert fires; unusually high SMS send rate
- **Cause**: Automated abuse from a small set of IPs exploiting the `/mobile/send_sms_message` endpoint
- **Resolution**: Run Splunk query `sourcetype=itier-mobile_json message="[WEB]" [ search sourcetype=itier-mobile_json message="[TWILIO]" | fields + meta.requestId ] | top meta.remoteAddress showperc=false`; identify high-frequency IPs; request Global Security to block

### SMS errors (Twilio sender number issue)

- **Symptoms**: `itier_mobile_twilio_sms_errors` alert fires; SMS delivery failures
- **Cause**: Twilio sender phone number no longer assigned to Groupon account, or user opt-out
- **Resolution**: Run `sourcetype=itier-mobile_json message="[TWILIO-ERRORS]"` in Splunk; if a sender number is invalidated, swap it for another in the code and redeploy

### `/mobile` page down

- **Symptoms**: Pingdom SEV3 alert for a country; `curl https://www.groupon.com/mobile` returns non-200
- **Cause**: Pod crash, configuration error, or upstream layout-service degradation
- **Resolution**: Check ELK logs; check Wavefront graphs for error rate spike; restart pods via Deploybot or `npx nap --cloud rollback`

### Deploy verification failure

- **Symptoms**: Post-deploy check shows missing assets or JS errors
- **Cause**: webpack build artifact mismatch or CDN upload failure
- **Resolution**: Verify `/_config`, `/mobile`, and `/apple-app-site-association` endpoints; check Splunk for `[PANIC]` messages (`index=main sourcetype="itier-mobile_json" message="[PANIC]"`); roll back if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service fully down across all regions | Immediate | InteractionTier on-call via PagerDuty (PY7QIOI) |
| P2 | Degraded (e.g., SMS errors, partial region outage) | 30 min | InteractionTier on-call |
| P3 | Minor impact (e.g., single-country Pingdom alert) | Next business day | i-tier-devs@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Twilio | Twilio status page: http://status.twilio.com/ | SMS endpoint returns error; no automatic fallback |
| layout-service | Wavefront / ELK monitoring of layout request failures | Page may render without layout shell |
| Hybrid Boundary | Hybrid Boundary UI dashboards (staging / production) | Traffic cannot reach service if HB is down |
