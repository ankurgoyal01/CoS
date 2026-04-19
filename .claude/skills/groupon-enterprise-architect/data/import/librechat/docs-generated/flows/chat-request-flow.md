---
service: "librechat"
title: "Chat Request Flow"
generated: "2026-03-03"
type: flow
flow_name: "chat-request-flow"
flow_type: synchronous
trigger: "User submits a prompt in the LibreChat web UI"
participants:
  - "consumer"
  - "continuumLibrechatApp"
  - "continuumLibrechatRagApi"
  - "continuumLibrechatVectordb"
  - "continuumLibrechatMongodb"
architecture_ref: "dynamic-chat-request-flow"
---

# Chat Request Flow

## Summary

The Chat Request Flow is the core end-to-end process in LibreChat. A Groupon employee submits a prompt via the React-based Web UI; the API Server enriches the prompt with retrieval-augmented context from the RAG API (which queries the vector embeddings store), then forwards the augmented prompt to the LiteLLM proxy for model completion. The response is returned to the user and the conversation turn is persisted to MongoDB.

## Trigger

- **Type**: user-action
- **Source**: Groupon employee (`consumer`) submits a message in the LibreChat browser UI
- **Frequency**: On demand, per chat message

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer (Groupon employee) | Initiates the prompt and receives the response | `consumer` |
| LibreChat App (Web UI) | Captures user input and renders response | `continuumLibrechatApp` / `appWebUi` |
| LibreChat App (API Server) | Orchestrates RAG retrieval, LLM call, and persistence | `continuumLibrechatApp` / `appApiServer` |
| RAG API | Assembles retrieval context for the prompt | `continuumLibrechatRagApi` |
| VectorDB (pgvector) | Executes semantic similarity search for relevant embeddings | `continuumLibrechatVectordb` |
| MongoDB | Persists the conversation turn | `continuumLibrechatMongodb` |
| LiteLLM proxy | Routes the augmented prompt to the selected LLM provider | External — not modeled in DSL |

## Steps

1. **User submits prompt**: The Groupon employee types a message in the Web UI and submits.
   - From: `consumer`
   - To: `continuumLibrechatApp` (`appWebUi`)
   - Protocol: HTTPS

2. **Web UI forwards to API Server**: The React frontend sends the chat input to the backend API Server.
   - From: `continuumLibrechatApp` (`appWebUi`)
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTPS/JSON

3. **API Server requests retrieval context**: The API Server sends the prompt to the RAG API to retrieve relevant document context before calling the LLM.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatRagApi` (`ragApi`)
   - Protocol: HTTP/JSON

4. **RAG API coordinates retrieval pipeline**: The RAG API Handler passes the request to the Retriever, which builds the retrieval plan.
   - From: `continuumLibrechatRagApi` (`ragApi`)
   - To: `continuumLibrechatRagApi` (`ragRetriever`)
   - Protocol: In-process

5. **Retriever executes vector lookup**: The Retriever instructs the Vector DB Client to perform a nearest-neighbor search in VectorDB.
   - From: `continuumLibrechatRagApi` (`ragRetriever`)
   - To: `continuumLibrechatRagApi` (`ragVectorClient`)
   - Protocol: In-process

6. **Vector similarity search**: The Vector DB Client queries the pgvector embeddings index for semantically similar content.
   - From: `continuumLibrechatRagApi` (`ragVectorClient`)
   - To: `continuumLibrechatVectordb` (`vectorEmbeddingsIndex`)
   - Protocol: PostgreSQL protocol

7. **VectorDB returns matching embeddings**: The embeddings index returns nearest-neighbor results to the Vector DB Client, which returns context to the Retriever and RAG API Handler.
   - From: `continuumLibrechatVectordb` (`vectorEmbeddingsIndex`)
   - To: `continuumLibrechatRagApi`
   - Protocol: PostgreSQL protocol

8. **RAG API returns context to API Server**: The assembled retrieval context is returned as JSON to the API Server.
   - From: `continuumLibrechatRagApi`
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTP/JSON

9. **API Server calls LiteLLM proxy**: The API Server combines the original prompt with the retrieved context and sends the enriched request to the LiteLLM proxy, selecting the configured model (e.g., `gpt-4.1-mini`, `claude-4-opus-20250514`).
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: LiteLLM proxy (external)
   - Protocol: HTTP/JSON

10. **LiteLLM returns LLM response**: The LLM model generates a completion; LiteLLM returns it to the API Server.
    - From: LiteLLM proxy (external)
    - To: `continuumLibrechatApp` (`appApiServer`)
    - Protocol: HTTP/JSON

11. **API Server persists conversation turn**: The API Server writes the prompt and response as a new message to the MongoDB Conversation Store.
    - From: `continuumLibrechatApp` (`appApiServer`)
    - To: `continuumLibrechatMongodb` (`mongoConversationStore`)
    - Protocol: MongoDB protocol

12. **Response rendered in UI**: The API Server returns the LLM response to the Web UI, which renders it in the chat thread.
    - From: `continuumLibrechatApp` (`appApiServer`)
    - To: `consumer` (via `appWebUi`)
    - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LiteLLM proxy unreachable | API Server receives HTTP error from LiteLLM endpoint | Error message displayed to user; turn not persisted |
| RAG API timeout or error | API Server may proceed without retrieval context (behavior inherited from LibreChat open-source defaults) | Prompt sent to LLM without RAG enrichment |
| VectorDB unavailable | RAG API cannot complete retrieval; returns error to API Server | Same as RAG API error path |
| MongoDB write failure | Conversation turn cannot be persisted | Response may still be displayed to user, but history is not saved |

## Sequence Diagram

```
Consumer -> appWebUi: Submits prompt (HTTPS)
appWebUi -> appApiServer: Forwards chat input (HTTPS/JSON)
appApiServer -> ragApi: Requests retrieval context (HTTP/JSON)
ragApi -> ragRetriever: Coordinates retrieval pipeline (in-process)
ragRetriever -> ragVectorClient: Executes vector lookups (in-process)
ragVectorClient -> vectorEmbeddingsIndex: Semantic similarity search (PostgreSQL protocol)
vectorEmbeddingsIndex --> ragVectorClient: Returns nearest-neighbor embeddings
ragVectorClient --> ragRetriever: Returns embedding results
ragRetriever --> ragApi: Returns assembled context
ragApi --> appApiServer: Returns retrieval context (HTTP/JSON)
appApiServer -> LiteLLMProxy: Sends augmented prompt (HTTP/JSON)
LiteLLMProxy --> appApiServer: Returns LLM completion (HTTP/JSON)
appApiServer -> mongoConversationStore: Persists turn (MongoDB protocol)
appApiServer --> appWebUi: Returns response (HTTPS/JSON)
appWebUi --> Consumer: Renders response in chat UI
```

## Related

- Architecture dynamic view: `dynamic-chat-request-flow`
- Related flows: [RAG Context Retrieval Flow](rag-context-retrieval-flow.md), [Conversation Persistence Flow](conversation-persistence-flow.md)
