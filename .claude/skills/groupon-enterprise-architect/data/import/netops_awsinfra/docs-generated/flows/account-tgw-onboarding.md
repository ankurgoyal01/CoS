---
service: "netops_awsinfra"
title: "Account TGW Onboarding"
generated: "2026-03-03"
type: flow
flow_name: "account-tgw-onboarding"
flow_type: batch
trigger: "Manual engineer action — new account added to customers.yml, tgw_share applied, then tgw_accept applied in workload account"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumTransitGatewayShareModule"
  - "continuumTransitGatewayAcceptModule"
  - "continuumTransitGatewayVpcAttachmentTaggingModule"
  - "cloudPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# Account TGW Onboarding

## Summary

This flow connects a new AWS workload account to the Groupon Transit Gateway network. It involves two separate apply operations executed in two different AWS accounts: first the NetOps account shares the TGW to the workload account via AWS RAM, then the workload account accepts the share and creates a VPC attachment. Cross-module data is passed via a `tgw_data.yml` file written by the share module and read by the accept module. Finally, VPC attachment metadata is written back to the NetOps account for tagging.

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer adds account to `envs/customers.yml`, creates account directory structure under `envs/`, and runs share and accept apply operations
- **Frequency**: On demand — once per new account onboarding or new region expansion for an existing account

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Configures account files; initiates all apply operations | — |
| NetOps Terragrunt Orchestrator | Executes modules in both NetOps and workload accounts | `continuumNetopsTerragruntOrchestrator` |
| Transit Gateway Share Module | Creates RAM principal association; writes `tgw_data.yml` to workload account directory | `continuumTransitGatewayShareModule` |
| Transit Gateway Accept Module | Accepts RAM share; creates VPC attachment; creates managed prefix list and routes | `continuumTransitGatewayAcceptModule` |
| TGW VPC Attachment Tagging Module | Reads attachment metadata YAML and applies `aws_ec2_tag` resources | `continuumTransitGatewayVpcAttachmentTaggingModule` |
| AWS RAM API | Manages resource share and acceptance | `cloudPlatform` |
| AWS EC2 API | Creates VPC attachment and route resources | `cloudPlatform` |

## Steps

1. **Register account in customers.yml**: Engineer adds new account (e.g., `grpn-cloudcore-dev`) to `envs/customers.yml` with `owner_id` and `dc_vlan` settings; marks `third_party: false`
   - From: Network Operations Engineer
   - To: `envs/customers.yml`
   - Protocol: Git commit

2. **Create account directory structure**: Engineer creates `envs/<account>/account.hcl`, `envs/<account>/<region>/region.hcl`, and `envs/<account>/<region>/prod/tgw_accept/terragrunt.hcl`
   - From: Network Operations Engineer
   - To: `continuumNetopsTerragruntOrchestratorConfig`
   - Protocol: Git commit

3. **Apply TGW Share in NetOps account**: Run `make grpn-netops/<region>/<account>/prod/tgw_share/APPLY`; Terragrunt applies `aws_ram_principal_association` using the workload account's `owner_id` from `customers.yml`
   - From: `continuumTransitGatewayShareModule`
   - To: `cloudPlatform` (AWS RAM API)
   - Protocol: AWS API

4. **Write tgw_data.yml**: `tgw_share` module applies `local_file` resource to write `tgw_data.yml` into `envs/<account>/<region>/prod/tgw_accept/` with fields: `tgw_id`, `tgw_name`, `tgw_owner_account`, `tgw_ram_arn`
   - From: `continuumTransitGatewayShareModuleProvisioner`
   - To: Local filesystem (Git repo)
   - Protocol: Terraform `local_file` resource

5. **Commit tgw_data.yml**: Engineer commits the generated `tgw_data.yml` file to the repository so it is available for the accept step
   - From: Network Operations Engineer
   - To: Git repository
   - Protocol: Git commit

6. **Apply TGW Accept in workload account**: Run `make <account>/<region>/prod/tgw_accept/APPLY`; Terragrunt reads `tgw_data.yml` as inputs; applies `aws_ram_resource_share_accepter` to accept the RAM share
   - From: `continuumTransitGatewayAcceptModuleProvisioner`
   - To: `cloudPlatform` (AWS RAM API)
   - Protocol: AWS API

7. **Create VPC attachment**: Terraform applies `aws_ec2_transit_gateway_vpc_attachment` using the `PrimaryVPC` VPC and designated subnets in the workload account
   - From: `continuumTransitGatewayAcceptModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS API

8. **Create managed prefix list and routes**: Terraform applies `aws_ec2_managed_prefix_list` with CIDR routes from `tgw_route_table_routes` (e.g., `10.0.0.0/8`) and `aws_route` entries in all VPC route tables pointing to the TGW
   - From: `continuumTransitGatewayAcceptModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS API

9. **Write attachment metadata**: `tgw_accept` module writes `<account>.yml` to the NetOps account's `tgw_vpc_attachments_tag` directory with `tgw_attachment_id` and `tgw_attachment_vpc`
   - From: `continuumTransitGatewayAcceptModuleProvisioner`
   - To: Local filesystem (Git repo)
   - Protocol: Terraform `local_file` resource

10. **Apply TGW VPC Attachment Tagging**: Engineer runs `tgw_vpc_attachments_tag` module in NetOps account; applies `aws_ec2_tag` resources to label attachment with account metadata
    - From: `continuumTransitGatewayVpcAttachmentTaggingModule`
    - To: `cloudPlatform` (AWS EC2 API)
    - Protocol: AWS API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `tgw_data.yml` not committed before accept apply | `yamldecode(file(...))` fails at plan time | Engineer must commit `tgw_data.yml` and re-run |
| RAM share not yet accepted when VPC attachment is attempted | `aws_ec2_transit_gateway_vpc_attachment` has `depends_on = [aws_ram_resource_share_accepter.tgw]` | Terraform waits for acceptance before creating attachment |
| VPC not found by `PrimaryVPC` tag | Data source lookup fails; plan errors | Verify Landing Zone VPC tag in workload account |
| Subnet filter returns empty set | VPC attachment fails | Verify subnet tags match `vpc_attachment_subnetname` variable |

## Sequence Diagram

```
Engineer -> NetOpsAccount: make grpn-netops/us-west-2/grpn-cloudcore-dev/prod/tgw_share/APPLY
NetOpsAccount -> AWSRAM: create aws_ram_principal_association (owner_id=130530573605)
AWSRAM --> NetOpsAccount: share created
NetOpsAccount -> LocalFile: write tgw_data.yml (tgw_id, tgw_ram_arn)
Engineer -> Git: commit tgw_data.yml
Engineer -> WorkloadAccount: make grpn-cloudcore-dev/us-west-2/prod/tgw_accept/APPLY
WorkloadAccount -> tgw_data.yml: read tgw_id, tgw_ram_arn
WorkloadAccount -> AWSRAM: aws_ram_resource_share_accepter
AWSRAM --> WorkloadAccount: accepted
WorkloadAccount -> AWSEC2: aws_ec2_transit_gateway_vpc_attachment
AWSEC2 --> WorkloadAccount: attachment-id
WorkloadAccount -> AWSEC2: aws_ec2_managed_prefix_list + aws_route (10.0.0.0/8 -> TGW)
WorkloadAccount -> LocalFile: write <account>.yml (tgw_attachment_id)
Engineer -> NetOpsAccount: make grpn-netops/us-west-2/tgw_vpc_attachments_tag/prod/APPLY
NetOpsAccount -> AWSEC2: aws_ec2_tag (attachment metadata)
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Transit Gateway Provisioning](transit-gateway-provisioning.md), [Cross-Region TGW Peering](cross-region-tgw-peering.md)
