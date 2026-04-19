---
service: "sem-gcp-pipelines"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

sem-gcp-pipelines does not expose any inbound HTTP API, gRPC, or webhook endpoints. It is an Airflow DAG collection that operates exclusively as a scheduled data pipeline. All interactions are outbound: it calls internal Groupon services and external ad-platform APIs, and publishes messages to the internal Message Bus. The Airflow UI (GCP Composer) is the sole operator-facing interface for triggering and monitoring DAGs.

## Endpoints

> Not applicable. This service exposes no inbound API endpoints.

The Airflow Composer web UI provides DAG management access at:

| Environment | Composer URL |
|-------------|-------------|
| dev | `https://d134c969a7dc418dba6e877f8f4fa5b0-dot-us-central1.composer.googleusercontent.com` |
| stable | `https://4952faa6ee0242268293dfe488980af0-dot-us-central1.composer.googleusercontent.com` |
| prod | `https://91c76cae09ac40609460f5e26460e6e8-dot-us-central1.composer.googleusercontent.com` |

## Request/Response Patterns

> Not applicable — no inbound API.

## Rate Limits

> Not applicable — no inbound API exposed.

## Versioning

> Not applicable — no inbound API versioning.

## OpenAPI / Schema References

> Not applicable — no API schema defined. See [Events](events.md) for Message Bus message schemas, and [Integrations](integrations.md) for outbound API call patterns.
