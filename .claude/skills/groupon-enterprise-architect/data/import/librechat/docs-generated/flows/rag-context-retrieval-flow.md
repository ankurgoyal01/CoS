---
service: "librechat"
title: "RAG Context Retrieval Flow"
generated: "2026-03-03"
type: flow
flow_name: "rag-context-retrieval-flow"
flow_type: synchronous
trigger: "API Server requests retrieval-augmented context for a user prompt"
participants:
  - "continuumLibrechatApp"
  - "continuumLibrechatRagApi"
  - "continuumLibrechatVectordb"
architecture_ref: "dynamic-chat-request-flow"
---

# RAG Context Retrieval Flow

## Summary

The RAG Context Retrieval Flow is a sub-flow of the Chat Request Flow. When the LibreChat API Server receives a prompt, it calls the RAG API to assemble relevant document context before forwarding the prompt to the LLM. The RAG API orchestrates an internal pipeline: the Retriever builds a retrieval plan, the Vector DB Client executes a nearest-neighbor search in the pgvector embeddings store, and the assembled context is returned to the API Server.

## Trigger

- **Type**: api-call
- **Source**: `continuumLibrechatApp` (`appApiServer`) — triggered as part of every chat request that involves RAG-enabled endpoints
- **Frequency**: Per chat request (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LibreChat App (API Server) | Initiates the retrieval request and consumes the returned context | `continuumLibrechatApp` / `appApiServer` |
| RAG API Handler | Receives the retrieval request and orchestrates the retrieval pipeline | `continuumLibrechatRagApi` / `ragApi` |
| Retriever | Builds the retrieval plan and coordinates sub-components | `continuumLibrechatRagApi` / `ragRetriever` |
| Vector DB Client | Executes the nearest-neighbor vector lookup | `continuumLibrechatRagApi` / `ragVectorClient` |
| VectorDB Embeddings Index | Stores and searches vector embeddings | `continuumLibrechatVectordb` / `vectorEmbeddingsIndex` |

## Steps

1. **API Server sends retrieval request**: The API Server dispatches an HTTP/JSON request to the RAG API Handler containing the user's prompt (and any session context needed for retrieval).
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatRagApi` (`ragApi`)
   - Protocol: HTTP/JSON

2. **RAG API Handler delegates to Retriever**: The RAG API Handler passes the retrieval request to the Retriever component to build a retrieval plan.
   - From: `continuumLibrechatRagApi` (`ragApi`)
   - To: `continuumLibrechatRagApi` (`ragRetriever`)
   - Protocol: In-process

3. **Retriever prepares vector query**: The Retriever determines the query strategy (e.g., which embedding model to use, how many nearest neighbors to retrieve) and instructs the Vector DB Client to execute the lookup.
   - From: `continuumLibrechatRagApi` (`ragRetriever`)
   - To: `continuumLibrechatRagApi` (`ragVectorClient`)
   - Protocol: In-process

4. **Vector DB Client queries pgvector**: The Vector DB Client sends a semantic similarity query (nearest-neighbor search on the embeddings vector column) to the pgvector Embeddings Index.
   - From: `continuumLibrechatRagApi` (`ragVectorClient`)
   - To: `continuumLibrechatVectordb` (`vectorEmbeddingsIndex`)
   - Protocol: PostgreSQL protocol

5. **Embeddings Index returns results**: The pgvector index performs the similarity search and returns the top-k matching document chunks to the Vector DB Client.
   - From: `continuumLibrechatVectordb` (`vectorEmbeddingsIndex`)
   - To: `continuumLibrechatRagApi` (`ragVectorClient`)
   - Protocol: PostgreSQL protocol

6. **Retriever assembles context**: The Retriever receives the matched embeddings and associated content, formats them into a coherent context block.
   - From: `continuumLibrechatRagApi` (`ragVectorClient`)
   - To: `continuumLibrechatRagApi` (`ragRetriever`)
   - Protocol: In-process

7. **RAG API returns context to API Server**: The assembled retrieval context is returned as a JSON response to the calling API Server.
   - From: `continuumLibrechatRagApi` (`ragApi`)
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTP/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| VectorDB (pgvector) unreachable | RAG API Vector DB Client receives a PostgreSQL connection error | RAG API returns an error to API Server; API Server may proceed without context |
| No matching embeddings found | Retriever receives empty result set | Empty context returned; prompt forwarded to LLM without RAG enrichment |
| RAG API timeout | API Server receives HTTP timeout | API Server proceeds without RAG context or returns an error to the user |
| Embedding provider down (during indexing) | New documents cannot be embedded | Retrieval of previously indexed content is unaffected; new content is not indexed |

## Sequence Diagram

```
appApiServer -> ragApi: Requests retrieval context (HTTP/JSON)
ragApi -> ragRetriever: Delegates retrieval plan (in-process)
ragRetriever -> ragVectorClient: Instructs vector lookup (in-process)
ragVectorClient -> vectorEmbeddingsIndex: Semantic similarity search (PostgreSQL protocol)
vectorEmbeddingsIndex --> ragVectorClient: Returns top-k matching embeddings
ragVectorClient --> ragRetriever: Returns embedding results
ragRetriever --> ragApi: Returns assembled context
ragApi --> appApiServer: Returns retrieval context (HTTP/JSON)
```

## Related

- Architecture dynamic view: `dynamic-chat-request-flow`
- Related flows: [Chat Request Flow](chat-request-flow.md)
