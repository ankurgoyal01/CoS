---
service: "librechat"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 4
---

# Integrations

## Overview

LibreChat has three key external dependencies: the LiteLLM proxy (model routing to LLM providers), Okta (employee SSO/OIDC), and OpenAI (embedding generation for the RAG pipeline). Internally it coordinates with four co-deployed containers — MongoDB, Meilisearch, RAG API, and VectorDB — all within the same Kubernetes namespace. Upstream consumers are Groupon employees accessing the web UI.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| LiteLLM proxy | rest | Routes chat prompts to configured LLM providers (OpenAI, Anthropic, Perplexity, xAI) | yes | Not modeled separately in DSL |
| Okta (OpenID Connect) | oidc | Employee SSO authentication and identity | yes | Not modeled separately in DSL |
| OpenAI Embeddings API | rest | Generates vector embeddings for RAG document indexing | yes | Not modeled separately in DSL |

### LiteLLM Proxy Detail

- **Protocol**: REST/HTTP
- **Base URL (staging)**: `http://litellm.staging.service`
- **Base URL (production)**: `http://litellm.production.service`
- **Auth**: `apiKey: "user_provided"` — users supply their own API key in the LibreChat UI
- **Purpose**: Central model gateway that proxies requests to GPT-4.1, Claude 4, o-series, Perplexity Sonar, xAI Grok, and other models configured in `librechat.yaml`
- **Configured models (production)**: `gpt-4.1-mini`, `gpt-4.1-nano`, `gpt-4`, `o1`, `o1-mini`, `o3-deep-research`, `o3`, `o3-mini`, `o4-mini`, `gpt-4-turbo-preview`, `claude-4-opus-20250514`, `claude-4-sonnet-20250514`, `claude-3-5-haiku-latest`, `perplexity/sonar`, `perplexity/sonar-pro`, `perplexity/sonar-reasoning`, `perplexity/sonar-deep-research`, `perplexity/sonar-reasoning-pro`, `xai/grok-3`, `xai/grok-4-latest`, `xai/grok-3-mini`
- **Failure mode**: Prompts cannot be sent to LLM providers; chat feature is unavailable
- **Circuit breaker**: No evidence found in codebase

### Okta (OpenID Connect) Detail

- **Protocol**: OIDC
- **Issuer**: `https://groupon.okta.com/oauth2/default`
- **Auth**: OpenID Connect flow with callback at `/oauth/openid/callback`
- **Scope**: `openid email profile`
- **Purpose**: Authenticates all Groupon employees accessing the LibreChat web UI; controls user registration via social login
- **Failure mode**: Users cannot authenticate; all protected endpoints are inaccessible
- **Circuit breaker**: No evidence found in codebase

### OpenAI Embeddings API Detail

- **Protocol**: REST
- **Auth**: API key managed via secrets (`.meta/deployment/cloud/secrets/`)
- **Purpose**: The RAG API uses OpenAI's embedding service (`EMBEDDINGS_PROVIDER: openai`) to generate vector representations of documents for indexing in VectorDB
- **Failure mode**: New document embeddings cannot be generated; existing indexed content remains searchable but new RAG ingestion stalls
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MongoDB | MongoDB protocol | Stores and retrieves conversations and user data | `continuumLibrechatMongodb` |
| Meilisearch | HTTP | Full-text content search | `continuumLibrechatMeilisearch` |
| RAG API | HTTP/JSON | Retrieval-augmented context assembly for prompts | `continuumLibrechatRagApi` |
| VectorDB (pgvector) | PostgreSQL protocol | Semantic similarity search for the RAG pipeline | `continuumLibrechatVectordb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon employees (Consumer persona) | HTTPS | Access the chat interface, manage conversations, perform content search |

> Upstream consumers are tracked in the central architecture model. The `consumer` persona is defined in `continuumSystem` (`workspace.dsl`).

## Dependency Health

- **MongoDB**: Readiness checked via `readiness-probe.sh` (mongosh `db.hello().isWritablePrimary || db.hello().secondary`) every 10s; liveness via `ping-mongodb.sh` every 10s
- **Meilisearch**: Readiness and liveness checked via HTTP GET `/health` on port 7700, every 10s
- **RAG API**: Readiness and liveness checked via HTTP GET `/health` on port 8000, every 10s
- **VectorDB**: Readiness and liveness checked via `pg_isready -U myuser` exec probe every 10s
- **App (LibreChat)**: Readiness and liveness checked via HTTP GET `/health` on port 3080, every 10s
- No circuit breaker patterns are explicitly configured in the deployment manifests.
