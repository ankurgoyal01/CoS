---
service: "ads-jobframework"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

ads-jobframework is a Spark batch job framework and does not expose any HTTP endpoints, gRPC services, or other synchronous inbound API surface. All interaction is through scheduled YARN job submission, Hive table reads/writes, and GCS file outputs. External systems consume its outputs via GCS feeds or Hive tables, not via direct API calls to this service.

## Endpoints

> No evidence found in codebase.

The service does not serve HTTP traffic. The following outbound HTTP calls are made by the framework to external APIs (see [Integrations](integrations.md)):

| Direction | URL Pattern | Purpose |
|-----------|-------------|---------|
| Outbound (CitrusAd) | `https://us-integration.citrusad.com/v1/resource/first-i/{adId}` | Report impression callback |
| Outbound (CitrusAd) | `https://us-integration.citrusad.com/v1/resource/second-c/{adId}` | Report click callback |
| Outbound (ClarusAd) | `https://ad.doubleclick.net/ddm/trackimp/...` | DoubleClick impression tracking ping |

## Request/Response Patterns

> No evidence found in codebase. This service does not expose inbound API endpoints.

## Rate Limits

> No rate limiting configured. The service is a batch consumer, not an API server.

## Versioning

> No evidence found in codebase. No API versioning applies.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or proto files are present in the repository.
