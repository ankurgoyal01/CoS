---
service: "AIGO-CheckoutBot"
title: Integrations
generated: "2026-03-02T00:00:00Z"
type: integrations
external_count: 4
internal_count: 0
---

# Integrations

## Overview

AIGO-CheckoutBot integrates with four external platforms via the `backendIntegrationAdapters` component in `continuumAigoCheckoutBackend`. Two are LLM providers (OpenAI and Google Gemini) for response generation; one is a CRM (Salesforce) for escalation management; and one is a task/project management platform (Asana) for operational follow-up. A fourth integration with the Salted engagement platform synchronizes conversation events. None of these four external systems currently appear in the central federated architecture model — they are represented as stubs in the local workspace DSL. There are no internal Groupon service dependencies identified in the inventory.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| OpenAI GPT | REST/HTTPS (SDK) | Generate LLM completions and structured bot responses | yes | `openAiPlatform` (stub) |
| Google Gemini | REST/HTTPS (SDK) | Alternative LLM provider for completions | yes | — |
| Salesforce | REST/HTTPS | Create and update support case/escalation context | no | `salesforcePlatform` (stub) |
| Asana | REST/HTTPS | Publish operational follow-up tasks and reports | no | `asanaPlatform` (stub) |
| Salted | REST/HTTPS | Synchronize conversation events and engagement state | no | `saltedPlatform` (stub) |

### OpenAI GPT Detail

- **Protocol**: REST/HTTPS via `openai` SDK 4.98.0
- **Base URL / SDK**: `openai` npm package 4.98.0
- **Auth**: API key (secret)
- **Purpose**: The `backendIntegrationAdapters` component invokes OpenAI to generate chat responses within conversation turns, using the GPT models selected per project configuration. Structured output modes are used where decision tree branching requires typed responses.
- **Failure mode**: If OpenAI is unavailable, conversation turn processing fails and the user receives an error response. No fallback LLM is automatically triggered.
- **Circuit breaker**: No evidence found in the inventory.

### Google Gemini Detail

- **Protocol**: REST/HTTPS via `@google/genai` SDK 1.9.0
- **Base URL / SDK**: `@google/genai` npm package 1.9.0
- **Auth**: API key (secret)
- **Purpose**: Alternative LLM provider available for projects configured to use Google Gemini instead of OpenAI GPT. Selected at the project configuration level by `backendDesignAndConfig`.
- **Failure mode**: Conversation turn processing fails for projects using Gemini if the service is unavailable.
- **Circuit breaker**: No evidence found in the inventory.

### Salesforce Detail

- **Protocol**: REST/HTTPS via `axios` 1.7.7
- **Base URL / SDK**: Salesforce REST API (base URL from environment configuration)
- **Auth**: OAuth2 credentials (secret)
- **Purpose**: When a conversation is escalated (human handoff triggered), the `backendIntegrationAdapters` creates or updates a Salesforce case with conversation context to enable support agents to continue the interaction.
- **Failure mode**: Escalation case creation fails silently or triggers a retry; the conversation remains in an escalated state in the local database.
- **Circuit breaker**: No evidence found in the inventory.

### Asana Detail

- **Protocol**: REST/HTTPS via `axios` 1.7.7
- **Base URL / SDK**: Asana REST API (base URL from environment configuration)
- **Auth**: Personal access token or OAuth2 (secret)
- **Purpose**: Publishes operational follow-up tasks (e.g., unanswered questions, failed flows) to an Asana project for the AIGO Team to review and act on.
- **Failure mode**: Task creation failure is non-critical; the main conversation flow is not affected.
- **Circuit breaker**: No evidence found in the inventory.

### Salted Detail

- **Protocol**: REST/HTTPS via `axios` 1.7.7
- **Base URL / SDK**: Salted platform API (base URL from environment configuration)
- **Auth**: API key or token (secret)
- **Purpose**: Synchronizes conversation events and engagement state to the Salted engagement platform, enabling downstream tracking and activation workflows.
- **Failure mode**: Non-critical; conversation data is not lost if Salted is unavailable.
- **Circuit breaker**: No evidence found in the inventory.

## Internal Dependencies

> No evidence found of dependencies on other internal Groupon services from this inventory.

## Consumed By

> Upstream consumers are tracked in the central architecture model. The Chat Widget Bundle (`continuumAigoChatWidgetBundle`) is the primary real-time consumer. The Admin Frontend (`continuumAigoAdminFrontend`) consumes admin APIs. Both are part of this same service boundary.

## Dependency Health

No circuit breaker or retry patterns are documented in the inventory. Health check behavior for external integrations is not discoverable from the DSL. The `/health` endpoint reflects the backend's own liveness but does not expose dependency health status. Operational procedures for dependency failures should be defined by the service owner.
