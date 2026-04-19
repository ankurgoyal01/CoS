---
service: "lavatoryRunner"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Platform Infrastructure / Artifactory"
platform: "Continuum"
team: "rapt"
status: active
tech_stack:
  language: "Python"
  language_version: "3"
  framework: "Lavatory"
  framework_version: "2019.05.08-19.55.38-387658e (base image)"
  runtime: "Docker"
  runtime_version: "N/A"
  build_tool: "Make"
  package_manager: "pip (via Lavatory base image)"
---

# Lavatory Runner Overview

## Purpose

Lavatory Runner is a scheduled Docker-based cleanup service that enforces artifact retention policies against Groupon's internal Artifactory registries. It prevents unbounded repository growth by querying Artifactory using AQL (Artifactory Query Language) and deleting stale or excess Docker image tags that exceed defined age or count thresholds. The service runs as a cron-triggered container on designated `artifactory-utility` hosts across all production colos and environments.

## Scope

### In scope

- Defining and loading per-repository retention policies as Python modules under `/opt/lavatory/policies`
- Querying Artifactory repositories via AQL to identify stale artifacts
- Applying multi-colo download-date awareness to prevent deletion of recently accessed images
- Deleting artifacts that meet purge criteria (age, count, whitelist)
- Writing per-repository cleanup logs for Splunk ingestion
- Enforcing policies on schedule via host-level cron jobs (set up by Ansible)

### Out of scope

- Hosting or operating Artifactory itself (managed separately via `artifactory/artifactory_cloud` Terraform)
- Ansible deployment of cron jobs to hosts (triggered manually, not part of this repo's CI)
- Generic (non-Docker) artifact repository cleanup beyond the `X-artifacts_generic.py` GDPR one-time policy (which is deliberately disabled)
- Retention policy for repositories not listed under `policies/`

## Domain Context

- **Business domain**: Platform Infrastructure — Artifactory artifact lifecycle management
- **Platform**: Continuum
- **Upstream consumers**: Cron scheduler running on `artifactory-utility` hosts in uat, staging, and prod environments (sac1, snc1, dub1, us-west-2)
- **Downstream dependencies**: Groupon internal Artifactory instance (`artifactory` / `docker.groupondev.com`), Splunk log aggregation, Wavefront metrics

## Stakeholders

| Role | Description |
|------|-------------|
| Platform / rapt team | Owners; define and maintain retention policies and deploy Ansible playbooks |
| Artifactory administrators | Manage the Artifactory instances and user credentials (lavatory user) |
| All CI/CD consumers | Indirect beneficiaries — stale images are removed, keeping Artifactory healthy |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3 | `policies/policy.py`, `policies/docker_conveyor.py` |
| Framework | Lavatory (gogoair fork) | 2019.05.08-19.55.38-387658e | `Dockerfile` FROM line |
| Runtime | Docker | N/A | `Dockerfile`, `Makefile` |
| Build tool | Make | N/A | `Makefile` |
| Package manager | pip (via Lavatory base image) | N/A | `Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| lavatory | 2019.05.08-387658e | scheduling | Core runner: wraps Artifactory AQL queries, purge execution, and dry-run mode |
| abc (stdlib) | stdlib | validation | Abstract base class enforcement for `Policy` interface |
| datetime (stdlib) | stdlib | scheduling | Computes age thresholds for retention policy comparisons |
| logging (stdlib) | stdlib | logging | Emits structured logs captured by Splunk (`sourcetype=lavatory`) |
| importlib (stdlib) | stdlib | scheduling | Dynamic loading of per-repository policy modules at runtime |
| os / sys (stdlib) | stdlib | scheduling | Reads `TARGET_COLOS` env var; manages module import paths |
| default-jdk (Debian) | N/A | testing | Required by Artifactory Pro test container (`test/Dockerfile`) |
| jq | N/A | testing | Used in integration test shell script to parse Artifactory storage API responses |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
