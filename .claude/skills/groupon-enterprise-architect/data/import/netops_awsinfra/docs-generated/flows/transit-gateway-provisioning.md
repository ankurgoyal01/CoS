---
service: "netops_awsinfra"
title: "Transit Gateway Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "transit-gateway-provisioning"
flow_type: batch
trigger: "Manual engineer action — make grpn-netops/<region>/tgw/<env>/APPLY"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumTransitGatewayModule"
  - "continuumNetworkGlobalModule"
  - "cloudPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# Transit Gateway Provisioning

## Summary

This flow provisions a new AWS Transit Gateway in a target region for the `grpn-netops` account. The TGW is created with a BGP ASN specific to the region, registered in the AWS Network Manager global network (`Groupon`), and immediately made available for RAM sharing to workload accounts. This flow establishes the regional network routing hub that all subsequent VPC attachments depend on.

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer running `make grpn-netops/<region>/tgw/<env>/plan` followed by `make grpn-netops/<region>/tgw/<env>/APPLY`
- **Frequency**: On demand — typically once per new region or when a new TGW set is required (e.g., the Teradata-specific TGW `grpn-netops-teradata-TGW`)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Initiates apply; reviews plan output | — |
| NetOps Terragrunt Orchestrator | Resolves module source path; executes Terraform against `grpn-netops` account | `continuumNetopsTerragruntOrchestrator` |
| Transit Gateway Module | Defines and applies TGW, RAM share, and Network Manager registration resources | `continuumTransitGatewayModule` |
| Network Global Module | Provides global network context for Network Manager registration | `continuumNetworkGlobalModule` |
| AWS EC2 / Transit Gateway API | Creates `aws_ec2_transit_gateway` resource | `cloudPlatform` |
| AWS RAM API | Creates `aws_ram_resource_share` and `aws_ram_resource_association` | `cloudPlatform` |
| AWS Network Manager API | Registers TGW in global network `Groupon` | `cloudPlatform` |

## Steps

1. **Resolve account and region**: Terragrunt reads `envs/grpn-netops/account.hcl` and the region `region.hcl`; extracts TGW name (e.g., `grpn-netops-TGW`) and BGP ASN for the target region (e.g., `64514` for `us-west-2`)
   - From: `continuumNetopsTerragruntOrchestratorConfig`
   - To: `continuumNetopsTerragruntOrchestratorExecutor`
   - Protocol: HCL file read

2. **Run Terraform plan**: Terragrunt CLI executes `terraform plan` against `modules/tgw/`; shows resources to create: `aws_ec2_transit_gateway`, `aws_ec2_tag` (for route table), `aws_ram_resource_share`, `aws_ram_resource_association`, `aws_networkmanager_transit_gateway_registration`
   - From: `continuumNetopsTerragruntOrchestratorExecutor`
   - To: `continuumTransitGatewayModuleConfig`
   - Protocol: Terraform CLI

3. **Engineer reviews and approves plan**: Engineer confirms resource additions are correct; runs APPLY Make target
   - From: Network Operations Engineer
   - To: `continuumNetopsTerragruntOrchestratorExecutor`
   - Protocol: Make CLI

4. **Create Transit Gateway**: Terraform applies `aws_ec2_transit_gateway` with `auto_accept_shared_attachments = disable` and `default_route_table_association/propagation = enable`; applies `aws_ec2_tag` to tag the default route table
   - From: `continuumTransitGatewayModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS API

5. **Create RAM Resource Share**: Terraform applies `aws_ram_resource_share` with `allow_external_principals = true` and associates the TGW ARN via `aws_ram_resource_association`
   - From: `continuumTransitGatewayModuleProvisioner`
   - To: `cloudPlatform` (AWS RAM API)
   - Protocol: AWS API

6. **Register TGW in Network Manager**: Terraform queries `aws_networkmanager_global_networks` data source to find the global network tagged `Name = Groupon`; applies `aws_networkmanager_transit_gateway_registration`
   - From: `continuumTransitGatewayModuleProvisioner`
   - To: `cloudPlatform` (AWS Network Manager API)
   - Protocol: AWS API

7. **Write Terraform state**: State file updated in S3 remote backend under `netops::netops_awsinfra` project with TGW ID, ARN, and RAM ARN
   - From: `continuumTransitGatewayModuleProvisioner`
   - To: S3 remote state
   - Protocol: AWS S3 API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AWS API throttling | Terraform provider built-in retry with exponential backoff | Apply retries automatically |
| Duplicate TGW name | Terraform plan shows no changes if TGW already exists in state; fails if out-of-band TGW exists | Engineer must import or reconcile |
| Network Manager registration fails | Terraform apply returns error; partial state; TGW is created but not registered | Re-run apply; check `aws_networkmanager_global_networks` data source for global network existence |
| State lock conflict | S3 DynamoDB lock prevents concurrent apply | Wait for lock release or `terraform force-unlock` after confirming no active apply |

## Sequence Diagram

```
Engineer -> Make: make grpn-netops/us-west-2/tgw/prod/APPLY
Make -> TerragruntCLI: terragrunt run-all apply
TerragruntCLI -> account.hcl: read TGW name and ASN
TerragruntCLI -> AWSapi(EC2): create aws_ec2_transit_gateway (ASN=64514)
AWSapi(EC2) --> TerragruntCLI: tgw-id = tgw-04ea5e0ae2c455885
TerragruntCLI -> AWSapi(RAM): create aws_ram_resource_share + association
AWSapi(RAM) --> TerragruntCLI: RAM ARN
TerragruntCLI -> AWSapi(NetworkManager): register TGW in global network "Groupon"
AWSapi(NetworkManager) --> TerragruntCLI: registration confirmed
TerragruntCLI -> S3: write state
TerragruntCLI --> Engineer: apply complete
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Account TGW Onboarding](account-tgw-onboarding.md), [Cross-Region TGW Peering](cross-region-tgw-peering.md)
