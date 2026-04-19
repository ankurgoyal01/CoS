---
service: "custom-fields-service"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /grpn/healthcheck` (port 8080) | HTTP — Kubernetes readiness probe | 5s | — |
| `GET /grpn/healthcheck` (port 8080) | HTTP — Kubernetes liveness probe | 15s | — |
| `/grpn/status` (port 8080) | HTTP — service status endpoint (disabled per `.service.yml`) | — | — |

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| HTTP request rate (all endpoints) | counter | Requests per minute served by the service | Expected max: 62,000 rpm (NA), 21,000 rpm (EMEA) |
| HTTP error rate — validate 400s | counter | Rate of 400 responses from validate endpoints | Alert: SEV4 when rate is higher than normal |
| HTTP error rate — create failures | counter | Rate of failures on `POST /v1/fields` | Alert: SEV4 when elevated |
| User Service connection errors | counter | Failed outbound connections to Users Service | Alert: SEV4 when elevated |
| User Service response time | histogram | Latency of `GET users/v1/accounts` calls | Alert: SEV4 when too high |
| DB query latency | histogram | PostgreSQL query response time | Alert: SEV4 when slow |
| DB availability | gauge | DaaS PostgreSQL up/down | Alert: SEV3 when down |
| Service availability | gauge | CFS itself up/down | Alert: SEV3 when down |
| TP99 latency | histogram | 99th percentile end-to-end response time | Target: 150ms |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Custom Fields Service Endpoints (cloud) | Wavefront | https://groupon.wavefront.com/dashboard/custom-fields-service-cloud |
| Custom Fields Service (on-prem legacy) | Wavefront | https://groupon.wavefront.com/dashboard/custom-fields |
| Custom Fields Service Hosts | Wavefront | https://groupon.wavefront.com/dashboard/custom-fields-hosts |
| System Metrics (Conveyor Cloud) | Wavefront | https://groupon.wavefront.com/dashboard/Conveyor-Cloud-Customer-Metrics |
| EU-WEST-1 Logs | Kibana (logging-eu) | https://logging-eu.groupondev.com/goto/49971a80-6ecb-11ee-8f0a-ed1e30fa1b36 |
| US-WEST-1 Logs | Kibana (logging-us) | https://logging-us.groupondev.com/goto/34e121d0-6ecb-11ee-82f7-1f54a11f5b75 |
| Hybrid-boundary Metrics | Kibana | https://logging-dub1.groupondev.com/goto/fb9182fa8430ea907e6a50f177ddafc7 |
| Splunk (logs by sourcetype) | Splunk | `sourcetype=custom_fields` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| User Service down | Elevated connection errors to Users Service | SEV4 | Check Users Service status; fields will continue working without prefill. Escalate to Engage Dev and UserService team. |
| User Service response time too slow | Response latency from Users Service exceeds threshold | SEV4 | Check Wavefront; consider disabling prefill by updating `userService.host` to dead-end. Escalate if needed. |
| DB down | DaaS PostgreSQL unavailable | SEV3 | Field retrieval will fail entirely. Engage Dev team + GDS/DaaS team. |
| DB slow | DaaS PostgreSQL responding slowly | SEV4 | Partially mitigated by cache. Check Wavefront DB dashboard; engage GDS/DaaS team. |
| High rate of invalid validate calls | Rate of 400s on validate endpoints is above baseline | SEV4 | Check Splunk for error patterns; identify upstream caller with broken contract; engage calling team. |
| High rate of create failures | Rate of failures on `POST /v1/fields` is above baseline | SEV4 | Check Splunk; identify caller; engage Engage Dev team. |
| Service down | CFS not responding at all | SEV3 | Check Splunk and Kubernetes pod status; attempt restart. Escalate to Engage Dev team. |

PagerDuty: https://groupon.pagerduty.com/services/PBR91RA (cloud) / https://groupon.pagerduty.com/services/P97C4VA (legacy)

## Common Operations

### Restart Service

Via Kubernetes (cloud):

```bash
# Authenticate
kubectl cloud-elevator auth
# Set context
kubectl config use-context custom-fields-service-production-us-west-1
# Rolling restart
kubectl rollout restart deployment/custom-fields-service
```

Via legacy runit (on-prem):

```bash
sudo sv stop jtier
sudo sv start jtier
```

### Scale Up / Down

1. Open `.meta/deployment/cloud/components/app/{env}.yml` for the target environment
2. Update `minReplicas` and/or `maxReplicas` values
3. Re-deploy via DeployBot by promoting the current version with the updated config

### Disable User Service Prefilling (emergency)

When the Users Service is causing high latency or errors, disable prefill without a code deploy:

1. Update the run-config for the affected environment:
   ```yaml
   userServiceClient:
     url: "http://localhost:9999/"
   ```
2. Roll out the config change via DeployBot
3. CFS will fail-fast on connect and skip prefill, returning unprefilled fields to callers
4. Revert once Users Service recovers

### Database Operations

- Schema migrations run automatically at application startup via `jtier-migrations`
- Database schema rollbacks are **not supported** — all changes must be backward compatible
- To check DB metrics: Wavefront (GDS metrics) or CheckMK

## Troubleshooting

### High Latency

- **Symptoms**: TP99 latency exceeding 150ms threshold; upstream callers timing out
- **Cause**: Either Users Service slowness (prefill path) or PostgreSQL DaaS slowness
- **Resolution**: Check Wavefront per-host dashboard to isolate DB vs User Service. If User Service: consider disabling prefill (see above). If DB: engage GDS/DaaS team.

### Service Not Responding

- **Symptoms**: All requests returning errors or timing out; PagerDuty alert fires
- **Cause**: Pod crash, JVM OOM, or dependency cascade
- **Resolution**: Check `kubectl get pods` and `kubectl logs <pod-name> app`. Attempt rolling restart. Check Splunk for exception stack traces (`sourcetype=custom_fields`).

### High Rate of Validation Failures (400s)

- **Symptoms**: SEV4 alert fires; callers report validation rejecting previously valid fields
- **Cause**: Upstream service changed its field submission format; field template updated incompatibly
- **Resolution**: Check Splunk for the `CHECKOUT_FIELD_*` error codes being returned; identify which `fieldsId` is failing; trace back to the calling service; engage that team.

### Template Creation Failures (POST /v1/fields returning 400)

- **Symptoms**: Callers cannot create new field templates; receiving 400 with `InvalidTemplateResponse`
- **Cause**: Submitted template JSON does not pass `CustomFieldsTemplateValidator` rules
- **Resolution**: Check the `invalidFields` array in the 400 response body for specific `refersTo` + `message` details. Validate template JSON against `doc/swagger/swagger.yaml` schema.

### Database Down

- **Symptoms**: All read and write endpoints failing; SEV3 alert fires
- **Cause**: DaaS PostgreSQL node failure or network partition
- **Resolution**: Verify DB status via Wavefront GDS dashboard. Engage GDS/DaaS team. Service cannot operate without DB — no fallback.

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| SEV3 | Service down or DB down — no field retrieval possible | Immediate | 3PIP Booking team, then Engage Dev team |
| SEV4 | Degraded — prefill not working, validate error rate elevated, or DB slow | 30 min | 3PIP Booking team; escalate to dependent service teams as needed |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| Users Service | Wavefront: User Service latency / error dashboards; Splunk `sourcetype=custom_fields` for connection errors | Disable prefill by setting `userServiceClient.url` to dead-end; fields returned without prepopulated values |
| PostgreSQL DaaS | Wavefront GDS metrics dashboard; CheckMK DB metrics | None — service cannot serve templates without DB access |
