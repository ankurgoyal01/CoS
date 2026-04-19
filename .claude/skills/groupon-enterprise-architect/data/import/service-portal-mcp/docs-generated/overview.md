---
service: "service-portal-mcp"
title: Overview
generated: "2026-03-03T00:00:00Z"
type: overview
domain: "Service Discovery / Cost Analysis / API Documentation"
platform: "Starlette ASGI"
team: "Platform Engineering"
status: active
tech_stack:
  language: "Python"
  language_version: "3.13.7"
  framework: "FastMCP"
  framework_version: "2.12.5"
  runtime: "Python"
  runtime_version: "3.13.7"
  build_tool: "pip"
  package_manager: "pip / pyproject.toml"
---

# Service Portal MCP Overview

## Purpose

service-portal-mcp is a Model Context Protocol (MCP) server that exposes Service Portal data as AI-callable tools. It acts as an integration layer between AI agents or assistants and the internal Service Portal REST API, translating natural-language tool invocations into structured API calls. The service enables AI consumers to discover services, analyze costs, inspect dependencies, and retrieve OpenAPI schemas without direct access to the underlying portal.

## Scope

### In scope

- Exposing 12 MCP tools covering service lookup, cost retrieval, dependency mapping, OpenAPI schema access, and attribute management
- Serving MCP requests over both HTTP (Starlette ASGI) and STDIO transport modes
- Health check endpoint for liveness verification
- OpenTelemetry-based distributed tracing via Elastic APM

### Out of scope

- Storing or owning any service metadata (all data owned by the Service Portal)
- Authentication and authorization enforcement beyond what the upstream Service Portal API provides
- Mutation of Service Portal data beyond attribute management tools
- Direct database access of any kind

## Domain Context

- **Business domain**: Service Discovery / Cost Analysis / API Documentation
- **Platform**: Starlette ASGI (HTTP) + STDIO (local agent usage)
- **Upstream consumers**: AI agents, AI assistants, developer tooling via MCP protocol
- **Downstream dependencies**: Service Portal REST API (production and staging environments)

## Stakeholders

| Role | Description |
|------|-------------|
| Platform Engineering | Owns and maintains this MCP server |
| AI/Developer Tooling Teams | Primary consumers of MCP tools |
| Service Portal Team | Owns the upstream data source this server wraps |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 3.13.7 | pyproject.toml |
| Framework | FastMCP | 2.12.5 | pyproject.toml |
| Runtime | Python | 3.13.7 | pyproject.toml |
| Build tool | pip | — | pyproject.toml |
| Package manager | pip / pyproject.toml | | |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| fastmcp | 2.12.5 | http-framework | MCP server framework providing tool registration and transport handling |
| starlette | (via fastmcp) | http-framework | ASGI web framework for HTTP transport mode |
| httpx | — | http-client | Async HTTP client for calls to Service Portal REST API |
| opentelemetry-api | — | metrics | Distributed tracing instrumentation |
| opentelemetry-sdk | — | metrics | OpenTelemetry SDK for trace export |
| elastic-apm | — | metrics | Elastic APM agent for trace shipping |
| pyyaml | — | serialization | YAML parsing for configuration files |
| pytest | — | testing | Test runner for unit and integration tests |

Categories: `http-framework`, `orm`, `db-client`, `message-client`, `auth`, `logging`, `metrics`, `serialization`, `testing`, `ui-framework`, `state-management`, `validation`, `scheduling`

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
