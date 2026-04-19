---
service: "librechat"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Internal AI tooling / Developer productivity"
platform: "Continuum"
team: "Platform Engineering"
status: active
tech_stack:
  language: "JavaScript / Python"
  language_version: "Node.js 20 / Python 3"
  framework: "Express + FastAPI"
  framework_version: "Express (Node.js 20) / FastAPI"
  runtime: "Node.js 20 Alpine"
  runtime_version: "20-alpine"
  build_tool: "npm + Helm 3"
  package_manager: "npm"
---

# LibreChat Overview

## Purpose

LibreChat is Groupon's internal deployment of the LibreChat open-source AI chat platform (v0.7.4/v0.7.8). It gives Groupon employees a single web interface to interact with multiple large language model providers — including OpenAI GPT models, Anthropic Claude, Perplexity, and xAI Grok — routed through a central LiteLLM proxy. The platform extends standard chat with retrieval-augmented generation (RAG) so users can ground prompts in indexed internal knowledge, and persists all conversations and user profiles for continuity across sessions.

## Scope

### In scope
- Browser-based chat interface for authenticated Groupon employees
- Multi-model LLM access via LiteLLM proxy (GPT-4, Claude, o-series, Perplexity, Grok)
- Retrieval-augmented generation (RAG) context injection for user prompts
- Full-text search over indexed content via Meilisearch
- Persistent conversation and user data storage in MongoDB
- Vector embedding storage and semantic similarity search via pgvector
- SSO authentication through Okta (OpenID Connect)
- Plugin model support for GPT-family models

### Out of scope
- LLM model hosting (delegated to LiteLLM proxy and external providers)
- Customer-facing commerce features (handled by core Continuum platform)
- General-purpose API gateway (LiteLLM handles model routing)

## Domain Context

- **Business domain**: Internal AI tooling / Developer productivity
- **Platform**: Continuum
- **Upstream consumers**: Groupon employees (Consumer persona) accessing via browser over HTTPS
- **Downstream dependencies**: LiteLLM proxy (model routing), Okta (SSO/OIDC), MongoDB (persistence), Meilisearch (full-text search), pgvector/VectorDB (semantic search), OpenAI embeddings API

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Engineering | Owns deployment, configuration, and infrastructure for LibreChat |
| Groupon Employees | End users of the chat interface |
| AI/ML Teams | Consumers of the RAG and multi-model capabilities |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (app) | JavaScript (Node.js) | 20-alpine | `Dockerfile` |
| Language (RAG API) | Python | 3.x | `.meta/deployment/cloud/components/rag-api/common.yml` |
| Framework (app) | Node.js/Express | bundled with LibreChat v0.7.8 | `Dockerfile` CMD `npm run backend` |
| Framework (RAG API) | FastAPI | bundled with RAG API v0.5.0 | architecture DSL (`librechat-rag-api.dsl`) |
| UI framework | React | bundled | `Dockerfile` `npm run frontend` |
| Runtime | Node.js | 20 Alpine | `Dockerfile` `FROM node:20-alpine` |
| Build tool | npm | bundled | `Dockerfile` |
| Deployment packaging | Helm 3 | cmf-generic-api v3.91.3-SNAPSHOT | `.meta/deployment/cloud/scripts/deploy.sh` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| React | bundled | ui-framework | Browser-facing chat UI |
| Express | bundled | http-framework | Backend HTTP API server |
| FastAPI | bundled | http-framework | RAG API HTTP handler (Python) |
| pgvector client | bundled | db-client | Vector similarity search queries against PostgreSQL+pgvector |
| MongoDB driver | bundled | db-client | Reads/writes conversation and user documents |
| Meilisearch client | bundled | db-client | Full-text search queries |
| OpenID Connect (OIDC) | bundled | auth | Okta SSO integration |
| LiteLLM SDK/proxy | via HTTP | message-client | Routes prompts to upstream LLM providers |
