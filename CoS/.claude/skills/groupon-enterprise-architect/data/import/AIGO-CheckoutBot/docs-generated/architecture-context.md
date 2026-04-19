---
service: "AIGO-CheckoutBot"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAigoCheckoutBackend, continuumAigoAdminFrontend, continuumAigoChatWidgetBundle, continuumAigoPostgresDb, continuumAigoRedisCache]
---

# Architecture Context

## System Context

AIGO-CheckoutBot is a service within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. The bot operates at the customer-facing checkout layer, embedding a chat widget into Groupon pages and connecting it to an AI orchestration backend. Checkout operators manage conversation behavior through a dedicated admin frontend. The backend integrates with external AI providers (OpenAI, Google Gemini), the Salesforce CRM for escalation, Asana for task tracking, and the Salted engagement platform for event synchronization.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| AIGO Checkout Backend | `continuumAigoCheckoutBackend` | Backend Service | TypeScript, Node.js, Express | Express 4.21.1 / Node.js 18.20.4 | Node.js/Express API service that orchestrates chat, workflow execution, integrations, and persistence |
| AIGO Admin Frontend | `continuumAigoAdminFrontend` | Web Application | TypeScript, Next.js, React | Next.js 14.2.14 / React 18.3.1 | Next.js administrative UI for managing trees, prompts, analytics, and system configuration |
| AIGO Chat Widget Bundle | `continuumAigoChatWidgetBundle` | Embeddable Bundle | TypeScript, React, JavaScript Bundle | React 18.3.1 | Embeddable web chat widget bundle served to customer-facing pages |
| AIGO PostgreSQL | `continuumAigoPostgresDb` | Database | PostgreSQL | — | Primary relational datastore for design, engine, analytics, and simulation schemas |
| AIGO Redis Cache | `continuumAigoRedisCache` | Cache / Queue | Redis | — | Cache and transient state store for SSE tokens, event recovery, and distributed coordination |

## Components by Container

### AIGO Checkout Backend (`continuumAigoCheckoutBackend`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `backendApiLayer` | Express routes, middleware, and request validation for all backend endpoints | TypeScript, Express |
| `backendConversationEngine` | Core orchestration for chat loops, response generation, and routing decisions | TypeScript Services |
| `backendDesignAndConfig` | Services for tree editing, prompts, actions, conditions, and project configuration | TypeScript Services |
| `backendSimulationAndAnalytics` | Simulation execution, replay workflows, and analytics/reporting pipelines | TypeScript Services |
| `backendIntegrationAdapters` | Provider clients and adapters for OpenAI, Salesforce, Salted, and related external APIs | TypeScript Clients |
| `backendDataAccess` | Database repositories, migrations, and data access utilities for PostgreSQL/Redis-backed workflows | TypeScript Repositories |

### AIGO Admin Frontend (`continuumAigoAdminFrontend`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `adminUiShell` | Next.js app shell and page composition for authenticated operator workflows | TypeScript, Next.js |
| `adminStateAndContexts` | React context and hook layer managing editor state, permissions, and workspace data | TypeScript, React |
| `adminApiClients` | Typed client modules calling backend REST endpoints for design, analytics, and operations | TypeScript |

### AIGO Chat Widget Bundle (`continuumAigoChatWidgetBundle`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `widgetUi` | Embeddable chat interface components and interaction controls for end-user conversations | TypeScript, React |
| `widgetConversationState` | Client-side hooks and state managers for polling, streaming, and message lifecycle | TypeScript, React Hooks |
| `widgetTransportClients` | HTTP and SSE/polling clients used to exchange messages and upload files with backend APIs | TypeScript |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAigoAdminFrontend` | `continuumAigoCheckoutBackend` | Calls admin APIs for configuration, design, analytics, and operations | REST/HTTPS |
| `continuumAigoChatWidgetBundle` | `continuumAigoCheckoutBackend` | Sends and receives chat messages, files, and conversation metadata | REST/HTTPS, SSE |
| `continuumAigoCheckoutBackend` | `continuumAigoPostgresDb` | Reads and writes application data across ng_design/ng_engine/ng_analytics/ng_simulation schemas | PostgreSQL |
| `continuumAigoCheckoutBackend` | `continuumAigoRedisCache` | Uses transient state, token caching, and distributed coordination locks | Redis |
| `continuumAigoCheckoutBackend` | `openAiPlatform` | Generates LLM completions and structured responses (stub — not yet in federated model) | REST/HTTPS |
| `continuumAigoCheckoutBackend` | `salesforcePlatform` | Creates and updates case/escalation context (stub — not yet in federated model) | REST/HTTPS |
| `continuumAigoCheckoutBackend` | `asanaPlatform` | Publishes operational follow-up tasks and reports (stub — not yet in federated model) | REST/HTTPS |
| `continuumAigoCheckoutBackend` | `saltedPlatform` | Synchronizes conversation events and engagement state (stub — not yet in federated model) | REST/HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component (Backend): `aigoCheckoutBackendComponents`
- Component (Admin Frontend): `aigoAdminFrontendComponents`
- Component (Chat Widget): `aigoChatWidgetComponents`
- Dynamic (Chat Conversation Flow): `chatConversationFlow`
