---
service: "netops_awsinfra"
title: "Direct Connect Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "direct-connect-provisioning"
flow_type: batch
trigger: "Manual engineer action — new DX connection ordered and provisioned through Terraform modules"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumDirectConnectModule"
  - "continuumDirectConnectGatewayModule"
  - "continuumDirectConnectVirtualInterfaceNetopsModule"
  - "continuumDirectConnectTransitInterfaceNetopsModule"
  - "continuumTransitGatewayDcgAssociationModule"
  - "cloudPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# Direct Connect Provisioning

## Summary

This flow provisions the full Direct Connect connectivity path from a Groupon datacenter to AWS. It creates a physical DX connection at a colocation facility (Equinix ECX), creates Direct Connect Gateways (DCGs) with BGP ASNs for peering, creates virtual interfaces (private for per-account connectivity, transit for TGW-based connectivity), and finally associates the DCG with the Transit Gateway to complete the on-premise-to-AWS routing path. Two DCGs exist in the NetOps account: `DCG-NETOPS-PROD` (ASN `65312`) and `DCG-NETOPS-TERADATA` (ASN `65332`).

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer provisioning a new DX connection or adding a new DX virtual interface for an account
- **Frequency**: On demand — DX connections are long-lived; virtual interfaces are added when new accounts require DX connectivity

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Initiates all apply operations; coordinates with Equinix for physical connection LOA | — |
| NetOps Terragrunt Orchestrator | Executes Terraform in NetOps account | `continuumNetopsTerragruntOrchestrator` |
| Direct Connect Module | Provisions `aws_dx_connection` resources | `continuumDirectConnectModule` |
| Direct Connect Gateway Module | Provisions `aws_dx_gateway` resources | `continuumDirectConnectGatewayModule` |
| DX Virtual Interface NetOps Module | Creates private virtual interfaces (`aws_dx_private_virtual_interface`) | `continuumDirectConnectVirtualInterfaceNetopsModule` |
| DX Transit Interface NetOps Module | Creates transit virtual interfaces (`aws_dx_transit_virtual_interface`) for TGW | `continuumDirectConnectTransitInterfaceNetopsModule` |
| DX Virtual Interface Create Module | Creates hosted private VIFs (`aws_dx_hosted_private_virtual_interface`) for workload accounts | `continuumDirectConnectVirtualInterfaceCreateModule` |
| DX Virtual Interface Accept Module | Accepts hosted private VIFs in workload accounts | `continuumDirectConnectVirtualInterfaceAcceptModule` |
| TGW-DCG Association Module | Associates DCG with TGW via `aws_dx_gateway_association` | `continuumTransitGatewayDcgAssociationModule` |
| AWS Direct Connect API | Physical connectivity and virtual interface management | `cloudPlatform` |

## Steps

1. **Define DX connection in account.hcl**: Engineer adds DX connection definition to `envs/grpn-netops/account.hcl` under `dxcons` map for the target region (e.g., `us-east-2`), specifying `provider = "Equinix"`, `bandwidth = "10Gbps"`, `location = "EQC50"`, `interface`, and `device`
   - From: Network Operations Engineer
   - To: `continuumNetopsTerragruntOrchestratorConfig`
   - Protocol: Git commit

2. **Apply DX Connection**: Run `make grpn-netops/<region>/dxcon/APPLY`; Terraform applies `aws_dx_connection` for each entry in `dxcons[<region>]`; tags with `Interface` and `Device` metadata
   - From: `continuumDirectConnectModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

3. **Apply Direct Connect Gateway**: Run `make grpn-netops/global/dcg/prod/APPLY`; Terraform applies `aws_dx_gateway` with `name = "DCG-NETOPS-PROD"` and `amazon_side_asn = "65312"`
   - From: `continuumDirectConnectGatewayModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

4. **Create transit virtual interface**: Run `make grpn-netops/<region>/grpn-netops/prod/dxti_create_netops/APPLY`; Terraform applies `aws_dx_transit_virtual_interface` to attach DCG to the DX connection via BGP (ASN `12269`, address family `ipv4`)
   - From: `continuumDirectConnectTransitInterfaceNetopsModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

5. **Create hosted private virtual interfaces for workload accounts** (optional): Run `dxvi_create` module; Terraform applies `aws_dx_hosted_private_virtual_interface` for each workload account; writes VIF data to local YAML for cross-module sharing
   - From: `continuumDirectConnectVirtualInterfaceCreateModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

6. **Accept hosted private VIFs in workload accounts** (optional): Run `dxvi_accept` module in each workload account; Terraform applies `aws_dx_hosted_private_virtual_interface_accepter`
   - From: `continuumDirectConnectVirtualInterfaceAcceptModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

7. **Associate DCG with Transit Gateway**: Run `make grpn-netops/<region>/tgw_dcg_associations/prod/APPLY`; Terraform applies `aws_dx_gateway_association` linking DCG (`DCG-NETOPS-PROD`) to TGW (`grpn-netops-TGW`); configures allowed prefixes from `dcg_associations` in `account.hcl`
   - From: `continuumTransitGatewayDcgAssociationModuleProvisioner`
   - To: `cloudPlatform` (AWS Direct Connect API)
   - Protocol: AWS API

8. **BGP peering established**: On-premise datacenter routers (BGP ASN `12269`) establish BGP sessions over the virtual interfaces; routes are exchanged and propagated through TGW route tables
   - From: On-premise router
   - To: AWS Direct Connect / TGW BGP
   - Protocol: BGP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| DX connection in `pending` state | Connection ordered but not yet accepted by Equinix | Wait; contact Equinix ECX (`EQC50`) for LOA provisioning |
| BGP session not established | Transit VIF created but on-premise router not configured | Network Operations team configures datacenter router with correct BGP peer IPs and ASN |
| DCG-TGW association fails | May be limited to 3 TGWs per DCG | Review `dcg_associations` map; DCG `DCG-NETOPS-PROD` is associated with `eu-west-1`, `us-west-1`, and `us-west-2` TGWs |
| Prefix list exceeds 20 entries | AWS limits TGW DCG associations to 20 prefixes | Aggregate CIDRs into supernets in `global_prefixes` |

## Sequence Diagram

```
Engineer -> NetOpsAccount: make grpn-netops/us-east-2/dxcon/APPLY
NetOpsAccount -> AWSDX: create aws_dx_connection (CFR_ECX_10G_CFR01, 10Gbps, Equinix EQC50)
AWSDX --> NetOpsAccount: connection-id (state: pending)
Equinix -> AWSDX: provision physical cross-connect (LOA)
AWSDX --> NetOpsAccount: connection state: available
Engineer -> NetOpsAccount: make grpn-netops/global/dcg/prod/APPLY
NetOpsAccount -> AWSDX: create aws_dx_gateway (DCG-NETOPS-PROD, ASN=65312)
AWSDX --> NetOpsAccount: dcg-id
Engineer -> NetOpsAccount: make grpn-netops/eu-west-1/grpn-netops/prod/dxti_create_netops/APPLY
NetOpsAccount -> AWSDX: create aws_dx_transit_virtual_interface (BGP ASN=12269)
AWSDX --> NetOpsAccount: vif-id
OnPremRouter -> AWSDX: establish BGP session
Engineer -> NetOpsAccount: make grpn-netops/us-west-2/tgw_dcg_associations/prod/APPLY
NetOpsAccount -> AWSDX: create aws_dx_gateway_association (DCG-NETOPS-PROD <-> grpn-netops-TGW)
AWSDX --> NetOpsAccount: association established
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Transit Gateway Provisioning](transit-gateway-provisioning.md), [Account TGW Onboarding](account-tgw-onboarding.md)
- External documentation: `docs/GrouponAWSConnectivity2020.pdf`, `docs/Teradata_Connectivity.md`
