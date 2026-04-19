---
service: "aws-external"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "N/A"
environments: ["production", "staging"]
---

# Deployment

## Overview

`aws-external` has no deployable application component. It is a placeholder service metadata repository; there is nothing to build, containerize, or deploy. Infrastructure changes affecting AWS accounts are managed by individual infrastructure projects (such as CloudCore and Conveyor) and must follow Groupon's Change Policy using infrastructure-as-code (e.g., Terraform) rather than direct AWS console changes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile present; no application is deployed |
| Orchestration | None | No Kubernetes manifests or ECS task definitions |
| Load balancer | None | No HTTP service to front |
| CDN | None | No static assets served |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Production | Live AWS accounts hosting Groupon workloads | us-west-1, us-west-2, eu-west-1 (primary); us-east-1, eu-west-2, ap-southeast-1 (niche/legacy) | N/A |
| Staging | Pre-production AWS accounts | Mirrors production regions | N/A |

## CI/CD Pipeline

> No evidence found in codebase. This repository has no build or deployment pipeline because there is no deployable artifact.

### Pipeline Stages

> Not applicable.

## Scaling

> Not applicable. There is no runtime service to scale.

Changes to AWS service quotas are made via the [AWS Service Quotas console](https://console.aws.amazon.com/servicequotas/home). When increasing capacity during an incident, quotas should be raised by 50–100%. See [Runbook](runbook.md) for the full procedure.

## Resource Requirements

> Not applicable. There is no runtime service with resource requirements.

> Deployment configuration managed externally. All AWS infrastructure is provisioned by individual infrastructure projects (CloudCore, Conveyor, etc.) following the [Groupon Change Policy](https://groupondev.atlassian.net/wiki/spaces/PRODOPS/pages/55016466723/Change+Policy).
