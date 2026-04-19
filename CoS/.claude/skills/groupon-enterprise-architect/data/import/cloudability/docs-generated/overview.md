---
service: "cloudability"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Cost Management"
platform: "Continuum"
team: "CloudSRE"
status: active
tech_stack:
  language: "Bash"
  language_version: ""
  framework: "kubectl / curl / jq"
  framework_version: ""
  runtime: "Docker"
  runtime_version: ""
  build_tool: "deploybot"
  package_manager: ""
---

# Cloudability Overview

## Purpose

Cloudability is Groupon's cloud cost visibility integration. It installs and manages the Apptio Cloudability Metrics Agent across all Conveyor Kubernetes clusters so that per-cluster, per-namespace, and per-workload resource usage data is continuously exported to the Cloudability SaaS platform. The service consists of provisioning CLI scripts that register clusters, generate hardened Kubernetes manifests, and deploy the third-party agent — enabling cloud cost tracking and chargeback reporting for all engineering teams.

## Scope

### In scope

- Registering Conveyor Kubernetes clusters with the Cloudability provisioning API
- Fetching generated Kubernetes agent manifests from the Cloudability API
- Patching manifests to conform to Groupon OPA policies (namespace, RBAC, image pinning, resource limits)
- Deploying and maintaining the Cloudability Metrics Agent on each cluster via kubectl and deploybot
- Providing access to cloud cost data through the Cloudability SaaS portal

### Out of scope

- Authoring or maintaining the Cloudability Metrics Agent container image (third-party, mirrored to `docker.groupondev.com/cloudability/metrics-agent:2.4`)
- Cloud cost allocation policy configuration (managed in the Cloudability portal)
- Access control provisioning for cost data viewers (managed via ARQ/Launchpad)
- RBAC ClusterRole provisioning (managed by the Conveyor `aaa` playbook as `generic-metrics-agent-clusterrole`)

## Domain Context

- **Business domain**: Cloud Cost Management
- **Platform**: Continuum (Cloud SRE)
- **Upstream consumers**: Cloud SRE team members who access cost data via `https://app.cloudability.com/#/containers`
- **Downstream dependencies**: Cloudability Provisioning API (`https://api.cloudability.com/v3/containers/provisioning`), Cloudability Ingestion API, Kubernetes API server on each Conveyor cluster

## Stakeholders

| Role | Description |
|------|-------------|
| Cloud SRE | Owns provisioning, deployment, and ongoing maintenance of the agent |
| Engineering Teams | Consumers of cloud cost data exposed in the Cloudability portal |
| Cloudability TAM (IBM) | Vendor technical account manager: Basappa Sagar K S |
| Cloudability Account Rep (IBM) | Wil Edgar — vendor commercial contact |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Bash | - | `get_agent_config.sh`, `get_raw_config.sh` |
| CLI tooling | curl | - | `get_agent_config.sh` |
| CLI tooling | jq | - | `get_agent_config.sh` |
| Orchestration | kubectl | - | `get_agent_config.sh`, `.deploy_bot.yml` |
| Build/Deploy tool | deploybot | v2 | `.deploy_bot.yml` |
| Container image | cloudability/metrics-agent | 2.4 | `get_agent_config.sh` patch section |
| Deploy image | rapt/deploy_kubernetes | v2.3.0-3.3.0-1.1.4-1.16.4 | `.deploy_bot.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| curl | - | http-client | Calls Cloudability provisioning and config APIs |
| jq | - | serialization | Parses JSON responses to extract cluster ID |
| kubectl | - | orchestration | Applies Kubernetes manifests to target clusters |
| patch (GNU patch) | - | tooling | Applies manifest patches for Groupon-specific hardening |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
