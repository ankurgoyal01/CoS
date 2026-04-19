---
service: "service-portal-mcp"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. service-portal-mcp reads all data on-demand from the Service Portal REST API and returns it directly to callers. No data is persisted, cached locally, or replicated by this service.

## Stores

> Not applicable

## Caches

> Not applicable

## Data Flows

All data originates from the upstream Service Portal REST API. The MCP server acts purely as a protocol adapter: it receives a tool invocation, makes one or more REST calls to the Service Portal, and returns the response. No data transformation that would require local storage occurs within this service.
