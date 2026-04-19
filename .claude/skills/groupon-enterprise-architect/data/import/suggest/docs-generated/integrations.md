---
service: "suggest"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 0
---

# Integrations

## Overview

The Suggest service has three external dependencies: Google BigQuery (primary data source), the Groupon Division API (geographic metadata), and Elastic APM (tracing). All are outbound from the service. There are no internal Groupon service-to-service dependencies beyond the central platform observability stack. The service is consumed by the MBNXT search client.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Google BigQuery | GCP SDK (google-cloud-bigquery) | Reads suggestion query index, ranking metrics, and prefix index tables | yes | `bigQuery_9a2f` |
| Groupon Division API | REST / HTTP GET | Fetches division geographic coordinates (lat/lon) for location-aware suggestion routing | yes | `grouponDivisionApi_4f7b` |
| Elastic APM Server | HTTP (APM agent) | Ships distributed traces and error telemetry | no | `elasticApmServer_5d2c` |

### Google BigQuery Detail

- **Protocol**: GCP Python SDK (`google-cloud-bigquery==3.34.0`)
- **Base URL / SDK**: GCP project `prj-grp-dataview-prod-1ff9`; credentials loaded from `resources/service-account-key.json`
- **Auth**: GCP service account key file (path: `resources/service-account-key.json`, configured via `BigQuery.key_path`)
- **Purpose**: Provides the canonical suggestion query index (`product_analytics.query_by_division_index`), user engagement ranking data (`product_analytics.suggestion_ranking_index`), and prefix scoring data (`fs.suggest_prefix`). Data is bulk-loaded into memory at startup and refreshed daily.
- **Failure mode**: On BigQuery failure at startup or refresh, the service falls back to local CSV files (`data/suggest_queries_index.csv`, `data/suggestions_ranking_index.csv`). Prefix index falls back to an empty dict.
- **Circuit breaker**: No — exception is caught and fallback is applied.

### Groupon Division API Detail

- **Protocol**: REST — `GET https://api.groupon.com/v2/divisions.json?client_id=<REDACTED>&show=all`
- **Base URL / SDK**: `https://api.groupon.com/v2/divisions.json` (hardcoded in `app/clients/division_client.py`)
- **Auth**: `client_id` query parameter (non-secret public client ID)
- **Purpose**: Fetches all Groupon divisions with lat/lon coordinates. Used at startup to populate `DictionaryManager.gps_coordinates` for Haversine-based nearest-division resolution during suggestion requests.
- **Failure mode**: Exception is raised and logged; no fallback for GPS coordinates — the service will start with an empty GPS coordinates map if this call fails.
- **Circuit breaker**: No.

### Elastic APM Server Detail

- **Protocol**: HTTP (Elastic APM Python agent `elastic-apm[fastapi]>=6.22.0`)
- **Base URL / SDK**: Configured via `ELASTIC_APM_SERVER_URL` environment variable (e.g., `https://elastic-apm-http.logging-platform-elastic-stack-production.svc.cluster.local:8200`)
- **Auth**: Internal cluster TLS; `ELASTIC_APM_VERIFY_SERVER_CERT=false`
- **Purpose**: Distributed transaction tracing and error reporting. Transactions on `*/metrics*` and `*/healthcheck*` are excluded via `ELASTIC_APM_TRANSACTION_IGNORE_URLS`.
- **Failure mode**: APM failures are non-blocking; the service continues to serve requests.
- **Circuit breaker**: No — handled internally by the APM agent.

## Internal Dependencies

> No evidence found in codebase of direct calls to other internal Groupon microservices beyond the Groupon Division API (treated as external above).

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| MBNXT search client (`searchClient_3c1a`) | REST / HTTP | Calls `GET /suggestions` for typeahead autocomplete and `POST /query-preprocessing` for query enrichment in the search pipeline |
| Prometheus (`prometheusServer_1b6e`) | HTTP scrape | Scrapes `GET /metrics` every 60 seconds for operational metrics |

> Upstream consumers are also tracked in the central architecture model.

## Dependency Health

- **BigQuery**: No active health check. Failure is detected at load time (startup or scheduled refresh) and triggers fallback to local CSV files. BigQuery connectivity can be tested by inspecting scheduler job success metrics.
- **Groupon Division API**: No active health check. A startup failure results in an empty GPS coordinates map, degrading location-aware suggestions. Verify via the `GET /grpn/healthcheck` endpoint returning `200` does not validate this dependency.
- **Elastic APM**: Non-critical; APM agent handles its own reconnection logic.
