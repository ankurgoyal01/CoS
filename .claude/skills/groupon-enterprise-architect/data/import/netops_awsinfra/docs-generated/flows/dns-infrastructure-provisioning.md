---
service: "netops_awsinfra"
title: "DNS Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "dns-infrastructure-provisioning"
flow_type: batch
trigger: "Manual engineer action — apply dns or external_dns module"
participants:
  - "continuumNetopsTerragruntOrchestrator"
  - "continuumLegacyDnsModule"
  - "continuumExternalDnsModule"
  - "cloudPlatform"
architecture_ref: "containers-netops-awsinfra"
---

# DNS Infrastructure Provisioning

## Summary

This flow covers two distinct DNS provisioning paths managed by NetOps: the Legacy DNS module deploys DNS resolver EC2 instances (Amazon Linux 2) behind an Application Load Balancer with Route53 A records for name resolution within the Groupon network; the External DNS module deploys regional DNS infrastructure stacks for NetOps environments using Terragrunt. Both flows provision DNS infrastructure that supports name resolution for resources reachable via the Transit Gateway network.

## Trigger

- **Type**: manual
- **Source**: Network Operations engineer provisioning DNS infrastructure in a new region or updating existing DNS configuration
- **Frequency**: On demand — DNS infrastructure is long-lived; changes are infrequent

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Network Operations Engineer | Initiates DNS module apply operations | — |
| NetOps Terragrunt Orchestrator | Executes Terraform modules in the target account/region | `continuumNetopsTerragruntOrchestrator` |
| Legacy DNS Module | Provisions EC2 instances, security groups, ALB, listener, target groups, Route53 records | `continuumLegacyDnsModule` |
| External DNS Module | Executes Terragrunt external DNS stack for NetOps regions | `continuumExternalDnsModule` |
| AWS EC2 API | Creates instances, security groups, ALB | `cloudPlatform` |
| AWS Route53 API | Creates A records for DNS instances | `cloudPlatform` |

## Steps

### Legacy DNS Path

1. **Configure DNS instances in module variables**: Engineer defines `dns.instances`, `dns.instance_type`, `dns.name`, `dns.users`, and subnet/zone configuration in the `terragrunt.hcl` inputs for the `dns` module
   - From: Network Operations Engineer
   - To: `continuumLegacyDnsModuleConfig`
   - Protocol: HCL file edit / Git commit

2. **Apply Legacy DNS module**: Run `make <account>/<region>/dns/APPLY`; Terraform queries AMI data source for `amzn2-ami-kernel-5.10-hvm-2.0.20220426.0-x86_64-gp2` (Amazon Linux 2)
   - From: `continuumNetopsTerragruntOrchestratorExecutor`
   - To: `continuumLegacyDnsModuleProvisioner`
   - Protocol: Terragrunt CLI

3. **Create security group**: Terraform applies `aws_security_group` for DNS instance network access controls
   - From: `continuumLegacyDnsModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS API

4. **Launch DNS EC2 instances**: Terraform applies `aws_instance` for each entry in `dns.instances`; uses `user_data.tftpl` template to configure DNS software and users; sets `monitoring = true`, `volume_size = 30GB gp2`
   - From: `continuumLegacyDnsModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2 API)
   - Protocol: AWS API

5. **Provision Application Load Balancer**: Terraform applies ALB, listener, and target group resources; registers DNS instances as targets
   - From: `continuumLegacyDnsModuleProvisioner`
   - To: `cloudPlatform` (AWS EC2/ELB API)
   - Protocol: AWS API

6. **Create Route53 A records**: Terraform applies `aws_route53_record` with `type = "A"`, `ttl = 3600` for each DNS instance (`<dns.name>-<instance-key>.<zone-name>`), pointing to the instance private IP
   - From: `continuumLegacyDnsModuleProvisioner`
   - To: `cloudPlatform` (AWS Route53 API)
   - Protocol: AWS API

### External DNS Path

1. **Configure External DNS stack**: Engineer creates or updates Terragrunt stack configuration in `envs/<account>/<region>/external_dns/`
   - From: Network Operations Engineer
   - To: `continuumExternalDnsModuleConfig`
   - Protocol: HCL file edit / Git commit

2. **Apply External DNS Terragrunt stack**: Run make target for external DNS module; Terragrunt executes Terraform to provision external DNS-related infrastructure in the target NetOps region
   - From: `continuumExternalDnsModuleProvisioner`
   - To: `cloudPlatform` (AWS DNS/Route53 API)
   - Protocol: AWS API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMI not found | `data.aws_ami.amzn` filter returns no results | Update AMI name filter in `modules/dns/instance.tf` to a current Amazon Linux 2 AMI |
| Subnet not found | `data.aws_subnet.instance_subnet` lookup fails | Verify subnet tag/name in the target VPC |
| Route53 zone not found | `data.aws_route53_zone.zone` lookup fails | Verify hosted zone exists in the target account |
| Instance user_data provisioning failure | Instance launches but DNS software fails to configure | Check instance system logs; verify `user_data.tftpl` template variables |

## Sequence Diagram

```
Engineer -> NetOpsAccount: make <account>/<region>/dns/APPLY
NetOpsAccount -> AWSEC2: describe AMI (amzn2-ami-kernel-5.10)
AWSEC2 --> NetOpsAccount: ami-id
NetOpsAccount -> AWSEC2: create aws_security_group (dns)
NetOpsAccount -> AWSEC2: create aws_instance (x N, Amazon Linux 2, 30GB gp2)
AWSEC2 --> NetOpsAccount: instance-ids + private IPs
NetOpsAccount -> AWSELB: create ALB + listener + target groups
NetOpsAccount -> AWSRoute53: create aws_route53_record A (TTL=3600, private IP)
AWSRoute53 --> NetOpsAccount: record created
NetOpsAccount -> S3: write state
NetOpsAccount --> Engineer: apply complete
```

## Related

- Architecture dynamic view: `containers-netops-awsinfra`
- Related flows: [Account TGW Onboarding](account-tgw-onboarding.md)
