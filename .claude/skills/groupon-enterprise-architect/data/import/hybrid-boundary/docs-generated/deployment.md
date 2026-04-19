---
service: "hybrid-boundary"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "ec2-ami, lambda"
environments: [gensandbox, consandbox, staging, production]
---

# Deployment

## Overview

Hybrid Boundary uses a mixed deployment model. The edge proxy fleet (`continuumHybridBoundaryEdgeProxy`) runs on EC2 instances using Packer-baked AMIs deployed via Terraform. The Hybrid Boundary Agent is packaged as a Docker container (Alpine-based) and embedded in the AMI. The administrative API, RRDNS, and Iterator components are deployed as AWS Lambda functions. All infrastructure is managed via Terraform. CI/CD is handled by Jenkins on `cloud-jenkins.groupondev.com`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Agent container | Docker (Alpine) | `agent/Dockerfile` — Alpine base image; agent binary as entrypoint |
| CI build container | Docker | `Dockerfile` — `docker.groupondev.com/service-mesh/hybrid-boundary-ci:0.1` |
| Edge proxy AMI | Packer | `packer/` — AMI baked in `eu-west-1` staging, copied to production |
| Orchestration | EC2 Auto Scaling (Terraform) | `terraform/envs/` — per-environment Terraform configurations |
| Lambda functions | AWS Lambda (Go) | Deployed via Terraform; ARN referenced in `STATE_MACHINE_ARN` |
| Load balancer | AWS ELB (Target Groups) | Agent monitors target health via `-targetgrouparn` |
| DNS | AWS Route53 | `continuumHybridBoundaryDns` — managed by RRDNS Lambda |
| CDN allow-list | Akamai SiteShield | Agent periodically refreshes Akamai IP ranges to local ipset |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| `gensandbox` | General sandbox for feature testing | `us-west-2` | Internal only |
| `consandbox` | Consumer sandbox | Not specified | Internal only |
| `staging` | Pre-production validation | `eu-west-1` | Internal only |
| `production` | Live production traffic | `eu-west-1` | https://cloud-jenkins.groupondev.com/job/service-mesh/job/hybrid-boundary |

## CI/CD Pipeline

- **Tool**: Jenkins (declarative pipeline)
- **Config**: `Jenkinsfile`
- **Trigger**: Git tag push (`make deploy/<environment>` creates a signed tag with format `<env>-<region>-<timestamp>` and pushes it)

### Pipeline Stages

1. **Validate tag**: Parses the git tag to extract target environment and region(s)
2. **Debug Params**: Echoes pipeline parameters for audit traceability
3. **Unit test python scripts**: Runs `pytest tests/` against Python tooling
4. **Unit test openapi-schema**: Runs `make -C openapi-schema docker-all` to validate OpenAPI schema
5. **Validate configs**: Runs `bin/config.py validate configs/*/*/*.yml` to validate YAML routing configs
6. **Setup GPG environment**: Imports GPG key and runs `git crypt unlock` to decrypt secrets
7. **Terraform: check format**: Runs `make -C terraform check-fmt` to ensure Terraform formatting
8. **Unit test go scripts**: Runs `go mod download && go test ./... -v`
9. **Build/publish edge-proxy agent**: Builds Go agent binary, publishes Docker image, builds Lambda artifacts via `make -C agent publish` and `make -C agent build-lambdas`
10. **Bake AMI in stable (eu-west-1)**: Runs `make -C packer ami` in the `grpn-stable` account; copies AMI to production if on master branch
11. **Terraform plan (optional)**: Runs `make -C terraform plan-env/production/eu-west-1` if `TERRAFORM_PLAN` parameter is set
12. **Deploy to Production**: Runs `make -C terraform apply-env/production/<region>` if tag environment is `production` and build is not a PR

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (edge proxy fleet) | EC2 Auto Scaling | Managed via Terraform; ASG lifecycle events trigger the RRDNS Lambda to update DNS weights |
| Lambda concurrency | AWS Lambda managed | Default AWS Lambda concurrency limits apply |
| xDS streams | Configurable max streams | `-maxstreams` flag (default `10000`) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| Agent CPU | Not specified in repo | Not specified in repo |
| Agent Memory | Not specified in repo | Not specified in repo |
| Lambda Memory | Not specified in repo | Not specified in repo |

> Deployment configuration managed via Terraform in `terraform/` directory. Resource sizes are defined in Terraform HCL and not surfaced in application source.
