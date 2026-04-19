---
service: "service-portal-mcp"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "servicePortal"
  containers: [servicePortalMcpServer]
---

# Architecture Context

## System Context

service-portal-mcp sits at the boundary between AI tooling consumers and the Groupon internal Service Portal. It does not belong to the Continuum, Encore, or MBNXT platform cores — it is a dedicated integration adapter. AI agents invoke MCP tools over HTTP or STDIO; the server translates those invocations into REST calls against the Service Portal API and returns structured results. The service is stateless: it holds no local state and owns no databases.

> No `architecture/` folder is present in this service's repository. Container IDs are derived from the inventory description only. Structurizr diagram references will be added when this service is federated into the central workspace.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MCP Server | `servicePortalMcpServer` | Application | Python / FastMCP / Starlette ASGI | 2.12.5 | Stateless HTTP and STDIO MCP server exposing Service Portal data as AI-callable tools |

## Components by Container

### MCP Server (`servicePortalMcpServer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Tool Registry | Registers and dispatches 12 MCP tools to incoming tool-call requests | FastMCP |
| HTTP Transport | Serves MCP protocol over HTTP using ASGI | Starlette |
| STDIO Transport | Serves MCP protocol over STDIO for local agent usage | FastMCP |
| Service Portal Client | Issues authenticated REST calls to the upstream Service Portal API | httpx |
| Health Endpoint | Responds to `GET /grpn/healthcheck` for liveness probes | Starlette |
| Tracing | Instruments requests with OpenTelemetry and ships traces to Elastic APM | opentelemetry-sdk / elastic-apm |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `servicePortalMcpServer` | Service Portal REST API | Reads service metadata, costs, dependencies, OpenAPI schemas | REST / HTTPS |
| AI Agent / Assistant | `servicePortalMcpServer` | Invokes MCP tools to query Service Portal data | MCP over HTTP or STDIO |

## Architecture Diagram References

> No architecture folder present in this service's repository. Diagram references will be populated when the service is onboarded to the federation model.

- System context: `contexts-servicePortalMcp`
- Container: `containers-servicePortalMcp`
- Component: `components-servicePortalMcpServer`
