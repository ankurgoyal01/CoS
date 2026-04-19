---
service: "n8n"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Internal Automation / Workflow Orchestration"
platform: "Continuum"
team: "Platform Engineering"
status: active
tech_stack:
  language: "JavaScript / Python"
  language_version: ""
  framework: "n8n"
  framework_version: "1.122.3"
  runtime: "Node.js"
  runtime_version: ""
  build_tool: "Docker"
  package_manager: "uv (Python runners)"
---

# n8n Overview

## Purpose

n8n is Groupon's internal workflow automation platform, deployed as a set of domain-scoped instances within the Continuum platform. It enables business, finance, merchant, and LLM-traffic teams to design, schedule, and execute automated workflows through a visual editor without requiring custom application code. The platform runs in queue execution mode, distributing workflow jobs to horizontally scalable worker pods backed by Redis and PostgreSQL.

## Scope

### In scope

- Visual workflow design and execution for internal Groupon teams
- Scheduled and webhook-triggered workflow automation
- Queue-based execution with concurrency control (up to 10 concurrent jobs per queue-worker pod)
- Isolated domain instances: `default`, `finance`, `merchant`, `llm-traffic`, `business`, `playground`
- External task runner execution for JavaScript and Python code nodes
- Credential management for workflow integrations
- Metrics exposure for workflow execution, queue depth, and API activity
- Community package installation for extending workflow nodes

### Out of scope

- Customer-facing APIs (n8n is an internal tool only)
- Custom application business logic (handled by other Continuum services)
- Cross-instance workflow orchestration (each instance is isolated)
- Data warehousing or long-term analytics storage

## Domain Context

- **Business domain**: Internal Automation / Workflow Orchestration
- **Platform**: Continuum
- **Upstream consumers**: Internal teams (Business, Finance, Merchant, LLM-traffic) who design and trigger workflows via the n8n editor UI or webhook endpoints
- **Downstream dependencies**: PostgreSQL (workflow state), Redis / Google Cloud Memorystore (job queue), external webhook endpoints triggered by workflows, loggingStack

## Stakeholders

| Role | Description |
|------|-------------|
| Business Teams | Build and manage automation workflows via the n8n editor |
| Platform Engineering | Operate and maintain the n8n deployment infrastructure |
| Finance Team | Run finance-specific workflow automations on the finance instance |
| Merchant Team | Run merchant-facing automations on the merchant instance |
| LLM-traffic Team | Orchestrate LLM-related automation flows on the llm-traffic instance |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Framework | n8n | 1.122.3 (default/queue-worker), 2.3.5 (business/business-queue-worker), 2.6.4 (staging worker) | `.meta/deployment/cloud/components/common.yml`, component YAMLs |
| Task Runners | n8nio/runners | 2.6.4 | `Dockerfile.runners` |
| Language (runners) | Python | 3.x (via venv) | `Dockerfile.runners`, `extras.txt` |
| Database | PostgreSQL | 16 | `continuumN8nPostgres.dsl` |
| Queue | Redis / GCP Memorystore | — | `production-us-central1.yml` env vars |
| Container image | n8nio/n8n | Pull-through cache | `.meta/deployment/cloud/components/common.yml` |
| Orchestration | Kubernetes (GKE) | — | `.deploy_bot.yml`, kustomize overlays |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| psycopg | binary,pool variant | db-client | PostgreSQL connectivity from Python code nodes |
| Bull (Redis queue) | — | message-client | Job queue backing for queue execution mode |
| libpq | 5.18 (shared lib) | db-client | PostgreSQL C client library for Python runner |
| uv | — | package-manager | Python package installation in runner image |
| node (JavaScript runner) | — | runtime | Executes JavaScript code nodes in sandboxed environment |
| KEDA | — | scheduling | Kubernetes-based event-driven autoscaling for queue workers |
