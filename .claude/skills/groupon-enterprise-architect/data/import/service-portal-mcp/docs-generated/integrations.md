---
service: "service-portal-mcp"
title: Integrations
generated: "2026-03-03T00:00:00Z"
type: integrations
external_count: 0
internal_count: 1
---

# Integrations

## Overview

service-portal-mcp has a single downstream dependency: the internal Service Portal REST API. It connects to the production or staging environment of that API depending on configuration. The service has no external third-party dependencies beyond observability tooling (Elastic APM).

## External Dependencies

> No evidence found of external third-party API dependencies.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Service Portal REST API | REST / HTTPS | Primary data source — provides all service metadata, cost data, dependency graphs, and OpenAPI schemas that MCP tools surface | `servicePortal` |

### Service Portal REST API Detail

- **Protocol**: REST over HTTPS
- **Base URL / SDK**: Production and staging endpoints configurable via environment variables
- **Auth**: API key forwarded from MCP server configuration
- **Purpose**: The Service Portal is the authoritative registry of all Groupon services. This MCP server wraps its REST API to make that data accessible to AI agents via the MCP protocol.
- **Failure mode**: MCP tool calls fail and return an MCP error response to the caller. No retry or circuit breaker logic is documented in the inventory.
- **Circuit breaker**: No evidence found

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| AI agents and assistants | MCP over HTTP | Invoke tools to query Service Portal data programmatically |
| AI agents (local) | MCP over STDIO | Local developer usage of MCP tools |
| Infrastructure liveness probes | HTTP GET | Health check via `GET /grpn/healthcheck` |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

Health of the upstream Service Portal API is not monitored by this service beyond request-time failure propagation. If the Service Portal API is unavailable, MCP tool calls return errors to the invoking agent. No fallback or cached-data strategy is in place.
