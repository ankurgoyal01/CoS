---
service: "ghe-gcp-migration"
title: "Infrastructure Provisioning"
generated: "2026-03-03"
type: flow
flow_name: "infrastructure-provisioning"
flow_type: batch
trigger: "Manual execution of terraform apply by a platform engineer"
participants:
  - "continuumGcpVpc"
  - "continuumGcpSubnet"
  - "continuumGcpFirewallRules"
  - "continuumNginxVm"
  - "continuumGithubVm"
  - "continuumGithubExternalDisk"
  - "continuumGithubInstanceGroup"
  - "continuumGithubAutoscaler"
  - "continuumHttpLoadBalancer"
  - "continuumSshLoadBalancer"
architecture_ref: "dynamic-ghe-gcp-migration"
---

# Infrastructure Provisioning

## Summary

This flow describes how a platform engineer provisions the complete GHE GCP environment using Terraform. Running `terraform apply` against the root module orchestrates the creation of all GCP resources in dependency order: VPC first, then subnet and firewall, then compute instances and persistent disk, then the managed instance group and autoscaler, and finally the load balancers. The result is a fully operational GitHub Enterprise environment accessible over HTTP(S) and SSH.

## Trigger

- **Type**: manual
- **Source**: Platform engineer running `terraform apply` from the repository root
- **Frequency**: On-demand (initial provisioning or infrastructure changes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Terraform CLI | Orchestrates resource creation via GCP API | — |
| GCP VPC Network | Created first; provides network isolation | `continuumGcpVpc` |
| GCP Subnet | Created within VPC; hosts compute resources | `continuumGcpSubnet` |
| GCP Firewall Rules | Applied to VPC; controls ingress traffic | `continuumGcpFirewallRules` |
| GitHub External Disk | Persistent data disk created before VM attachment | `continuumGithubExternalDisk` |
| Nginx Core VM | Nginx proxy compute instance | `continuumNginxVm` |
| GitHub Core VM | GHE application compute instance | `continuumGithubVm` |
| GitHub Instance Group | Managed instance group wrapping GHE template | `continuumGithubInstanceGroup` |
| GitHub Autoscaler | Autoscaling policy attached to instance group | `continuumGithubAutoscaler` |
| HTTP(S) Load Balancer | Global load balancer for web traffic | `continuumHttpLoadBalancer` |
| SSH TCP Load Balancer | Global TCP load balancer for SSH traffic | `continuumSshLoadBalancer` |

## Steps

1. **Initialize Terraform**: Engineer runs `terraform init` to download provider `hashicorp/google` 5.25.0 and initialize module references (`vpc`, `compute`, `loadbalancer`, `firewall`)
   - From: `Engineer workstation`
   - To: `Terraform Registry / GCP`
   - Protocol: HTTPS

2. **Plan infrastructure changes**: Engineer runs `terraform plan` to preview resource creation against current GCP state
   - From: `Engineer workstation`
   - To: `GCP APIs`
   - Protocol: GCP REST API

3. **Create VPC and subnet** (`module.vpc`): Terraform creates GCP VPC `ghe-vpc` with `auto_create_subnetworks = false` and routing mode `GLOBAL`; creates subnet `public-subnet` with CIDR `172.31.1.0/24` in region `us-central1`
   - From: `Terraform / module.vpc`
   - To: `GCP Compute Network API`
   - Protocol: GCP REST API

4. **Apply firewall rules** (`module.firewall`): Terraform creates firewall rule `allow-world-access` permitting TCP 22, 80, 443, 8443, 122 from the allowlisted IP ranges; also creates VPC-level rules `allow-icmp-ssh` and `allow-http-https`
   - From: `Terraform / module.firewall`
   - To: `GCP Compute Firewall API`
   - Protocol: GCP REST API

5. **Create persistent disk**: Terraform creates `github-core-external-disk` (1536 GB, `pd-standard`) in zone `us-central1-b`
   - From: `Terraform / module.compute`
   - To: `GCP Compute Disk API`
   - Protocol: GCP REST API

6. **Create Nginx VM** (`nginx-core`): Terraform creates GCE instance `nginx-core` with machine type `n1-standard-1`, Ubuntu 20.04 LTS image, 50 GB boot disk, attached to VPC, tagged `nginx`; SSH public key injected via instance metadata
   - From: `Terraform / module.compute`
   - To: `GCP Compute Instances API`
   - Protocol: GCP REST API

7. **Create GHE VM and instance template**: Terraform creates GCE instance `github-core` (machine type `n2-highmem-16`, GHE 3.10.6 image, 500 GB boot disk, `external-disk` attached) and instance template `github-core-template` for the managed instance group
   - From: `Terraform / module.compute`
   - To: `GCP Compute Instances API`
   - Protocol: GCP REST API

8. **Create managed instance group**: Terraform creates `github-core-manager` managed instance group in zone `us-central1-b` using `github-core-template`, target size 1
   - From: `Terraform / module.compute`
   - To: `GCP Compute Instance Groups API`
   - Protocol: GCP REST API

9. **Create autoscaler**: Terraform creates `github-core-autoscaler` with min 1, max 3 replicas and 60% CPU utilization target, targeting `github-core-manager`
   - From: `Terraform / module.compute`
   - To: `GCP Compute Autoscalers API`
   - Protocol: GCP REST API

10. **Create load balancers** (`module.loadbalancer`): Terraform creates backend services (`nginx-backend`, `github-backend`), URL map `lb-url-map`, HTTP target proxy `lb-proxy`, TCP proxy `github-proxy`, and forwarding rules `http-lb` (80), `https-lb` (443), `custom-https-lb` (8443), `github-ssh-lb` (22, 122)
    - From: `Terraform / module.loadbalancer`
    - To: `GCP Compute Load Balancing API`
    - Protocol: GCP REST API

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| GCP API authentication failure | Terraform exits immediately with credentials error | No resources created; engineer must fix `GOOGLE_APPLICATION_CREDENTIALS` |
| Resource creation quota exceeded | Terraform reports GCP quota error | Partial apply; engineer must request quota increase then re-apply |
| Dependency not yet available (e.g., VPC not ready before subnet) | Terraform `depends_on` and implicit dependency graph prevents out-of-order creation | Terraform waits and retries; if timeout, manual intervention required |
| `terraform apply` interrupted mid-run | Terraform state file captures partially created resources | Run `terraform apply` again to reconcile remaining resources |
| Disk image not found (`github-enterprise-public/github-enterprise-3-10-6`) | GCP API returns 404; Terraform fails VM creation step | Engineer must verify image exists and update `github_image` variable |

## Sequence Diagram

```
Engineer -> TerraformCLI: terraform init
TerraformCLI -> TerraformRegistry: download hashicorp/google 5.25.0
Engineer -> TerraformCLI: terraform apply
TerraformCLI -> GCP_VPC_API: create ghe-vpc + public-subnet
GCP_VPC_API --> TerraformCLI: vpc_self_link
TerraformCLI -> GCP_Firewall_API: create allow-world-access, allow-icmp-ssh, allow-http-https
TerraformCLI -> GCP_Disk_API: create github-core-external-disk (1536 GB)
GCP_Disk_API --> TerraformCLI: disk_id
TerraformCLI -> GCP_Compute_API: create nginx-core (n1-standard-1, Ubuntu 20.04)
TerraformCLI -> GCP_Compute_API: create github-core (n2-highmem-16, GHE 3.10.6) + attach external-disk
TerraformCLI -> GCP_Compute_API: create github-core-template + github-core-manager + github-core-autoscaler
TerraformCLI -> GCP_LB_API: create nginx-backend, github-backend, lb-url-map, lb-proxy, github-proxy
TerraformCLI -> GCP_LB_API: create http-lb (80), https-lb (443), custom-https-lb (8443), github-ssh-lb (22,122)
GCP_LB_API --> TerraformCLI: forwarding rule external IPs
TerraformCLI --> Engineer: Apply complete — outputs: nginx_instance_self_link, github_instance_group
```

## Related

- Architecture dynamic view: `dynamic-ghe-gcp-migration`
- Related flows: [HTTP/HTTPS Traffic Routing](http-traffic-routing.md), [SSH Traffic Routing](ssh-traffic-routing.md), [GHE Autoscaling](ghe-autoscaling.md)
