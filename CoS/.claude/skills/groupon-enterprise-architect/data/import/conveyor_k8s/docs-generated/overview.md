---
service: "conveyor_k8s"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Platform Engineering / Kubernetes Infrastructure"
platform: "Continuum (Conveyor Cloud)"
team: "Conveyor Cloud"
status: active
tech_stack:
  language: "Go"
  language_version: "1.24"
  framework: "cobra"
  framework_version: "0.0.5"
  runtime: "Docker"
  runtime_version: "Alpine 3.18"
  build_tool: "Make"
  package_manager: "Go modules"
---

# Conveyor K8s Overview

## Purpose

Conveyor K8s is Groupon's Kubernetes cluster lifecycle management platform. It automates the full lifecycle of EKS (AWS) and GKE (GCP) clusters — from infrastructure provisioning with Terraform/Terragrunt, through OS image baking with Packer, cluster configuration with Ansible, and cluster promotion across environments. It provides the operational backbone that all Groupon services run on by ensuring reliable, repeatable, and auditable cluster creation and promotion.

## Scope

### In scope

- Terraform/Terragrunt modules for EKS cluster provisioning (AWS, `terra-eks/`)
- Terraform/Terragrunt modules for GKE cluster provisioning (GCP, `terra-gke/`)
- Ansible provisioning playbooks for Kubernetes configuration (`conveyor_provisioning_playbook/`)
- Packer-based AMI baking for EKS worker node images (`machine-image-baking/`)
- Jenkins pipeline definitions for cluster create, promote, rollback, and delete lifecycle operations (`pipelines/`)
- GitHub Actions workflows for GitOps-style Ansible deployments to dev, stable, and production environments
- Go utility binaries consumed by CI/CD pipelines: `ami_lookup`, `ami_publish`, `find_clusters`, `services_readiness`, `changelog`, `wavefront`, `promotion`
- Sandbox cluster cleanup scheduling

### Out of scope

- Application-level service deployments (owned by individual service teams via Conveyor)
- Kubernetes RBAC policy enforcement at runtime (enforced by Open Policy Agent, configured by these playbooks)
- DNS, load balancer, or certificate management outside of cluster bootstrap

## Domain Context

- **Business domain**: Platform Engineering / Kubernetes Infrastructure
- **Platform**: Continuum (Conveyor Cloud team)
- **Upstream consumers**: All Groupon services that run on Conveyor-managed Kubernetes clusters; Jenkins pipelines and GitHub Actions workflows that invoke this repository's pipelines
- **Downstream dependencies**: AWS EC2/EKS APIs, GCP GKE APIs, AWS S3 (cluster state), Wavefront (deployment event tracking), Kubernetes API (readiness checks, promotion metadata)

## Stakeholders

| Role | Description |
|------|-------------|
| Conveyor Cloud Team | Owns and maintains the cluster lifecycle pipelines and tooling |
| Platform / SRE | Operates and monitors cluster health, approves production promotions |
| Service Teams | Consume clusters provisioned by this repo; do not interact directly |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (pipeline utils) | Go | 1.24 | `conveyor-pipeline-utils/go.mod` |
| CLI framework | cobra | 0.0.5 | `conveyor-pipeline-utils/go.mod` |
| Infrastructure as Code (AWS) | Terraform / Terragrunt | >= 0.13 | `terra-eks/modules/eks-cluster/versions.tf` |
| Infrastructure as Code (GCP) | Terraform / Terragrunt | >= 1.7.5 | `terra-gke/modules/gke-cluster/versions.tf` |
| Configuration management | Ansible | (playbook-runner image) | `conveyor_provisioning_playbook/`, `.github/actions/run-playbooks/action.yml` |
| Image baking | Packer | 1.6.5 | `conveyor-pipeline-utils/Dockerfile` |
| CI orchestration (legacy) | Jenkins (Groovy DSL) | conveyor-pipeline-dsl@v1.0.167 | `Jenkinsfile` |
| CI orchestration (GitOps) | GitHub Actions | actions/checkout@v4 | `.github/workflows/` |
| Container runtime | Docker (Alpine 3.18) | alpine:3.18 | `conveyor-pipeline-utils/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `github.com/aws/aws-sdk-go` | v1.44.251 | cloud-sdk | AWS S3, EC2 API access for AMI lookup/publish and cluster state |
| `github.com/aws/aws-sdk-go-v2` | v0.19.0 | cloud-sdk | Newer AWS SDK (supplementary) |
| `github.com/spf13/cobra` | v0.0.5 | http-framework | CLI command structure for all utility binaries |
| `github.com/spf13/pflag` | v1.0.5 | http-framework | POSIX-style flag parsing for CLI tools |
| `github.com/kelseyhightower/envconfig` | v1.4.0 | config | Environment-variable-based configuration loading |
| `github.com/jpillora/backoff` | v1.0.0 | scheduling | Exponential backoff with jitter for readiness polling |
| `github.com/matryer/try` | v0.0.0 | scheduling | Retry logic for cluster readiness checks |
| `github.com/coreos/go-semver` | v0.3.0 | validation | Semantic version parsing for cluster version comparisons |
| `github.com/scylladb/go-set` | v1.0.2 | validation | Set operations for cluster name exclusion filtering |
| `k8s.io/client-go` | v0.28.0-alpha.3 | db-client | Kubernetes API client for readiness checks and promotion metadata |
| `github.com/onsi/ginkgo/v2` | v2.9.4 | testing | BDD-style test framework |
| `github.com/onsi/gomega` | v1.27.6 | testing | Matcher library for Ginkgo tests |
| `github.groupondev.com/conveyor-cloud/go-cluster-libraries` | v0.0.10 | db-client | Internal library for AWS/K8s cluster operations |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
