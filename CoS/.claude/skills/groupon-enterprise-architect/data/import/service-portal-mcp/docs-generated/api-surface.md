---
service: "service-portal-mcp"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [mcp, rest]
auth_mechanisms: [api-key]
---

# API Surface

## Overview

service-portal-mcp exposes two API surfaces: a Model Context Protocol (MCP) tool interface for AI agents and a minimal HTTP endpoint for health monitoring. AI consumers call the 12 MCP tools to retrieve service metadata, costs, dependencies, and OpenAPI schemas from the Service Portal. The HTTP health endpoint is used by infrastructure liveness probes.

## Endpoints

### Health Check

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/grpn/healthcheck` | Liveness probe — confirms the server process is running | None |

### MCP Tools (Service Discovery)

| Tool Name | Purpose | Auth |
|-----------|---------|------|
| `getService` | Retrieve full metadata for a single service by name or ID | API key (forwarded to Service Portal) |
| `listServices` | List all services registered in the Service Portal | API key |
| `getServiceDependencies` | Retrieve upstream and downstream dependency graph for a service | API key |
| `getServiceOpenApiSchema` | Fetch the OpenAPI schema registered for a service | API key |

### MCP Tools (Cost Analysis)

| Tool Name | Purpose | Auth |
|-----------|---------|------|
| `getServiceCosts` | Retrieve cost attribution data for a service | API key |

### MCP Tools (Attribute Management)

| Tool Name | Purpose | Auth |
|-----------|---------|------|
| Attribute tools (7) | Read and write service attribute metadata in the Service Portal | API key |

## Request/Response Patterns

### Common headers

- MCP HTTP transport uses standard MCP protocol framing headers as defined by the FastMCP library.
- Health check endpoint returns HTTP 200 with a plain text or JSON body indicating service liveness.

### Error format

MCP tool errors are returned as structured MCP error responses with an error code and message. HTTP transport errors follow standard HTTP status codes. Specific error shapes are defined by the FastMCP framework.

### Pagination

> No evidence found of pagination on MCP tool responses. List operations return full result sets as provided by the upstream Service Portal API.

## Rate Limits

> No rate limiting configured at the MCP server layer. Rate limiting, if any, is enforced by the upstream Service Portal API.

## Versioning

MCP tools are not versioned at the URL level. Tool names are stable identifiers. The MCP protocol version is determined by the FastMCP 2.12.5 library.

## OpenAPI / Schema References

> No OpenAPI spec file found in this service's repository. The server itself surfaces OpenAPI schemas for other services via the `getServiceOpenApiSchema` MCP tool, but does not publish its own OpenAPI spec.
