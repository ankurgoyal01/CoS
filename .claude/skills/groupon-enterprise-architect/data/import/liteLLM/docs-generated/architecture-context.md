---
service: "liteLLM"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumLiteLlmGateway]
---

# Architecture Context

## System Context

LiteLLM is deployed as a single-component container within the `continuumSystem` (Continuum Platform), Groupon's core commerce engine. It acts as an internal AI gateway: internal services submit OpenAI-compatible LLM requests to LiteLLM, which routes them to upstream LLM provider APIs, applies caching, and returns normalized responses. The gateway connects outward to external LLM provider APIs over HTTPS, and inward to the Continuum platform's shared observability infrastructure (logging, metrics, tracing) and a PostgreSQL database for model configuration persistence.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| LiteLLM Gateway | `continuumLiteLlmGateway` | Service / API | Python 3.13 / LiteLLM | v1.80.8-stable | Single deployable LiteLLM runtime handling model routing, API compatibility, and provider integrations. |

## Components by Container

### LiteLLM Gateway (`continuumLiteLlmGateway`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Router (`gatewayRequestRouter`) | Accepts OpenAI-compatible requests and routes to provider/model execution paths. | LiteLLM Router |
| Provider Adapter (`gatewayProviderAdapter`) | Executes outbound provider-specific API calls and normalizes responses. | LiteLLM Provider Integrations |
| Config Resolver (`gatewayConfigResolver`) | Loads and merges environment/runtime configuration used by request routing. | Configuration Layer |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumLiteLlmGateway` | Upstream LLM Providers | Invokes upstream LLM completion/chat APIs | HTTPS |
| `continuumLiteLlmGateway` | PostgreSQL Database | Reads/writes persisted config and model metadata when DB-backed storage is enabled | TCP / SQL |
| `continuumLiteLlmGateway` | `loggingStack` | Emits structured application and access logs | Internal |
| `continuumLiteLlmGateway` | `metricsStack` | Publishes runtime metrics for autoscaling and alerting | Internal |
| `continuumLiteLlmGateway` | `tracingStack` | Exports request traces for latency and dependency diagnostics | Internal |
| `gatewayRequestRouter` | `gatewayProviderAdapter` | Delegates provider/model selection and execution | Internal |
| `gatewayConfigResolver` | `gatewayRequestRouter` | Supplies effective runtime configuration for each request | Internal |

## Architecture Diagram References

- Component view: `components-continuum-litellm-gateway`
- Dynamic request flow: `dynamic-litellm-request-flow`
