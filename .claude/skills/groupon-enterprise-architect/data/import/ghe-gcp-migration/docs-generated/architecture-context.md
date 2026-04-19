---
service: "ghe-gcp-migration"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
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
---

# Architecture Context

## System Context

The `ghe-gcp-migration` infrastructure sits within the `continuumSystem` (Continuum Platform) and provides Groupon's self-hosted GitHub Enterprise service on GCP. Groupon engineers and automated CI/CD pipelines consume this infrastructure by connecting to GHE over HTTP(S) (ports 80, 443, 8443) and SSH (ports 22, 122). The infrastructure is isolated in a private VPC and access-controlled via a firewall allowlist of known external IP ranges.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| GCP VPC Network | `continuumGcpVpc` | Network | GCP VPC | — | Private VPC (`ghe-vpc`) with global routing mode hosting all migration resources |
| GCP Subnet | `continuumGcpSubnet` | Network | GCP Subnetwork | — | Subnet (`public-subnet`, CIDR `172.31.1.0/24`) inside the VPC hosting compute instances |
| GCP Firewall Rules | `continuumGcpFirewallRules` | Security | GCP Firewall | — | Ingress allowlists for TCP 22, 80, 443, 8443, 122 from specific IP ranges |
| Nginx Core VM | `continuumNginxVm` | Compute | GCE VM (Ubuntu 20.04) | n1-standard-1 | Nginx reverse-proxy instance handling HTTP/HTTPS inbound traffic; 50 GB boot disk |
| GitHub Core VM | `continuumGithubVm` | Compute | GCE VM (GHE 3.10.6) | n2-highmem-16 | GitHub Enterprise application instance; 500 GB boot disk |
| GitHub External Disk | `continuumGithubExternalDisk` | Storage | GCP Persistent Disk (pd-standard) | — | 1.5 TB (1536 GB) attached data disk holding GHE repository and data storage |
| GitHub Instance Group | `continuumGithubInstanceGroup` | Compute | GCP Managed Instance Group | — | Managed instance group (`github-core-manager`) wrapping the GHE instance template |
| GitHub Autoscaler | `continuumGithubAutoscaler` | Scaling | GCP Autoscaler | — | Auto-scales the GHE instance group between 1 and 3 replicas at 60% CPU utilization |
| HTTP(S) Load Balancer | `continuumHttpLoadBalancer` | Networking | GCP Global Load Balancer | — | Global HTTP/HTTPS load balancer fronting Nginx on ports 80, 443, and 8443 |
| SSH TCP Load Balancer | `continuumSshLoadBalancer` | Networking | GCP Global TCP Load Balancer | — | Global TCP load balancer routing SSH traffic (ports 22 and 122) to the GHE instance group |

## Components by Container

> Not applicable — this is an infrastructure-only repository. No application components are defined. See `models/components.dsl` which contains no component definitions.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumGcpVpc` | `continuumGcpSubnet` | Contains | Network containment |
| `continuumGcpSubnet` | `continuumNginxVm` | Hosts | Network |
| `continuumGcpSubnet` | `continuumGithubVm` | Hosts | Network |
| `continuumGcpFirewallRules` | `continuumNginxVm` | Allows ingress (22/80/443/8443) | TCP |
| `continuumGcpFirewallRules` | `continuumGithubVm` | Allows ingress (22/122) | TCP |
| `continuumHttpLoadBalancer` | `continuumNginxVm` | Routes HTTP/HTTPS | HTTP/HTTPS |
| `continuumSshLoadBalancer` | `continuumGithubInstanceGroup` | Routes SSH | TCP |
| `continuumGithubInstanceGroup` | `continuumGithubVm` | Manages | GCP MIG |
| `continuumGithubAutoscaler` | `continuumGithubInstanceGroup` | Scales | GCP Autoscaler |
| `continuumGithubExternalDisk` | `continuumGithubVm` | Attached to | GCP disk attachment |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-ghe-gcp-migration`
- Component: `components-ghe-gcp-migration` — no components defined
