---
service: "hybrid-boundary"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /metrics` (agent admin) | http | 30s (agent poll cycle) | Not specified |
| `GET /config` (agent admin) | http | On demand | Not specified |
| ELB target group health check | AWS ELB | Configured in Terraform | Not specified |
| Envoy admin health check (`POST /healthcheck/fail`) | http (to Envoy) | On drain event | Immediate |

The agent monitors ELB target health on every poll tick. When the instance transitions to `draining` state, the agent posts `http://localhost:{envoyadminport}/healthcheck/fail` to signal Envoy to stop accepting new connections before the instance is terminated.

## Monitoring

### Metrics

All metrics are emitted in Prometheus format from the agent admin endpoint at `/metrics`.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `edgeproxy_agent_config_reload_total` | counter | Total number of configuration reloads triggered by SIGUSR1 | Not specified |
| `edgeproxy_agent_update_count_total` | counter | Total number of Envoy configuration update cycles started | Not specified |
| `edgeproxy_agent_update_success_total` | counter | Total number of Envoy configuration update cycles completed successfully | Not specified |
| `edgeproxy_agent_update_error_total` | counter | Total number of Envoy configuration update cycles aborted due to error | Alert if non-zero sustained |
| `edgeproxy_agent_update_duration_seconds` | histogram | Histogram of Envoy configuration update loop duration | Not specified |
| `edgeproxy_agent_service_total` | gauge | Total number of registered services visible to this agent | Not specified |
| `edgeproxy_agent_akamai_ip_total` | gauge | Total number of IP addresses returned by the Akamai API | Not specified |
| `edgeproxy_agent_ipsetupdate_count_total` | counter | Total number of Akamai ipset update cycles started | Not specified |
| `edgeproxy_agent_ipsetupdate_success_total` | counter | Total number of Akamai ipset update cycles completed successfully | Not specified |
| `edgeproxy_agent_ipsetupdate_error_total` | counter | Total number of Akamai ipset update cycles aborted due to error | Alert if non-zero sustained |
| `edgeproxy_agent_ipsetupdate_duration_seconds` | histogram | Histogram of Akamai ipset update loop duration | Not specified |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Hybrid Boundary Overview | Wavefront | https://groupon.wavefront.com/dashboard/hybrid-boundary |
| Hybrid Boundary Per-Service | Wavefront | https://groupon.wavefront.com/dashboard/hybrid-boundary-per-service |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service down | Edge proxy fleet not responding | P1 | Page on-call via PagerDuty PAXBCM9; contact cloud-routing@groupon.com |
| Envoy config update errors | `edgeproxy_agent_update_error_total` increasing | P2 | Check agent logs, verify DynamoDB connectivity, check `-pollafter` configuration |
| Akamai ipset update errors | `edgeproxy_agent_ipsetupdate_error_total` increasing | P2 | Check S3 bucket access, verify Akamai API connectivity |

PagerDuty service: https://groupon.pagerduty.com/services/PAXBCM9
Slack channel ID: `C03UE911RSQ`
New tickets: https://jira.groupondev.com/browse/MESH

## Common Operations

### Restart Service

For the Agent (EC2 AMI-based):
1. Terminate the EC2 instance — Auto Scaling will replace it with a new instance using the latest AMI.
2. To trigger a configuration reload without restart, send `SIGUSR1` to the agent process: the agent will enqueue both an Envoy config update and an Akamai ipset update.

For Lambda functions:
1. Lambda functions are stateless — re-invocation is automatic. No manual restart required.
2. To force a Lambda cold start, update any environment variable via the AWS Console or Terraform.

### Scale Up / Down

1. Modify the Auto Scaling Group desired/min/max counts in `terraform/envs/<env>/` and apply:
   ```
   make -C terraform apply-env/<env>/<region>
   ```
2. The RRDNS Lambda automatically updates Route53 weighted records as instances join or leave the ASG.

### Database Operations

DynamoDB tables are managed via Terraform. No migration tooling exists in the application layer.

- To inspect service registrations: query `edge-proxy.<env>.services` directly via the AWS Console or AWS CLI.
- To inspect change history: query `edge-proxy.<env>.history` by `domainName`.
- Schema changes require Terraform apply. Consult the Cloud Routing team before modifying table structure.

## Troubleshooting

### Envoy not receiving updated configuration

- **Symptoms**: Envoy continues to route to stale endpoints after a service update.
- **Cause**: Agent poll cycle failed to update DynamoDB, or the agent xDS server is not reachable by Envoy.
- **Resolution**: Check `edgeproxy_agent_update_error_total` metric. Review agent logs (JSON structured via logrus). Verify DynamoDB connectivity. Send `SIGUSR1` to the agent to trigger an immediate reload.

### API returns 409 Conflict

- **Symptoms**: Mutating API call returns HTTP 409 with message "conflict with conveyor cluster promotion".
- **Cause**: Conveyor is in maintenance mode for the target environment.
- **Resolution**: Wait for Conveyor maintenance to complete. Admins can override by including `"ConveyorMaintenanceOverride": true` in the request body.

### Traffic shift stuck in InProgress

- **Symptoms**: Shift status is `InProgress` but traffic weights are not changing.
- **Cause**: Step Functions state machine execution stalled or failed.
- **Resolution**: Check AWS Step Functions console for execution status and error details. Use `DELETE /v1/services/{serviceName}/{domainName}/shift` to abort the shift. Alternatively, use `PUT /v1/services/{serviceName}/{domainName}/versions/{version}` to revert to a previous configuration.

### Service registration rejected: service does not exist in service portal

- **Symptoms**: `POST /v1/services` returns HTTP 400 "Service X does not exist in service portal".
- **Cause**: The service name is not registered in the Groupon service portal.
- **Resolution**: Register the service in the service portal first. As a temporary workaround, append `?skipServiceNameCheck=true` to the request URL (this bypass should not be used in production).

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — edge proxy fleet not routing traffic | Immediate | Cloud Routing team (cloud-routing@groupon.pagerduty.com) |
| P2 | Degraded — configuration updates failing, traffic shifts stuck | 30 min | Cloud Routing team (#cloud-support Gchat) |
| P3 | Minor impact — single endpoint misconfiguration, API errors | Next business day | MESH Jira ticket |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS DynamoDB | Agent logs errors and increments `edgeproxy_agent_update_error_total`; check AWS console | Agent continues serving last known xDS snapshot to Envoy |
| AWS Step Functions | Check execution history in AWS Console | Abort shift via API and revert to previous version |
| Akamai / S3 | Agent logs errors and increments `edgeproxy_agent_ipsetupdate_error_total` | Previous allow-list remains active on edge proxies |
| Conveyor | API returns HTTP 500 if unreachable; admin override available | Use `ConveyorMaintenanceOverride: true` (admin only) |
| ProdCat | API returns HTTP 500 if unreachable; admin override available | Use `ProdcatOverride: true` (admin only) |
