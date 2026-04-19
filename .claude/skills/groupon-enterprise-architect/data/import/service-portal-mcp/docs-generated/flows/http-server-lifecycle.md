---
service: "service-portal-mcp"
title: "HTTP Server Lifecycle"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "http-server-lifecycle"
flow_type: synchronous
trigger: "Process start signal (container launch) or shutdown signal (SIGTERM/SIGINT)"
participants:
  - "servicePortalMcpServer"
  - "Service Portal REST API"
architecture_ref: "dynamic-servicePortalMcpServerLifecycle"
---

# HTTP Server Lifecycle

## Summary

This flow describes the startup and graceful shutdown sequence of the service-portal-mcp server process. On startup, FastMCP initializes the tool registry and Starlette binds the ASGI server to the configured host and port. On shutdown, in-flight requests are allowed to complete before the process exits. This flow is relevant to deployment operations, health check readiness, and rolling restarts.

## Trigger

- **Type**: manual / infrastructure signal
- **Source**: Container orchestration platform (Kubernetes) or direct process management
- **Frequency**: On each deployment, rolling restart, or scaling event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| `servicePortalMcpServer` | Starts up, registers tools, binds HTTP port, handles shutdown | `servicePortalMcpServer` |
| Service Portal REST API | Validated at startup (optional connectivity check) | `servicePortal` |
| Infrastructure liveness probe | Polls `GET /grpn/healthcheck` to confirm readiness | External |

## Steps

1. **Process start**: Container runtime starts the Python process with the configured entrypoint.
   - From: Container orchestration
   - To: `servicePortalMcpServer`
   - Protocol: OS process signal

2. **Load configuration**: Process reads environment variables (`SERVICE_PORTAL_API_URL`, `SERVICE_PORTAL_API_KEY`, `MCP_TRANSPORT`, `MCP_HOST`, `MCP_PORT`, and observability settings).
   - From: `servicePortalMcpServer`
   - To: Environment / mounted secrets
   - Protocol: direct (in-process)

3. **Initialize tool registry**: FastMCP registers all 12 MCP tools and their handler functions.
   - From: `servicePortalMcpServer` (FastMCP initialization)
   - To: `servicePortalMcpServer` (in-memory tool registry)
   - Protocol: direct (in-process)

4. **Bind ASGI server**: Starlette ASGI server binds to `MCP_HOST:MCP_PORT` and begins accepting connections.
   - From: `servicePortalMcpServer`
   - To: Network interface
   - Protocol: HTTP

5. **Health check becomes ready**: The `GET /grpn/healthcheck` endpoint responds with HTTP 200, signaling readiness to the orchestration platform.
   - From: Infrastructure liveness probe
   - To: `servicePortalMcpServer`
   - Protocol: HTTP

6. **Receive shutdown signal**: SIGTERM is sent by the orchestration platform (e.g., during rolling restart or scale-down).
   - From: Container orchestration
   - To: `servicePortalMcpServer`
   - Protocol: OS process signal

7. **Graceful shutdown**: Starlette completes in-flight requests up to the configured timeout, then closes the server and exits the process.
   - From: `servicePortalMcpServer`
   - To: (in-flight AI agent connections)
   - Protocol: HTTP / MCP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Missing required environment variable at startup | Process raises configuration error and exits with non-zero status | Pod enters CrashLoopBackOff; orchestration alerts on repeated failures |
| Port already in use | Starlette raises binding error; process exits | Pod fails to start; orchestration restarts |
| Shutdown signal during active tool call | Starlette waits for in-flight request to complete before closing | Clean response delivered to AI agent; graceful exit |

## Sequence Diagram

```
ContainerRuntime -> servicePortalMcpServer: Start process
servicePortalMcpServer -> Environment: Read env vars
servicePortalMcpServer -> servicePortalMcpServer: Register 12 MCP tools
servicePortalMcpServer -> Network: Bind ASGI on MCP_HOST:MCP_PORT
InfrastructureProbe -> servicePortalMcpServer: GET /grpn/healthcheck
servicePortalMcpServer --> InfrastructureProbe: 200 OK
ContainerRuntime -> servicePortalMcpServer: SIGTERM
servicePortalMcpServer -> servicePortalMcpServer: Drain in-flight requests
servicePortalMcpServer -> ContainerRuntime: Process exit (0)
```

## Related

- Architecture dynamic view: `dynamic-servicePortalMcpServerLifecycle`
- Related flows: [MCP Tool Query](mcp-tool-query.md)
