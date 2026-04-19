---
service: "librechat"
title: "Conversation Persistence Flow"
generated: "2026-03-03"
type: flow
flow_name: "conversation-persistence-flow"
flow_type: synchronous
trigger: "A chat turn (prompt + LLM response) completes successfully"
participants:
  - "continuumLibrechatApp"
  - "continuumLibrechatMongodb"
architecture_ref: "components-continuum-librechat-app"
---

# Conversation Persistence Flow

## Summary

After each completed chat turn, the LibreChat API Server writes the user's prompt and the LLM's response to the MongoDB Conversation Store. This ensures conversation history is durable, queryable, and available across browser sessions and page reloads. The API Server also reads from the Conversation Store to load prior history when a conversation is resumed.

## Trigger

- **Type**: api-call (internal, part of every chat request)
- **Source**: `continuumLibrechatApp` (`appApiServer`) — triggered after the LLM response is received
- **Frequency**: Per chat turn (on demand)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| LibreChat App (API Server) | Orchestrates reads and writes to the Conversation Store | `continuumLibrechatApp` / `appApiServer` |
| MongoDB (Conversation Store) | Persists conversation threads and individual messages | `continuumLibrechatMongodb` / `mongoConversationStore` |
| MongoDB (User Store) | Provides user identity and role context | `continuumLibrechatMongodb` / `mongoUserStore` |

## Steps

1. **Load conversation history (on conversation open)**: When a user opens an existing conversation, the API Server queries the Conversation Store for prior messages by conversation ID.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatMongodb` (`mongoConversationStore`)
   - Protocol: MongoDB protocol

2. **Conversation Store returns messages**: The Conversation Store returns the ordered message array for the conversation.
   - From: `continuumLibrechatMongodb` (`mongoConversationStore`)
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: MongoDB protocol

3. **API Server receives LLM response**: After the LLM completion is returned (via LiteLLM proxy), the API Server prepares the new message document containing the prompt and response.
   - From: LiteLLM proxy (external)
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: HTTP/JSON (prior step — see Chat Request Flow)

4. **API Server writes message to Conversation Store**: The API Server appends the new message document to the conversation record in MongoDB.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatMongodb` (`mongoConversationStore`)
   - Protocol: MongoDB protocol

5. **Conversation Store confirms write**: MongoDB acknowledges the write operation.
   - From: `continuumLibrechatMongodb` (`mongoConversationStore`)
   - To: `continuumLibrechatApp` (`appApiServer`)
   - Protocol: MongoDB protocol

6. **API Server returns response to Web UI**: With persistence confirmed, the API Server sends the LLM response to the Web UI for rendering.
   - From: `continuumLibrechatApp` (`appApiServer`)
   - To: `continuumLibrechatApp` (`appWebUi`)
   - Protocol: HTTPS/JSON

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MongoDB Conversation Store write fails | Write error returned to API Server | Response may still be displayed to user in-browser, but is not durably stored |
| MongoDB connection unavailable | API Server cannot read or write conversations | Conversation history unavailable; new turns cannot be persisted |
| MongoDB replica set not ready | Write not accepted by primary | Write failure propagated to API Server |

## Sequence Diagram

```
appApiServer -> mongoConversationStore: Load conversation history by ID (MongoDB protocol)
mongoConversationStore --> appApiServer: Returns ordered messages array
appApiServer -> mongoConversationStore: Appends new prompt+response message (MongoDB protocol)
mongoConversationStore --> appApiServer: Confirms write acknowledgment
appApiServer --> appWebUi: Returns LLM response for rendering (HTTPS/JSON)
```

## Related

- Architecture dynamic view: `components-continuum-librechat-app`
- Related flows: [Chat Request Flow](chat-request-flow.md)
