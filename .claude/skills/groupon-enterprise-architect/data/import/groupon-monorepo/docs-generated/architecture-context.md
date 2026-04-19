---
service: "groupon-monorepo"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "encoreSystem"
  containers: [encoreTs, encoreGo, adminReactFe, aidgReactFe, supportAngularFe, iqChromeExtension, microservicesPython, mastraTs]
---

# Architecture Context

## System Context

The Encore Platform (`encoreSystem`) is Groupon's next-generation commerce backbone. It sits at the center of the internal tooling ecosystem, serving admin users and sales representatives through multiple frontend applications. The platform integrates heavily with external systems including Salesforce for CRM, BigQuery for analytics, Mux for video, and bridges to legacy Continuum services for orders, merchants, and deals. It is modeled as a single C4 software system containing multiple containers organized by language runtime and application tier.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Encore TypeScript Backend | `encoreTs` | Backend Service | Encore TS, Node.js 22 | 1.54 | Primary backend: 60+ microservices organized by tribe (Core, B2B, B2C, AI, Marketing, Cloud Ops, IT) |
| Encore Go Backend | `encoreGo` | Backend Service | Encore Go, Go 1.24 | 1.48 | Search and recommendation services (gorapi autocomplete, lrapi deals, vespa-reader) |
| Admin React Frontend | `adminReactFe` | Web Application | Next.js 15, React 19 | 15.5 | Primary admin dashboard for internal operators |
| AIDG React Frontend | `aidgReactFe` | Web Application | Next.js 15, React 19 | 15.3 | AI-driven deal generation interface |
| Support Angular Frontend | `supportAngularFe` | Web Application | Angular | -- | Customer support admin interface |
| IQ Chrome Extension | `iqChromeExtension` | Browser Extension | Chrome Extension API | -- | Internal productivity browser extension |
| Python Microservices | `microservicesPython` | Backend Service | FastAPI, Docker | -- | AI/ML microservices (image classification, content generation, merchant quality) |
| Mastra AI Agent | `mastraTs` | Backend Service | Mastra TS | 0.10.1 | AI agent orchestration runtime |

## Components by Container

### Encore TypeScript Backend (`encoreTs`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| _core_system/gateway | API gateway, cookie-based authentication | Encore TS |
| _core_system/authentication | Google OAuth, JWT token management | Encore TS, Arctic, jsonwebtoken |
| _core_system/authorization | Role-based access control | Encore TS |
| _core_system/ai-gateway | Centralized LLM proxy (OpenAI, Anthropic) with Langfuse observability | Encore TS, LangChain, Langfuse |
| _core_system/ai_agents | AI agent execution and management | Encore TS, Mastra |
| _core_system/big-query | BigQuery analytics proxy | Encore TS, googleapis |
| _core_system/kafka | Kafka consumer bridge for legacy events | Encore TS, kafkajs |
| _core_system/mbus | Continuum message bus (STOMP) publisher/subscriber | Encore TS, @stomp/stompjs |
| _core_system/email | Email delivery service | Encore TS, @sendgrid/mail |
| _core_system/sms | SMS messaging service | Encore TS, Twilio |
| _core_system/notifications | Push notification service with database persistence | Encore TS, PostgreSQL |
| _core_system/video | Video upload and processing pipeline | Encore TS, @mux/mux-node |
| _core_system/images | Image upload, processing, and storage | Encore TS, Sharp |
| _core_system/bynder | Digital asset management integration | Encore TS |
| _core_system/user | User management and Workday hierarchy sync | Encore TS |
| _core_system/translations | Localization and translation service (Localazy) | Encore TS, @localazy/api-client |
| _core_system/feature-flags | Feature flag management | Encore TS |
| _core_system/auditlog | Audit log recording and querying | Encore TS |
| _core_system/api_tokens | API token issuance and validation (HMAC) | Encore TS |
| _core_system/websocket | Real-time WebSocket communication | Encore TS, ws |
| _core_system/microfrontend | Microfrontend registry and loader | Encore TS |
| _core_system/workflow_management | Temporal workflow registration and management | Encore TS, PostgreSQL |
| _core_system/service-management | Service catalog and health management | Encore TS |
| _tribe_b2b/deal | Deal lifecycle: creation, versioning, IQ import, approval, publishing | Encore TS, PostgreSQL |
| _tribe_b2b/accounts | Merchant accounts with Salesforce bidirectional sync | Encore TS, PostgreSQL |
| _tribe_b2b/salesforce | Salesforce API integration proxy | Encore TS, jsforce |
| _tribe_b2b/brands | Brand management with metrics | Encore TS, PostgreSQL |
| _tribe_b2b/custom-fields | Custom field definitions and values | Encore TS, PostgreSQL |
| _tribe_b2b/deal_sync | Deal synchronization with Continuum DMAPI | Encore TS, PostgreSQL |
| _tribe_b2b/deal_alerts | Deal performance alerts (BigQuery + Google Chat) | Encore TS |
| _tribe_b2b/deal_performance | Deal performance analytics | Encore TS |
| _tribe_b2b/dashboard | B2B operational dashboards | Encore TS |
| _tribe_b2b/tagging | Entity tagging system with async workers | Encore TS, PostgreSQL |
| _tribe_b2b/faq | FAQ management service | Encore TS, PostgreSQL |
| _tribe_b2b/reports | Reporting engine | Encore TS, PostgreSQL |
| _tribe_b2b/umapi | Universal Merchant API wrapper (Continuum) | Encore TS |
| _tribe_b2b/dmapi | Deal Management API wrapper (Continuum) | Encore TS |
| _tribe_b2b/api_lazlo | Lazlo API wrapper (Continuum) | Encore TS |
| _tribe_b2b/bhuvan | Merchant data service wrapper (Continuum) | Encore TS |
| _tribe_b2b/m3 | M3 merchant service integration | Encore TS |
| _tribe_b2b/google_places | Google Places API integration | Encore TS |
| _tribe_b2b/bloomreach_integration_service | Bloomreach personalization integration | Encore TS |
| _tribe_b2b/ugc | User-generated content management | Encore TS |
| _tribe_b2b/notes | Internal notes and comments | Encore TS |
| _tribe_b2b/tasks | Task management system | Encore TS |
| _tribe_b2b/presence | User presence tracking | Encore TS |
| _tribe_b2b/taxonomy | Category taxonomy management | Encore TS |
| _tribe_b2b/gazebo | Gazebo deal tool | Encore TS |
| _tribe_b2b/metro-draft-service | Metro area deal drafting | Encore TS |
| _tribe_b2b/mx-reporting | Merchant experience reporting | Encore TS |
| _tribe_b2b/reporting-service | General reporting service | Encore TS |
| _tribe_b2b/dc | Data center operations | Encore TS |
| _tribe_b2b/dct | Deal content tools | Encore TS |
| _tribe_b2b/deal-book-service | Deal book management | Encore TS |
| _tribe_b2b/mds | Merchant data service | Encore TS |
| _tribe_core/orders | Order management (Continuum wrapper) | Encore TS |
| _tribe_core/janus | Janus analytics event processing | Encore TS |
| _tribe_core/checkout-events | Checkout event processing | Encore TS, PostgreSQL |
| _tribe_core/gen_ai | AI content generation for core flows | Encore TS |
| _tribe_b2c/booster | Booster relevance API integration | Encore TS |
| _tribe_b2c/deal-reviews | Deal review aggregation and analytics | Encore TS, PostgreSQL |
| _tribe_ai/aidg_aiaas | AI-as-a-Service proxy for Python ML services | Encore TS |
| _tribe_marketing/partner_order_sync_service | Partner order synchronization | Encore TS, PostgreSQL |
| _tribe_cloud_operations/service-portal-mcp | Service portal MCP server | Encore TS |
| aidg | AIDG core service (Salesforce sync, data processing, pub/sub) | Encore TS, MongoDB |
| workflows | Temporal workflow orchestration across all tribes | Encore TS, @temporalio/* |

### Encore Go Backend (`encoreGo`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| gorapi/autocomplete | Deal recommendation autocomplete API | Go, Booster API, Vespa.ai |
| gorapi/lrapi | Deal search API with query preprocessing | Go, Vespa.ai, Suggest service |
| vespa-reader | Vespa.ai search integration (internal) | Go, Vespa.ai |

### Admin React Frontend (`adminReactFe`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Admin Dashboard | Primary admin interface for all internal operations | Next.js 15, React 19, Ant Design, Tailwind CSS |
| Monaco Editor | Code and JSON editing within admin | @monaco-editor/react |
| Map Integration | Location and merchant mapping | MapLibre GL, MapTiler |
| Swagger UI | Embedded API documentation viewer | swagger-ui-react |

### AIDG React Frontend (`aidgReactFe`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| AIDG Dashboard | AI-driven deal generation workspace | Next.js 15, React 19, Radix UI, Tailwind CSS |
| AI Chat | LLM-powered conversational deal creation | Vercel AI SDK |
| Leaflet Maps | Merchant location mapping | react-leaflet |
| Supabase Auth | AIDG-specific authentication | @supabase/supabase-js |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `adminReactFe` | Manages deals, merchants, operations | HTTPS |
| `salesRep` | `aidgReactFe` | Creates AI-generated deals | HTTPS |
| `adminReactFe` | `encoreTs` | All admin operations | REST (generated client) |
| `aidgReactFe` | `encoreTs` | AIDG operations and AI workflows | REST (generated client) |
| `encoreTs` | `salesForce` | CRM bidirectional sync (accounts, deals) | REST (jsforce) |
| `encoreTs` | `bigQuery` | Analytics queries and data export | REST (googleapis) |
| `encoreTs` | `mux` | Video upload, processing, playback | REST (mux-node SDK) |
| `encoreTs` | `twilio` | SMS messaging | REST (Twilio SDK) |
| `encoreTs` | `bloomreach` | Personalization integration | REST |
| `encoreTs` | `bynder` | Digital asset management | REST |
| `encoreTs` | `messageBus` | Legacy Continuum STOMP message bus | STOMP |
| `encoreTs` | `continuumOrdersService` | Order management proxy | REST |
| `encoreTs` | `continuumDealManagementApi` | Deal management proxy (DMAPI) | REST |
| `encoreTs` | `continuumUniversalMerchantApi` | Merchant operations proxy (UMAPI) | REST |
| `encoreTs` | `continuumApiLazloService` | Deal data enrichment (Lazlo) | REST |
| `encoreTs` | `continuumBhuvanService` | Merchant data proxy (Bhuvan) | REST |
| `encoreTs` | `continuumM3MerchantService` | M3 merchant service | REST |
| `encoreTs` | `continuumM3PlacesService` | M3 place read integration | REST |
| `encoreTs` | `edw` | Teradata EDW analytics proxy | ODBC |
| `encoreTs` | `githubEnterprise` | GitHub integration for CI/deployment triggers | REST |
| `encoreTs` | `microservicesPython` | AI/ML service calls | REST |
| `encoreGo` | `booster` | Deal recommendations | REST (HMAC auth) |
| `encoreGo` | `googlePlaces` | Places API for location enrichment | REST |
| `microservicesPython` | `encoreTs` | Callback notifications | REST (generated client) |

## Architecture Diagram References

- System context: `contexts-encoreSystem`
- Container: `containers-encoreSystem`
- Component: `components-encoreTs`
