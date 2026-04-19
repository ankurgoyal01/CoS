---
service: "liteLLM"
title: Overview
generated: "2026-03-03"
type: overview
domain: "AI / LLM Infrastructure"
platform: "Continuum"
team: "Conveyor Cloud"
status: active
tech_stack:
  language: "Python"
  language_version: "3.13"
  framework: "LiteLLM"
  framework_version: "v1.80.8-stable"
  runtime: "Python"
  runtime_version: "3.13"
  build_tool: "Docker / GitHub Actions"
  package_manager: "pip (upstream image)"
---

# LiteLLM Overview

## Purpose

LiteLLM is Groupon's centralized LLM gateway, deployed within the Continuum platform. It exposes an OpenAI-compatible HTTP API that routes AI model requests to upstream LLM providers (such as Anthropic, OpenAI, and others), normalizes responses, applies Redis-based caching, tracks costs, and emits observability signals via Prometheus, Langfuse, and a structured logging stack. The service exists to give internal teams a single, governed access point for AI/LLM capabilities without each consumer needing to manage provider credentials and routing logic independently.

## Scope

### In scope

- Accepting OpenAI-compatible inference requests (`/chat/completions`, `/completions`, etc.) from internal consumers
- Routing requests to configured upstream LLM provider APIs
- Applying Redis response caching with configurable TTL (default 300 seconds)
- Provider-level prompt caching (Anthropic `cache_control` injection)
- Tracking per-model and per-end-user cost and token usage via Prometheus budget metrics
- Emitting structured application logs (JSON) and runtime metrics
- Exporting request traces for latency diagnostics
- Publishing callback events to Langfuse for prompt/response observability
- Sending SMTP email notifications via the callbacks system
- Storing model configuration in PostgreSQL when `STORE_MODEL_IN_DB` is enabled
- Exposing an admin UI and API on port 8081

### Out of scope

- Training or fine-tuning LLM models
- Storing or managing user conversation history beyond the request/response cycle
- Serving as a data warehouse or analytics platform for LLM usage
- Managing upstream LLM provider accounts or billing directly

## Domain Context

- **Business domain**: AI / LLM Infrastructure
- **Platform**: Continuum (Groupon's core commerce engine platform)
- **Upstream consumers**: Internal Groupon services and teams consuming AI capabilities
- **Downstream dependencies**: Upstream LLM provider APIs (HTTPS), PostgreSQL (model config), Redis/Memorystore (response cache), Langfuse (prompt observability), SMTP (email notifications), Prometheus metrics stack, structured logging stack, distributed tracing stack

## Stakeholders

| Role | Description |
|------|-------------|
| Conveyor Cloud Team | Owners and operators of the LiteLLM deployment |
| Internal AI consumers | Engineering teams using LiteLLM as their AI gateway |
| Platform / SRE | Responsible for Kubernetes infrastructure, scaling, and incident response |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.13 | `.meta/deployment/cloud/components/litellm/common.yml` — command: `/usr/bin/python3.13` |
| Framework | LiteLLM | v1.80.8-stable | `common.yml` — `appVersion: v1.80.8-stable` |
| Runtime | Python | 3.13 | `common.yml` — mainContainerCommand |
| Build tool | Docker + GitHub Actions | — | `.github/workflows/litellm_build_image.yaml` |
| Package manager | pip (managed via upstream image) | — | Upstream image: `litellm/litellm` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| LiteLLM | v1.80.8-stable | http-framework | Core LLM proxy/router — OpenAI-compatible API surface and provider integrations |
| Prometheus | (bundled in LiteLLM) | metrics | Runtime metrics, budget tracking, cost per model/user |
| Langfuse | (bundled callback) | logging | Prompt/response observability and tracing |
| Redis (redis-py) | (bundled) | db-client | Response caching client; configured via `REDIS_*` env vars |
| PostgreSQL client | (bundled) | db-client | Persisting model configuration when `STORE_MODEL_IN_DB=true` |
| SMTP callback | (bundled) | messaging | Email notifications via LiteLLM callback system |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
