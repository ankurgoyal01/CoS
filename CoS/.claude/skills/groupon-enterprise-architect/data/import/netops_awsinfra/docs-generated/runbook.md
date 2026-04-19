---
service: "netops_awsinfra"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `make <path>/plan` (drift detection) | exec | On demand | Terraform provider timeout |
| AWS CloudWatch Dashboard `TransitGateway` | dashboard | Real-time | — |
| AWS CloudWatch Dashboard `DirectConnect` | dashboard | Real-time | — |
| PagerDuty — `netops-alerts@groupon.pagerduty.com` | alert | Continuous | — |
| Wavefront Firewall Sessions Dashboard | dashboard | 2-hour window | — |

> No HTTP health endpoint — this is an infrastructure provisioning tool, not a running service.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| TGW bytes in/out per attachment | gauge | Transit Gateway traffic volume per VPC attachment | AWS CloudWatch |
| TGW VPC in/out bytes (all regions) | gauge | Aggregate TGW throughput across all regions | AWS CloudWatch |
| DX connection state | gauge | Direct Connect link availability (available/down) | Alert on `down` or `pending` state |
| DX bytes in/out | gauge | Direct Connect link throughput | AWS CloudWatch |
| Netops firewall sessions | gauge | Firewall session count | See Wavefront dashboard |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Transit Gateway | AWS CloudWatch | Provisioned by `continuumTransitGatewayDashboardModule` as `TransitGateway` dashboard |
| Direct Connect | AWS CloudWatch | Provisioned by `continuumDirectConnectDashboardModule` as `DirectConnect` dashboard |
| Netops Firewall Sessions | Wavefront | https://groupon.wavefront.com/dashboard/netops_firewall_sessions |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Direct Connect link down | DX connection state != `available` | critical | Check `dxconn_down.png` runbook; verify physical connectivity at Equinix ECX |
| Direct Connect pending | DX connection state == `pending` | warning | Check `dxconn_pending.png` runbook; contact Equinix if LOA provisioning stalled |
| TGW attachment failure | VPC attachment in `failed` state | critical | Verify RAM share acceptance in workload account; check `tgw_accept` apply status |
| PagerDuty service | `netops-alerts@groupon.pagerduty.com` / `P2I9Z22` | variable | Escalate to Network Operations team via `#CF8A85A8J` Slack channel |

## Common Operations

### Add a New AWS Account to the TGW

1. Add account entry to `envs/customers.yml` with `owner_id` and `dc_vlan` settings
2. Create `envs/<account>/account.hcl` with `aws_account_id`, `env_short_name`, `env_stage`, and route table routes
3. Create `envs/<account>/<region>/region.hcl`
4. Run `make grpn-netops/<region>/<account>/prod/tgw_share/plan` — review RAM principal association
5. Run `make grpn-netops/<region>/<account>/prod/tgw_share/APPLY` — writes `tgw_data.yml` to account directory
6. Create `envs/<account>/<region>/prod/tgw_accept/terragrunt.hcl` pointing to `tgw_accept` module
7. Run `make <account>/<region>/prod/tgw_accept/plan` then `APPLY` — accepts RAM share and creates VPC attachment
8. If tagging is needed: run `tgw_vpc_attachments_tag` module in NetOps account

### Run a Terraform Plan

```bash
cd envs
make grpn-netops/us-west-2/tgw/prod/plan
```

### Run a Terraform Apply

```bash
cd envs
make grpn-netops/us-west-2/tgw/prod/APPLY
```

### Set Up Local Environment

```bash
cd envs
make aws-config     # generates ~/.aws/netops-netops-awsinfra.config with per-account profiles
make install        # installs Terraform base dependencies
```

### Scale Up / Down

> Not applicable — network infrastructure resources do not support horizontal scaling in the traditional sense. AWS Transit Gateway capacity is managed by AWS automatically.

### Database Operations

> Not applicable — no databases are managed by this service.

## Troubleshooting

### Direct Connect Link Down

- **Symptoms**: CloudWatch DX metric shows link state as `down`; cross-account network traffic failing; BGP sessions dropped
- **Cause**: Physical fiber cut, Equinix facility issue, or BGP misconfiguration on on-premise router
- **Resolution**: Check DX console for connection status; contact Equinix ECX (`EQC50`) for physical issues; verify BGP ASN `12269` peering on datacenter side; refer to `docs/GrouponAWSConnectivity2020.pdf` and `docs/dxconn_down.png`

### TGW Attachment in Failed State

- **Symptoms**: Workload account VPC cannot route to other accounts or on-premise; `aws_ec2_transit_gateway_vpc_attachment` shows `failed`
- **Cause**: RAM share not accepted; subnet IDs no longer exist; cross-account IAM permission issue
- **Resolution**: Verify RAM share is accepted in workload account (`aws_ram_resource_share_accepter`); re-run `tgw_accept` apply; check `tgw_data.yml` contains valid `tgw_ram_arn`

### Cross-Region Routing Not Working

- **Symptoms**: Traffic between regions not traversing TGW; route table missing TGW prefix list
- **Cause**: Cross-region peering not established; managed prefix list not populated; routes not added
- **Resolution**: Verify `tgw_crossregion_peering_create` and `_accept` are applied in both regions; check `tgw_crossregion_routes` managed prefix list entries match `global_prefixes` in `global.hcl`

### Terraform Apply Fails with Access Denied

- **Symptoms**: `AccessDeniedException` during apply
- **Cause**: aws-okta session expired or wrong AWS profile selected
- **Resolution**: Re-authenticate with `aws-okta login`; verify `AWS_PROFILE` matches the target account; confirm `grpn-all-netops-admin` role exists in target account

### Terraform State Lock Conflict

- **Symptoms**: `Error acquiring the state lock` message during plan/apply
- **Cause**: Another apply is running; previous apply crashed without releasing lock
- **Resolution**: Wait for concurrent operation to finish; if stale, use `terraform force-unlock <lock-id>` after confirming no active apply

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | All cross-account connectivity down (TGW or DX failure) | Immediate | Network Operations team via PagerDuty `P2I9Z22` |
| P2 | Single region TGW degraded; DX link flapping | 30 min | Network Operations team via PagerDuty `P2I9Z22` |
| P3 | Single account routing issue; non-production degradation | Next business day | `#CF8A85A8J` Slack channel / `prod-netops@groupon.com` |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| AWS Direct Connect | CloudWatch DX metrics + `dxconn_avail.png` runbook | Redundant DX links at Equinix ECX (two connections: `CFR_ECX_10G_CFR01`, `CFR_ECX_10G_CFR02`) |
| AWS Transit Gateway | CloudWatch TGW metrics; `terraform plan` drift check | No automated failover; TGW is a regional hub |
| AWS RAM | Check RAM share status in console | Re-run `tgw_share` apply to recreate share |
| Terraform Remote State (S3) | AWS S3 availability | CloudCore team escalation |
