---
service: "librechat"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "continuumLibrechatMongodb"
    type: "mongodb"
    purpose: "Persistent storage for user profiles, conversations, and application metadata"
  - id: "continuumLibrechatVectordb"
    type: "postgresql+pgvector"
    purpose: "Vector embedding storage for semantic similarity search (RAG)"
  - id: "continuumLibrechatMeilisearch"
    type: "meilisearch"
    purpose: "Full-text search index for chat content retrieval"
---

# Data Stores

## Overview

LibreChat owns three distinct data stores, each serving a specialized purpose: MongoDB for primary document persistence (conversations and users), a PostgreSQL+pgvector database for semantic embedding storage (RAG pipeline), and Meilisearch for full-text search. All three are deployed as dedicated containers in the same Kubernetes namespace as the application.

## Stores

### MongoDB (`continuumLibrechatMongodb`)

| Property | Value |
|----------|-------|
| Type | mongodb |
| Architecture ref | `continuumLibrechatMongodb` |
| Purpose | Document storage for user profiles, conversation threads, messages, and metadata |
| Ownership | owned |
| Image | `docker-conveyor.groupondev.com/bitnami/mongodb` (v8.0.3-debian-12-r0) |
| Persistent volume | 100G at `/bitnami/mongodb` |
| Connection | `mongodb://librechat--mongodb.<env>.service:80/LibreChat` (via `MONGO_URI` env var) |

#### Key Entities

| Entity / Collection | Purpose | Key Fields |
|---------------------|---------|-----------|
| `Conversation Store` | Persists conversation threads and individual messages | conversation ID, user ID, messages array, model, timestamps |
| `User Store` | Persists user profiles, roles, and account metadata | user ID, email, role, preferences |

#### Access Patterns

- **Read**: API server queries conversation history by user ID; fetches user profile on session creation
- **Write**: API server appends new messages to conversation documents; creates/updates user records on SSO login
- **Indexes**: Replica set `rs0` configured via `MONGODB_REPLICA_SET_NAME` and `--replSet=rs0` for high availability

---

### VectorDB (`continuumLibrechatVectordb`)

| Property | Value |
|----------|-------|
| Type | postgresql+pgvector |
| Architecture ref | `continuumLibrechatVectordb` |
| Purpose | Stores vector embeddings and executes semantic nearest-neighbor similarity search for the RAG pipeline |
| Ownership | owned |
| Image | `docker-conveyor.groupondev.com/ankane/pgvector` (v0.5.1) |
| Persistent volume | 50G at `/var/lib/postgresql/` |
| Connection | `DB_HOST: librechat--vectordb.<env>.service`, port 80/5432, via PostgreSQL protocol |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `Embeddings Index` (`vectorEmbeddingsIndex`) | Stores document vector embeddings for semantic search | embedding vector, source document ID, content chunk |

#### Access Patterns

- **Read**: RAG API Vector DB Client executes nearest-neighbor similarity searches against the embeddings index using the PostgreSQL pgvector extension
- **Write**: Embeddings are ingested when documents are indexed for RAG (mechanism managed by RAG API)
- **Indexes**: pgvector index on the embedding column for approximate nearest-neighbor (ANN) search

---

### Meilisearch (`continuumLibrechatMeilisearch`)

| Property | Value |
|----------|-------|
| Type | meilisearch |
| Architecture ref | `continuumLibrechatMeilisearch` |
| Purpose | Full-text search engine enabling keyword-based retrieval of indexed chat content |
| Ownership | owned |
| Image | `docker-conveyor.groupondev.com/getmeili/meilisearch` (v1.7.3) |
| Persistent volumes | 100G at `/meili_data/`, 10G at `/tmp/` |
| Connection | `MEILI_HOST: http://librechat--meilisearch.<env>.service` (via env var) |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Search Indexes | Indexed content documents for full-text retrieval | document ID, content text, searchable fields |

#### Access Patterns

- **Read**: API server queries Meilisearch Query Engine for full-text search results
- **Write**: Meilisearch Index Engine maintains and updates search indexes as content is added
- **Indexes**: Managed internally by Meilisearch; index structures are referenced by the Query Engine component

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| LibreChat App cache | in-memory | Response caching as configured by `cache: true` in `librechat.yaml` | Not specified |

> Cache behavior is controlled by the `cache: true` setting in the mounted `librechat.yaml` config file. No dedicated Redis or Memcached cache layer is deployed.

## Data Flows

- The API Server writes conversation data to MongoDB on every chat turn.
- When the API Server invokes the RAG API, the RAG API coordinates a vector similarity search in VectorDB and returns enriched context to the API Server.
- Meilisearch is populated by the index engine and queried by the API Server for user-initiated content search. No CDC or ETL pipeline is present; indexing is managed by the Meilisearch container directly.
