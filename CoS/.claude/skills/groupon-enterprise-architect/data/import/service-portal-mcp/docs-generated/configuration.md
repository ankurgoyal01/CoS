---
service: "service-portal-mcp"
title: Configuration
generated: "2026-03-03T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files]
---

# Configuration

## Overview

service-portal-mcp is configured through environment variables and YAML configuration files. Environment variables control transport mode, upstream API connectivity, and observability. YAML files (parsed via pyyaml) may supply additional structured configuration for tool behavior or Service Portal endpoint mapping.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `SERVICE_PORTAL_API_URL` | Base URL of the Service Portal REST API (production or staging) | yes | None | env |
| `SERVICE_PORTAL_API_KEY` | API key for authenticating with the Service Portal REST API | yes | None | env |
| `MCP_TRANSPORT` | Transport mode for the MCP server (`http` or `stdio`) | no | `http` | env |
| `MCP_HOST` | Host address for HTTP transport binding | no | `0.0.0.0` | env |
| `MCP_PORT` | Port for HTTP transport binding | no | `8000` | env |
| `ELASTIC_APM_SERVER_URL` | Elastic APM server endpoint for trace shipping | no | None | env |
| `ELASTIC_APM_SERVICE_NAME` | Service name reported to Elastic APM | no | `service-portal-mcp` | env |
| `ELASTIC_APM_SECRET_TOKEN` | Authentication token for Elastic APM | no | None | env |
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OpenTelemetry OTLP export endpoint | no | None | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No evidence found of feature flags in this service.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `pyproject.toml` | TOML | Project metadata, dependency declarations, build configuration |
| Configuration YAML (path to be confirmed) | YAML | Structured service/tool configuration parsed via pyyaml |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `SERVICE_PORTAL_API_KEY` | Authenticates MCP server requests to the Service Portal REST API | env / secret manager |
| `ELASTIC_APM_SECRET_TOKEN` | Authenticates trace shipping to Elastic APM | env / secret manager |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The primary per-environment override is `SERVICE_PORTAL_API_URL`, which points to the production Service Portal API in production and to the staging Service Portal API in non-production environments. All other configuration is expected to remain consistent across environments, with secrets rotated per environment via the secret management system in use.
