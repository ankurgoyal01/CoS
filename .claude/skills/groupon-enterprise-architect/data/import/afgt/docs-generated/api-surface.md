---
service: "afgt"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> Not applicable

AFGT is a batch data pipeline with no inbound HTTP API, REST endpoints, gRPC service, or message consumer interface. It is invoked exclusively through the Apache Airflow scheduler on a daily cron schedule (`30 6 * * *` UTC). The pipeline interacts outbound with the Optimus Prime HTTP API to trigger validation jobs, but does not itself expose any API surface.

## Endpoints

> No evidence found — AFGT exposes no inbound HTTP endpoints.

## Request/Response Patterns

### Common headers

> Not applicable — no inbound API.

### Error format

> Not applicable — no inbound API.

### Pagination

> Not applicable — no inbound API.

## Rate Limits

> No rate limiting configured. AFGT is a scheduled batch pipeline with no inbound API traffic.

## Versioning

> Not applicable — no API versioning strategy. Pipeline versioning is managed through Jenkins release tags and artifact versions (`PIPELINE_ARTIFACT_VERSION`).

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exists in this repository. The pipeline's data contract is defined by the Hive table schema of `ima.analytics_fgt` (partitioned by `transaction_date`, `country_id`), documented in `source/sql/hive_load_final.hql`.
