---
service: "netops_awsinfra"
title: "Cross-Region TGW Peering"
generated: "2026-03-03"
type: flow
flow_name: "cross-region-tgw-peering"
flow_type: batch
trigger: "Manual engineer action — create and accept cross-region peering attachments and configure routes"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumTransitGatewayCrossRegionPeeringCreateModule"
  - "continuumTransitGatewayCrossRegionPeeringAcceptModule"
  - "continuumTransitGatewayCrossRegionRoutesModule"
  - "cloudPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# Cross-Region TGW Peering

## Summary

This flow connects Transit Gateways in different AWS regions so that traffic can flow between Groupon's regional AWS footprints without traversing the public internet. A peering attachment is created from one region's TGW to another's, accepted on the remote side, and then managed prefix lists and TGW routes are configured so that regional CIDR ranges are reachable across the peering. The `grpn-netops-TGW` gateway spans `us-west-1`, `us-west-2`, `eu-west-1`, `eu-west-2`, `us-east-1`, `us-east-2`, and `ap-southeast-1`.

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer adding a new region to the TGW mesh, or modifying cross-region routing policies
- **Frequency**: On demand — once per new region pair or when routing configuration changes

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Initiates create and accept apply operations in both regions | — |
| NetOps Terragrunt Orchestrator | Executes Terraform against NetOps account in both source and target regions | `continuumNetopsTerragruntOrchestrator` |
| TGW Cross-Region Peering Create Module | Creates `aws_ec2_transit_gateway_peering_attachment` in the source region | `continuumTransitGatewayCrossRegionPeeringCreateModule` |
| TGW Cross-Region Peering Accept Module | Accepts `aws_ec2_transit_gateway_peering_attachment_accepter` in the target region | `continuumTransitGatewayCrossRegionPeeringAcceptModule` |
| TGW Cross-Region Routes Module | Applies managed prefix lists and TGW prefix list references to route traffic across the peering | `continuumTransitGatewayCrossRegionRoutesModule` |
| AWS EC2 API (both regions) | Creates and accepts peering attachments; manages prefix lists and routes | `cloudPlatform` |

## Steps

1. **Create peering attachment in source region**: Run `make grpn-netops/<source-region>/tgw_crossregion_peering_create/<env>/APPLY`; Terraform applies `aws_ec2_transit_gateway_peering_attachment` specifying the source TGW ID and the peer TGW ID + region (e.g., `us-west-2` TGW peering to `eu-west-1` TGW)
   - From: `continuumTransitGatewayCrossRegionPeeringCreateModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API, source region)
   - Protocol: AWS API

2. **Accept peering attachment in target region**: Run `make grpn-netops/<target-region>/tgw_crossregion_peering_accept/<env>/APPLY`; Terraform applies `aws_ec2_transit_gateway_peering_attachment_accepter` referencing the peering attachment ID from step 1
   - From: `continuumTransitGatewayCrossRegionPeeringAcceptModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API, target region)
   - Protocol: AWS API

3. **Configure cross-region routes in source region**: Run `make grpn-netops/<source-region>/tgw_crossregion_routes/<env>/APPLY`; Terraform applies `aws_ec2_managed_prefix_list` with the target region's CIDR ranges (from `global_prefixes` in `global.hcl`), and `aws_ec2_transit_gateway_prefix_list_reference` to route that prefix list via the peering attachment
   - From: `continuumTransitGatewayCrossRegionRoutesModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API, source region)
   - Protocol: AWS API

4. **Configure cross-region routes in target region**: Mirror of step 3 — apply `tgw_crossregion_routes` in target region with source region CIDRs
   - From: `continuumTransitGatewayCrossRegionRoutesModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API, target region)
   - Protocol: AWS API

5. **Verify route propagation**: Engineer validates that route tables in both regions include the cross-region prefix list routes; tests connectivity between workload VPCs in different regions

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Peering attachment in `pending acceptance` | Accept module not yet applied in target region | Run `tgw_crossregion_peering_accept` apply in target region |
| Incorrect peer TGW ID | Peering create fails with `InvalidTransitGatewayID` | Verify TGW ID from `tgw` module Terraform state output |
| CIDR overlap in prefix lists | AWS rejects duplicate CIDR entries | Aggregate or de-duplicate CIDRs in `global_prefixes` |
| Route table not updated | Prefix list reference not attached to correct route table | Check TGW route table configuration in `tgw_crossregion_routes` module |

## Sequence Diagram

```
Engineer -> NetOpsAccount(us-west-2): make grpn-netops/us-west-2/tgw_crossregion_peering_create/prod/APPLY
NetOpsAccount(us-west-2) -> AWSEC2(us-west-2): aws_ec2_transit_gateway_peering_attachment (peer: eu-west-1 TGW)
AWSEC2(us-west-2) --> NetOpsAccount(us-west-2): peering-attachment-id (state: pending acceptance)
Engineer -> NetOpsAccount(eu-west-1): make grpn-netops/eu-west-1/tgw_crossregion_peering_accept/prod/APPLY
NetOpsAccount(eu-west-1) -> AWSEC2(eu-west-1): aws_ec2_transit_gateway_peering_attachment_accepter
AWSEC2(eu-west-1) --> NetOpsAccount(eu-west-1): peering state: available
Engineer -> NetOpsAccount(us-west-2): make grpn-netops/us-west-2/tgw_crossregion_routes/prod/APPLY
NetOpsAccount(us-west-2) -> AWSEC2(us-west-2): aws_ec2_managed_prefix_list (eu-west-1 CIDRs: 10.200.0.0/14, ...)
NetOpsAccount(us-west-2) -> AWSEC2(us-west-2): aws_ec2_transit_gateway_prefix_list_reference (via peering)
Engineer -> NetOpsAccount(eu-west-1): make grpn-netops/eu-west-1/tgw_crossregion_routes/prod/APPLY
NetOpsAccount(eu-west-1) -> AWSEC2(eu-west-1): aws_ec2_managed_prefix_list (us-west-2 CIDRs: 10.196.0.0/14, ...)
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Transit Gateway Provisioning](transit-gateway-provisioning.md), [Direct Connect Provisioning](direct-connect-provisioning.md)
