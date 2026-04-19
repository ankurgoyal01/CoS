---
service: "raas"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Infrastructure / Redis Operations"
platform: "Continuum"
team: "raas-team (raas-team@groupon.com)"
status: active
tech_stack:
  language: "Ruby / Go"
  language_version: "Ruby 2.5.0; Go 1.12"
  framework: "Rails"
  framework_version: "5.1.4"
  runtime: "Puma"
  runtime_version: "3.7+"
  build_tool: "Bundler / Go modules"
  package_manager: "Bundler (Ruby); Go modules (Go)"
---

# RaaS (Redis-as-a-Service) Overview

## Purpose

RaaS is Groupon's internal Redis-as-a-Service platform. It centralizes lifecycle management, operational metadata, health monitoring, and Kubernetes configuration sync for managed Redis clusters running on Redislabs and AWS ElastiCache. The platform exposes a Rails-based metadata API and coordinates a suite of background daemons and tooling across caching, monitoring, config updates, Terraform post-processing, and Ansible-based database administration.

## Scope

### In scope

- Exposing REST endpoints for Redis cluster, database, node, endpoint, and shard inventory
- Collecting and caching telemetry snapshots from the Redislabs Control Plane API
- Running Nagios-style health checks against cached cluster state
- Generating and updating monitoring configurations across monitoring hosts
- Synchronizing cluster metadata into MySQL and PostgreSQL stores
- Updating Kubernetes telegraf deployment config maps when ElastiCache server sets change
- Executing Terraform post-deployment hooks (report generation, alert prerequisite checks)
- Provisioning and cloning Redis databases via Ansible playbooks

### Out of scope

- Redis cluster provisioning at the infrastructure level (managed by Terraform/Redislabs)
- Application-level Redis client configuration (owned by consuming services)
- Business domain logic — RaaS is pure infrastructure operations

## Domain Context

- **Business domain**: Infrastructure / Redis Operations
- **Platform**: Continuum
- **Upstream consumers**: Operators and administrators who view cluster inventory and run provisioning tasks
- **Downstream dependencies**: Redislabs Control Plane API, AWS ElastiCache API, Kubernetes API, Terraform definitions, GitHub Secrets

## Stakeholders

| Role | Description |
|------|-------------|
| Team | raas-team — pablo, raas-team@groupon.com |
| Operator / Administrator | Engineers who use the RaaS Info Service UI and admin tooling to manage Redis clusters |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 2.5.0 | Info Service, Monitoring Service, Checks Runner, Terraform Afterhook |
| Language | Go | 1.12 | K8s Config Updater |
| Language | Python | — | Ansible Admin DB Spec Pruner |
| Framework | Rails | 5.1.4 | Info Service (Rails Controllers/Views, ActiveRecord) |
| Runtime | Puma | 3.7+ | Info Service HTTP server |
| Automation | Ansible | — | Admin playbooks (Create DB, Clone DB) |
| Build tool | Bundler | — | Ruby services |
| Build tool | Go modules | — | Config Updater |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| ActiveRecord | (Rails 5.1.4) | orm | Persistence layer for cluster, node, DB, endpoint, shard entities |
| client-go | — | k8s-client | Kubernetes deploy client for config map and deployment management |
| AWS SDK (Go) | — | cloud-client | ElastiCache cluster discovery |
| Nagios check scripts | — | monitoring | Health check plugin execution in Checks Runner |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
