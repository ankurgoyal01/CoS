---
service: "netops_awsinfra"
title: "CloudWatch Dashboard Deployment"
generated: "2026-03-03"
type: flow
flow_name: "cloudwatch-dashboard-deployment"
flow_type: batch
trigger: "Manual engineer action — apply transit_gateway or direct_connect dashboard module"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumTransitGatewayDashboardModule"
  - "continuumDirectConnectDashboardModule"
  - "cloudPlatform"
  - "observabilityPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# CloudWatch Dashboard Deployment

## Summary

This flow provisions AWS CloudWatch dashboards for Transit Gateway and Direct Connect monitoring in the `grpn-netops` account. The dashboards are defined as Terraform-managed `aws_cloudwatch_dashboard` resources, with widget configurations derived from TGW IDs and DX connection IDs discovered at apply time. Once deployed, the dashboards provide real-time visibility into TGW throughput (bytes in/out per attachment and aggregate) and Direct Connect link health for the Network Operations team.

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer deploying or updating dashboards after adding new TGW attachments or DX connections; or as part of initial NetOps account setup
- **Frequency**: On demand — deployed once; updated when new TGW or DX resources are added

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Initiates dashboard module apply | — |
| NetOps Terragrunt Orchestrator | Executes Terraform in `grpn-netops` account global scope | `continuumNetopsTerragruntOrchestrator` |
| Transit Gateway Dashboard Module | Builds TGW CloudWatch dashboard JSON with per-TGW metric widgets | `continuumTransitGatewayDashboardModule` |
| Direct Connect Dashboard Module | Builds DX CloudWatch dashboard JSON with per-connection metric widgets | `continuumDirectConnectDashboardModule` |
| AWS CloudWatch API | Accepts and stores dashboard JSON body | `cloudPlatform` |
| CloudWatch Dashboards (observabilityPlatform) | Renders dashboard UI for Network Operations engineers | `observabilityPlatform` |

## Steps

1. **Apply Transit Gateway Dashboard module**: Run `make grpn-netops/global/dashboards/transit_gateway/APPLY`; Terraform references TGW IDs from `tgw_ids.tf` data sources; builds `dashboard_body` JSON with six widget types: `tgw_all_in_widget`, `tgw_all_out_widget`, `tgw_all_both_widget`, `tgw_all_vpc_in_widget`, `tgw_all_vpc_out_widget`, `tgw_all_vpc_both_widget`
   - From: `continuumTransitGatewayDashboardModuleProvisioner`
   - To: `cloudPlatform` (AWS CloudWatch API)
   - Protocol: AWS API

2. **Publish TGW dashboard**: Terraform applies `aws_cloudwatch_dashboard` with `dashboard_name = "TransitGateway"`; dashboard body is JSON-encoded and submitted to CloudWatch
   - From: `continuumTransitGatewayDashboardModuleProvisioner`
   - To: `cloudPlatform` (AWS CloudWatch API)
   - Protocol: AWS API

3. **Apply Direct Connect Dashboard module**: Run `make grpn-netops/global/dashboards/direct_connect/APPLY`; Terraform resolves DX connection IDs from `dxcon_ids.tf`; builds `dashboard_body` JSON with DX-specific metric widgets from `widgets.tf` using metrics defined in `metrics.tf`
   - From: `continuumDirectConnectDashboardModuleProvisioner`
   - To: `cloudPlatform` (AWS CloudWatch API)
   - Protocol: AWS API

4. **Publish DX dashboard**: Terraform applies `aws_cloudwatch_dashboard` for Direct Connect observability; DX metrics are aggregated per connection
   - From: `continuumDirectConnectDashboardModuleProvisioner`
   - To: `cloudPlatform` (AWS CloudWatch API)
   - Protocol: AWS API

5. **Dashboard available to engineers**: Network Operations engineers access dashboards via AWS Console CloudWatch in the `grpn-netops` account (`455278749095`) for ongoing monitoring of TGW and DX health
   - From: `observabilityPlatform`
   - To: Network Operations Engineer
   - Protocol: HTTPS (AWS Console)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| TGW ID not found by data source | `tgw_ids.tf` data source query returns empty | Verify TGW exists and is tagged correctly; ensure `tgw` module applied before dashboard module |
| DX connection ID not found | `dxcon_ids.tf` data source fails | Verify DX connections exist in the region; check `dxcon` module state |
| Dashboard body exceeds AWS size limit | CloudWatch `aws_cloudwatch_dashboard` rejects payload | Reduce number of widgets or split into multiple dashboards |
| Apply fails with access denied | IAM role lacks `cloudwatch:PutDashboard` permission | Verify `grpn-all-netops-admin` role has CloudWatch permissions in `grpn-netops` account |

## Sequence Diagram

```
Engineer -> NetOpsAccount: make grpn-netops/global/dashboards/transit_gateway/APPLY
NetOpsAccount -> AWSEC2: describe TGW IDs (from tgw_ids.tf)
AWSEC2 --> NetOpsAccount: tgw-id list
NetOpsAccount -> NetOpsAccount: build dashboard JSON (6 TGW widgets)
NetOpsAccount -> AWSCloudWatch: put_dashboard (name=TransitGateway)
AWSCloudWatch --> NetOpsAccount: dashboard created
Engineer -> NetOpsAccount: make grpn-netops/global/dashboards/direct_connect/APPLY
NetOpsAccount -> AWSDX: describe DX connection IDs (from dxcon_ids.tf)
AWSDX --> NetOpsAccount: connection-id list
NetOpsAccount -> NetOpsAccount: build dashboard JSON (DX metrics widgets)
NetOpsAccount -> AWSCloudWatch: put_dashboard (name=DirectConnect)
AWSCloudWatch --> NetOpsAccount: dashboard created
Engineer -> AWSConsole: view dashboards (TransitGateway, DirectConnect)
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Transit Gateway Provisioning](transit-gateway-provisioning.md), [Direct Connect Provisioning](direct-connect-provisioning.md)
- Monitoring: See [Runbook](../runbook.md) for alert thresholds and dashboard links
