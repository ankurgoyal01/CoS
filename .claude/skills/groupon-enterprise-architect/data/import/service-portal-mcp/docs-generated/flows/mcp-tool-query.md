---
service: "service-portal-mcp"
title: "MCP Tool Query"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "mcp-tool-query"
flow_type: synchronous
trigger: "AI agent invokes an MCP tool (e.g., getService, listServices, getServiceCosts)"
participants:
  - "AI Agent / Assistant"
  - "servicePortalMcpServer"
  - "Service Portal REST API"
architecture_ref: "dynamic-servicePortalMcpToolQuery"
---

# MCP Tool Query

## Summary

This flow describes the end-to-end path of an AI agent invoking one of the 12 MCP tools exposed by service-portal-mcp. The MCP server receives the tool call, validates its parameters, issues one or more authenticated REST calls to the Service Portal API, and returns the structured result to the calling agent. The entire flow is synchronous and completes within the scope of a single MCP request/response cycle.

## Trigger

- **Type**: api-call
- **Source**: AI agent or assistant (connected via MCP over HTTP or STDIO transport)
- **Frequency**: On-demand, per tool invocation

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| AI Agent / Assistant | Initiates tool call with tool name and parameters | External consumer |
| `servicePortalMcpServer` | Receives MCP tool call, dispatches to tool handler, calls Service Portal, returns result | `servicePortalMcpServer` |
| Service Portal REST API | Authoritative data source — returns service metadata, costs, dependencies, or schemas | `servicePortal` |

## Steps

1. **Receive tool invocation**: AI agent sends an MCP tool call request specifying the tool name (e.g., `getService`, `getServiceCosts`, `getServiceDependencies`) and parameters.
   - From: `AI Agent / Assistant`
   - To: `servicePortalMcpServer`
   - Protocol: MCP over HTTP (Starlette ASGI) or STDIO

2. **Dispatch to tool handler**: FastMCP routes the tool call to the registered handler function for the named tool.
   - From: `servicePortalMcpServer` (MCP layer)
   - To: `servicePortalMcpServer` (tool handler)
   - Protocol: direct (in-process)

3. **Call Service Portal API**: The tool handler constructs an authenticated HTTP request and issues it to the Service Portal REST API using httpx.
   - From: `servicePortalMcpServer`
   - To: Service Portal REST API
   - Protocol: REST / HTTPS

4. **Receive Service Portal response**: The Service Portal returns the requested data (service record, cost data, dependency list, OpenAPI schema, or attribute values).
   - From: Service Portal REST API
   - To: `servicePortalMcpServer`
   - Protocol: REST / HTTPS

5. **Return MCP result**: The tool handler serializes the Service Portal response into the MCP result format and returns it to the calling AI agent.
   - From: `servicePortalMcpServer`
   - To: AI Agent / Assistant
   - Protocol: MCP over HTTP or STDIO

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Service Portal API unreachable | httpx raises a connection error; tool handler catches and returns MCP error response | AI agent receives structured error; no retry at MCP layer |
| Service Portal returns 4xx (bad request / not found) | Tool handler propagates error as MCP error response | AI agent receives error with Service Portal message |
| Service Portal returns 5xx | Tool handler returns MCP error response | AI agent receives error; no circuit breaker |
| Invalid tool parameters | FastMCP validates parameters before dispatch; returns MCP validation error | AI agent receives parameter error before upstream is called |

## Sequence Diagram

```
AI Agent -> servicePortalMcpServer: MCP tool call (toolName, params)
servicePortalMcpServer -> servicePortalMcpServer: Route to tool handler
servicePortalMcpServer -> Service Portal REST API: GET /services/{id} (or equivalent) [HTTPS + API key]
Service Portal REST API --> servicePortalMcpServer: 200 OK (service data)
servicePortalMcpServer --> AI Agent: MCP result (structured data)
```

## Related

- Architecture dynamic view: `dynamic-servicePortalMcpToolQuery`
- Related flows: [HTTP Server Lifecycle](http-server-lifecycle.md)
