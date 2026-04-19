---
service: "librechat"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLibrechatApp, continuumLibrechatMongodb, continuumLibrechatMeilisearch, continuumLibrechatRagApi, continuumLibrechatVectordb]
---

# Architecture Context

## System Context

LibreChat sits within the `continuumSystem` (Continuum Platform — Groupon's core commerce engine) as an internal AI chat service. The `consumer` persona (a Groupon employee) accesses LibreChat via HTTPS through the browser-based UI. LibreChat does not interact directly with customer-facing commerce services; it depends on an external LiteLLM proxy for model routing, Okta for authentication, and owns four companion infrastructure containers (MongoDB, Meilisearch, RAG API, VectorDB) within the same deployment namespace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| LibreChat App | `continuumLibrechatApp` | WebApp + API | Node.js | 20-alpine / app v0.7.8 | Primary web application and backend API process; serves the React UI and handles chat orchestration |
| MongoDB | `continuumLibrechatMongodb` | Database | MongoDB (Bitnami) | 8.0.3-debian-12-r0 | Document database for users, conversations, and metadata |
| Meilisearch | `continuumLibrechatMeilisearch` | Search Engine | Meilisearch | v1.7.3 | Full-text search engine for indexing and retrieval |
| RAG API | `continuumLibrechatRagApi` | Backend Service | Python / FastAPI | v0.5.0 | Retrieval-augmented generation service for context assembly |
| VectorDB | `continuumLibrechatVectordb` | Database | PostgreSQL + pgvector | v0.5.1 | Vector database for embeddings and semantic similarity search |

## Components by Container

### LibreChat App (`continuumLibrechatApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web UI (`appWebUi`) | Browser-facing interface for chat, authentication, and settings | React |
| API Server (`appApiServer`) | Handles chat requests, auth orchestration, MongoDB reads/writes, Meilisearch queries, and RAG API calls | Node.js/Express |
| Runtime Configuration (`appConfig`) | Loads environment variables and `librechat.yaml` mounted config | YAML / .env |

### MongoDB (`continuumLibrechatMongodb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Conversation Store (`mongoConversationStore`) | Persists conversation threads and individual messages | MongoDB Collection |
| User Store (`mongoUserStore`) | Persists user profiles, roles, and metadata | MongoDB Collection |

### Meilisearch (`continuumLibrechatMeilisearch`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Index Engine (`meiliIndexer`) | Maintains and updates searchable indexes | Meilisearch Core |
| Query Engine (`meiliQuery`) | Executes full-text queries against indexes | Meilisearch Query API |

### RAG API (`continuumLibrechatRagApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RAG API Handler (`ragApi`) | Receives retrieval requests from the app service via HTTP/JSON | FastAPI |
| Retriever (`ragRetriever`) | Builds retrieval plans and prepares query context | Python Service |
| Vector DB Client (`ragVectorClient`) | Executes nearest-neighbor vector lookups against VectorDB | PostgreSQL Client |

### VectorDB (`continuumLibrechatVectordb`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| PGVector Engine (`vectorPgEngine`) | Stores vectors and executes similarity operations | PostgreSQL + pgvector |
| Embeddings Index (`vectorEmbeddingsIndex`) | Vector index structures used for semantic retrieval | pgvector Index |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `consumer` | `continuumLibrechatApp` | Uses chat and account features | HTTPS |
| `continuumLibrechatApp` (`appWebUi`) | `continuumLibrechatApp` (`appApiServer`) | Sends chat input and user actions | HTTPS/JSON |
| `continuumLibrechatApp` (`appApiServer`) | `continuumLibrechatMeilisearch` (`meiliQuery`) | Queries indexed searchable content | HTTP |
| `continuumLibrechatApp` (`appApiServer`) | `continuumLibrechatMongodb` (`mongoConversationStore`) | Reads and writes conversations | MongoDB protocol |
| `continuumLibrechatApp` (`appApiServer`) | `continuumLibrechatMongodb` (`mongoUserStore`) | Reads and writes user metadata | MongoDB protocol |
| `continuumLibrechatApp` (`appApiServer`) | `continuumLibrechatRagApi` (`ragApi`) | Requests retrieval context for prompts | HTTP/JSON |
| `continuumLibrechatRagApi` (`ragApi`) | `continuumLibrechatRagApi` (`ragRetriever`) | Coordinates retrieval pipeline | In-process |
| `continuumLibrechatRagApi` (`ragRetriever`) | `continuumLibrechatRagApi` (`ragVectorClient`) | Executes vector lookups | In-process |
| `continuumLibrechatRagApi` (`ragVectorClient`) | `continuumLibrechatVectordb` (`vectorEmbeddingsIndex`) | Performs semantic similarity search | PostgreSQL protocol |
| `continuumLibrechatMeilisearch` (`meiliQuery`) | `continuumLibrechatMeilisearch` (`meiliIndexer`) | Uses current index structures for query execution | In-process |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumLibrechat`
- Component (App): `components-continuum-librechat-app`
- Component (RAG API): `components-continuum-librechat-rag-ragApi`
- Dynamic (Chat Request Flow): `dynamic-chat-request-flow`
