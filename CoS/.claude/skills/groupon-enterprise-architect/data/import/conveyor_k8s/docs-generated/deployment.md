---
service: "conveyor_k8s"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [sandbox, dev, stable, production]
---

# Deployment

## Overview

Conveyor K8s itself is not a running service deployed to a cluster — it is a cluster lifecycle automation platform. Its artifacts are CI pipeline definitions, IaC modules, Ansible playbooks, and Go utility binaries packaged in Docker images. The `conveyor-pipeline-utils` binaries are built into a Docker image (`docker-conveyor.groupondev.com/conveyor-cloud/conveyor-pipeline-utils`) and published to Groupon's internal Docker registry. Ansible playbooks are executed inside a Python container (`docker-conveyor.groupondev.com/conveyor-cloud/conveyor_cloud_python:0.1.42`) in GitHub Actions runners. Jenkins pipelines run on `multitenant` nodes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (pipeline utils) | Docker (Alpine 3.18 + Go 1.24 + Packer 1.6.5) | `conveyor-pipeline-utils/Dockerfile` — multi-stage build producing Go binaries |
| Container (Ansible) | Docker (conveyor_cloud_python:0.1.42) | `docker-conveyor.groupondev.com/conveyor-cloud/conveyor_cloud_python:0.1.42` — used in all GitHub Actions Ansible workflows |
| Orchestration | GitHub Actions + Jenkins | GitHub Actions: `.github/workflows/`; Jenkins: `Jenkinsfile`, `pipelines/` |
| CI runners | GitHub self-hosted runners | `groupon-runner-sets-s` runner set |
| IaC state backend (EKS) | AWS S3 | Remote state per module, `us-west-2` default region |
| IaC state backend (GKE) | GCP GCS | Remote state per module, prefix-keyed |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| sandbox | Development cluster testing, PR validation | AWS us-central1, us-west | Not public |
| dev | Continuous integration target; receives changes on PR and master merge | GCP us-central1, europe-west1 | Not public |
| stable | Pre-production validation; deployed on version tag | GCP us-central1, europe-west1 | Not public |
| production | Live traffic clusters; deployed on version tag with manual approval | GCP us-central1 (EU placeholder TBD) | Not public |

Known GKE cluster name examples (from Jenkinsfile):

| Environment | Region | Cluster Name |
|-------------|--------|-------------|
| dev | us-central1 | `conveyor-gcp-dev-pr1` |
| dev | europe-west1 | `conveyor-gcp-dev-pr7` |
| stable | us-central1 | `conveyor-gcp-stable14` |
| stable | europe-west1 | `conveyor-gcp-stable23` |
| production | us-central1 | `conveyor-gcp-production2` |

## CI/CD Pipeline

- **Tool**: Jenkins (primary cluster lifecycle) + GitHub Actions (GitOps Ansible deployments)
- **Config**: `Jenkinsfile` (main build), `pipelines/*.groovy` (lifecycle jobs), `.github/workflows/*.yml` (Ansible deployments)
- **Trigger**: On push/PR, manual dispatch, SemVer tag push, scheduled sandbox cleanup

### Pipeline Stages — Main Build (Jenkinsfile)

1. **PR Title Linter**: Runs Danger.js in Docker to validate PR title convention
2. **Checkout**: Checks out repository with full history and tags
3. **Plan Terraform changes** (PR, if terra-gke changed): Runs `runTerraformPipeline('plan', ...)` on dev CI clusters in parallel
4. **Apply Ansible roles** (PR, if playbook changed): Detects changed roles/playbooks, runs `runAnsiblePipeline(role, branch, devClusters)` in parallel
5. **Create next SemVer tag** (master merge): Calls `generateNextSemVerTag()`
6. **Apply Terraform from master** (master merge, if terra-gke changed): Applies Terraform changes to all dev clusters
7. **Apply Ansible from master** (master merge, if roles changed): Applies Ansible role changes to dev clusters
8. **Generate Release Tag** (if `GENERATE_RELEASE=true`): Triggers `changelog-release-tooling` Jenkins job

### Pipeline Stages — GitHub Actions Ansible Deployment (Dev)

1. **Checkout**: Fetch full history and tags (`actions/checkout@v4`)
2. **Authenticate to GCP**: GCP Service Account auth via shared action
3. **Detect Changed Playbooks**: Diffs PR branch vs base; detects changed `install_*.yml` playbooks and roles
4. **Run Playbooks**: Executes `ansible-playbook` for each detected playbook against US and EU dev clusters in parallel jobs
5. **Rollback Playbooks**: Checks out master and re-runs playbooks to restore dev cluster state
6. **Publish Job Summary**: Writes deployment summary to GitHub Actions job summary

### Pipeline Stages — GitHub Actions Ansible Deployment (Stable / Production)

1. **Checkout**: Fetch full history and tags
2. **Authenticate to GCP**: GCP Service Account auth
3. **Detect Changed Playbooks**: Diffs current tag vs previous tag
4. **Run Playbooks**: Executes playbooks against stable/production cluster (production requires manual approval gate)
5. **Publish Job Summary**: Writes deployment outcome

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable — pipeline tooling | N/A |
| Parallelism | GitHub Actions parallel jobs (US + EU) | Per-workflow job matrix |
| Jenkins parallelism | `parallel()` in Groovy DSL for multi-cluster and multi-region operations | Defined per pipeline |

## Resource Requirements

> Deployment configuration managed externally. The GitHub Actions runner `groupon-runner-sets-s` defines actual CPU and memory limits. The `conveyor_cloud_python:0.1.42` container resource limits are set by the runner set configuration outside this repository.
