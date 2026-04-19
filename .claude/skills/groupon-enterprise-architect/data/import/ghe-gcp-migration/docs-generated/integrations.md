---
service: "ghe-gcp-migration"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 1
internal_count: 0
---

# Integrations

## Overview

The `ghe-gcp-migration` Terraform project has one external dependency: the GCP platform itself, accessed via the `hashicorp/google` Terraform provider (version 5.25.0) and authenticated through a GCP service account. There are no internal Groupon service-to-service integrations; this is an infrastructure provisioning repository, not an application service.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google Cloud Platform | GCP API (Terraform provider) | Provision and manage VPC, compute, load balancer, firewall, and disk resources | yes | `continuumGcpVpc`, `continuumGithubVm`, `continuumHttpLoadBalancer`, `continuumSshLoadBalancer` |
| GitHub Enterprise (image) | GCP disk image | Provides the GHE 3.10.6 OS image used to boot the `github-core` instance | yes | `continuumGithubVm` |

### Google Cloud Platform Detail

- **Protocol**: GCP REST APIs via `hashicorp/google` Terraform provider 5.25.0
- **Base URL / SDK**: `registry.terraform.io/hashicorp/google` version 5.25.0
- **Auth**: GCP Service Account key file referenced by `GOOGLE_APPLICATION_CREDENTIALS` environment variable / tfvars entry; project `prj-grp-general-sandbox-7f70`, region `us-central1`
- **Purpose**: All infrastructure resources (VPC, subnet, firewall, Nginx VM, GHE VM, persistent disk, managed instance group, autoscaler, load balancers, forwarding rules, TCP proxies, URL maps) are created and managed via GCP APIs
- **Failure mode**: If GCP APIs are unavailable, `terraform apply` fails and no infrastructure changes are made; existing provisioned resources continue running independently
- **Circuit breaker**: Not applicable — Terraform performs synchronous API calls with built-in retry logic

### GitHub Enterprise Image Detail

- **Protocol**: GCP disk image reference
- **Base URL / SDK**: `github-enterprise-public/github-enterprise-3-10-6` (GCP public image)
- **Auth**: Inherits GCP project credentials
- **Purpose**: Provides the bootable OS image for the `github-core` GCE instance with GHE 3.10.6 pre-installed
- **Failure mode**: Image must exist in GCP before `terraform apply`; if unavailable, instance creation fails
- **Circuit breaker**: Not applicable

## Internal Dependencies

> No evidence found in codebase.

This infrastructure project does not call any internal Groupon services.

## Consumed By

> Upstream consumers are tracked in the central architecture model.

Groupon engineers and CI/CD pipelines connect to GitHub Enterprise through the provisioned load balancers once infrastructure is live.

## Dependency Health

Terraform performs API health checks implicitly during `plan` and `apply` phases. GCP resource creation is retried automatically by the provider on transient failures. There are no application-layer health checks, circuit breakers, or retry policies defined in this repository.
