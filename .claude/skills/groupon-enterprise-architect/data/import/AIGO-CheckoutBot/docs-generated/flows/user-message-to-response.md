---
service: "AIGO-CheckoutBot"
title: "User Message to Response"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "user-message-to-response"
flow_type: synchronous
trigger: "User submits a chat message through the embedded Chat Widget on a Groupon page"
participants:
  - "continuumAigoChatWidgetBundle"
  - "continuumAigoCheckoutBackend"
  - "continuumAigoPostgresDb"
  - "continuumAigoRedisCache"
  - "openAiPlatform"
  - "salesforcePlatform"
architecture_ref: "dynamic-chatConversationFlow"
---

# User Message to Response

## Summary

This flow describes the end-to-end processing of a single user chat message through AIGO-CheckoutBot. A user typing in the embedded Chat Widget submits their message to the backend, which evaluates the current conversation state against the configured decision tree, generates an AI response via OpenAI GPT or Google Gemini, persists the conversation turn, and delivers the response back to the widget. If an escalation condition is met, a Salesforce case is created and the Salted platform is notified.

## Trigger

- **Type**: user-action
- **Source**: End user submits a message in the `continuumAigoChatWidgetBundle` embedded on a Groupon checkout page
- **Frequency**: Per-request (every message submitted by a user)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Chat Widget Bundle | Captures user input and delivers responses to the UI | `continuumAigoChatWidgetBundle` |
| Checkout Backend | Orchestrates conversation processing, LLM calls, and persistence | `continuumAigoCheckoutBackend` |
| AIGO PostgreSQL | Durable store for conversation state, message turns, and decision tree | `continuumAigoPostgresDb` |
| AIGO Redis Cache | Transient token store and distributed lock for turn processing | `continuumAigoRedisCache` |
| OpenAI Platform | Generates LLM completion for the bot response | `openAiPlatform` (stub) |
| Salesforce Platform | Receives escalation case when human handoff is triggered | `salesforcePlatform` (stub) |

## Steps

1. **Captures user message**: The user types and submits a message in the Chat Widget UI component (`widgetUi`).
   - From: `widgetUi`
   - To: `widgetTransportClients`
   - Protocol: in-process (React)

2. **Submits message to backend**: The `widgetTransportClients` posts the message and conversation metadata to the backend.
   - From: `continuumAigoChatWidgetBundle`
   - To: `continuumAigoCheckoutBackend` (`POST /api/conversations/:id/messages`)
   - Protocol: REST/HTTPS

3. **Validates and routes request**: The `backendApiLayer` validates the JWT, deserializes the payload, and routes the request to the `backendConversationEngine`.
   - From: `backendApiLayer`
   - To: `backendConversationEngine`
   - Protocol: direct (in-process)

4. **Acquires processing lock**: The `backendConversationEngine` acquires a distributed lock in Redis to prevent duplicate concurrent processing for the same conversation.
   - From: `backendConversationEngine`
   - To: `continuumAigoRedisCache`
   - Protocol: Redis SET NX

5. **Reads conversation state and decision tree node**: The `backendDataAccess` component retrieves the current conversation state and the active decision tree node from PostgreSQL (`ng_engine` and `ng_design` schemas).
   - From: `backendConversationEngine` via `backendDataAccess`
   - To: `continuumAigoPostgresDb`
   - Protocol: PostgreSQL

6. **Generates LLM response**: The `backendIntegrationAdapters` calls the configured LLM provider (OpenAI GPT or Google Gemini) with the conversation context and current node prompt to obtain a response.
   - From: `backendIntegrationAdapters`
   - To: `openAiPlatform` (or Google Gemini)
   - Protocol: REST/HTTPS (SDK)

7. **Evaluates routing conditions**: The `backendConversationEngine` applies decision tree conditions to the LLM response to determine the next node, any triggered actions, or an escalation condition.
   - From: `backendConversationEngine`
   - To: `backendDesignAndConfig` (condition evaluation)
   - Protocol: direct (in-process)

8. **Persists conversation turn**: The `backendDataAccess` writes the new message turn, updated conversation state, and next node pointer to PostgreSQL (`ng_engine` schema). Analytics events are written to `ng_analytics`.
   - From: `backendConversationEngine` via `backendDataAccess`
   - To: `continuumAigoPostgresDb`
   - Protocol: PostgreSQL

9. **Stores SSE token in Redis**: The backend stores or refreshes the SSE delivery token in Redis to enable streaming the response to the widget.
   - From: `continuumAigoCheckoutBackend`
   - To: `continuumAigoRedisCache`
   - Protocol: Redis SET

10. **Publishes Redis Pub/Sub event**: The backend publishes a `chat-message-sent` event to notify any subscribed listeners that a new message turn is available.
    - From: `continuumAigoCheckoutBackend`
    - To: `continuumAigoRedisCache` (Pub/Sub channel: `chat-message-sent`)
    - Protocol: Redis Pub/Sub

11. **(Conditional) Creates Salesforce escalation case**: If an escalation action is triggered, `backendIntegrationAdapters` creates or updates a Salesforce case with the conversation context.
    - From: `backendIntegrationAdapters`
    - To: `salesforcePlatform`
    - Protocol: REST/HTTPS

12. **Returns response to widget**: The backend returns the generated response payload (message content, updated state, next prompt) to the Chat Widget.
    - From: `continuumAigoCheckoutBackend`
    - To: `continuumAigoChatWidgetBundle`
    - Protocol: REST/HTTPS (JSON response or SSE stream)

13. **Renders response in UI**: The `widgetConversationState` updates local state and `widgetUi` renders the bot response to the user.
    - From: `widgetConversationState`
    - To: `widgetUi`
    - Protocol: in-process (React state)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| LLM provider unavailable (OpenAI / Gemini) | Request fails; backend returns error response | User sees an error message in the widget; conversation state not advanced |
| PostgreSQL write failure | Transaction rolled back; lock released | Turn not persisted; user may retry; no duplicate state |
| Redis lock already held (concurrent request) | Request queued or rejected | Prevents duplicate processing; widget may receive a retry signal |
| JWT invalid or expired | `backendApiLayer` rejects request with 401 | Widget prompts re-authentication or shows error |
| Salesforce API unavailable | Escalation case creation fails; logged; main flow continues | Conversation marked escalated locally; no Salesforce case created |
| SSE stream drop | Widget `widgetTransportClients` falls back to HTTP polling | Response delivery delayed; user experience degraded |

## Sequence Diagram

```
widgetUi -> widgetTransportClients: Submit message
widgetTransportClients -> continuumAigoCheckoutBackend: POST /api/conversations/:id/messages (JWT)
continuumAigoCheckoutBackend -> continuumAigoRedisCache: Acquire distributed lock
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Read conversation state + tree node (ng_engine, ng_design)
continuumAigoCheckoutBackend -> openAiPlatform: Request LLM completion
openAiPlatform --> continuumAigoCheckoutBackend: LLM response
continuumAigoCheckoutBackend -> continuumAigoPostgresDb: Persist turn + analytics (ng_engine, ng_analytics)
continuumAigoCheckoutBackend -> continuumAigoRedisCache: Store SSE token + publish chat-message-sent
continuumAigoCheckoutBackend --> continuumAigoChatWidgetBundle: Return response payload
widgetConversationState -> widgetUi: Render bot response
```

## Related

- Architecture dynamic view: `dynamic-chatConversationFlow`
- Related flows: [Design Tree Update](design-tree-update.md), [Analytics Aggregation and Reporting](analytics-aggregation-and-reporting.md)
