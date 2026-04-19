---
service: "librechat"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for LibreChat.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Chat Request Flow](chat-request-flow.md) | synchronous | User submits a prompt in the chat UI | End-to-end flow from prompt submission through RAG context retrieval to LLM response |
| [User Authentication Flow](user-authentication-flow.md) | synchronous | User navigates to LibreChat and initiates login | Okta OIDC SSO authentication and session establishment |
| [RAG Context Retrieval Flow](rag-context-retrieval-flow.md) | synchronous | App server requests retrieval context from RAG API | Embedding query, vector similarity search, and context assembly |
| [Conversation Persistence Flow](conversation-persistence-flow.md) | synchronous | Chat turn completes (prompt + response) | Persists conversation messages and metadata to MongoDB |
| [Content Search Flow](content-search-flow.md) | synchronous | User submits a search query in the UI | Full-text search request routed through the API server to Meilisearch |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 5 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The **Chat Request Flow** spans the full LibreChat system: `continuumLibrechatApp` orchestrates calls to both `continuumLibrechatRagApi` and external LiteLLM, with results persisted to `continuumLibrechatMongodb`. This flow is modeled as a Structurizr dynamic view: `dynamic-chat-request-flow`.

See also: [Architecture Context](../architecture-context.md) for container-level relationships.
