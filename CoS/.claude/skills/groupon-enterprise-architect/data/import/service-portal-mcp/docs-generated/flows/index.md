---
service: "service-portal-mcp"
title: Flows
generated: "2026-03-03T00:00:00Z"
type: flows-index
flow_count: 2
---

# Flows

Process and flow documentation for Service Portal MCP.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [MCP Tool Query](mcp-tool-query.md) | synchronous | AI agent invokes an MCP tool | End-to-end flow of an AI agent calling a tool, MCP server translating the request to a Service Portal REST call, and returning structured data |
| [HTTP Server Lifecycle](http-server-lifecycle.md) | synchronous | Process start / shutdown signal | Startup and graceful shutdown of the Starlette ASGI server and FastMCP tool registry |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

MCP tool queries cross the boundary from AI tooling consumers into the Service Portal system. The `servicePortalMcpServer` container mediates all such calls. No Structurizr dynamic views are currently registered for these flows — they will be added when this service is federated into the central architecture workspace.
