---
service: "openvpn-config"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "N/A"
environments: []
---

# Deployment

## Overview

OpenVPN Config Automation is not a long-running service and has no container image, orchestrator, or deployment pipeline. It is a collection of Python CLI scripts intended to be executed manually by InfoSec or NetOps operators directly on a workstation or jump host with Python 3 and the `requests` library installed. The `.service.yml` declares `colos: none: {}` and `status_endpoint: disabled: true`, confirming there is no deployed instance to monitor.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | No Dockerfile present in repository |
| Orchestration | None | Not deployed to Kubernetes, ECS, or Lambda |
| Load balancer | None | Not applicable — CLI toolset, not a service |
| CDN | None | Not applicable |

## Environments

> No evidence found in codebase. No environment-specific deployments are configured. The scripts target whichever Cloud Connexa tenant is identified by the `OPENVPN_API` environment variable at runtime.

## CI/CD Pipeline

> No evidence found in codebase. No GitHub Actions workflow, Jenkinsfile, or other CI pipeline configuration exists in the repository. Execution is fully manual.

### Pipeline Stages

> Not applicable — no automated pipeline exists.

## Scaling

> Not applicable. Scripts are short-lived CLI processes; scaling is not a concern.

## Resource Requirements

> Not applicable. Resource requirements depend on the operator's local workstation or jump host. The scripts are lightweight Python processes with minimal CPU and memory needs; the largest overhead is the `backup/access_groups.json` file which can be several hundred MB.

> Deployment configuration managed externally. The Cloud Connexa SaaS platform itself is managed by OpenVPN Inc.; Groupon's connector hosts are provisioned as AWS EC2 instances by the NetOps team outside this repository.
