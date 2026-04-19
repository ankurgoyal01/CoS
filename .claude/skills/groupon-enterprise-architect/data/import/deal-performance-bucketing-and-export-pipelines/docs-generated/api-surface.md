---
service: "deal-performance-bucketing-and-export-pipelines"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The Deal Performance Data Pipelines service does not expose any HTTP or RPC API. It is a batch data pipeline application invoked via `spark-submit` (or Apache Airflow tasks) with command-line arguments. The pipeline produces data consumed by:

- The `deal-performance-api-v2` subservice, which exposes a REST API for querying aggregated performance data from PostgreSQL.
- Downstream Spark ranking jobs, which read bucketed Avro files from GCS.

API documentation for the REST layer is maintained in the [deal-performance-api-v2 Swagger specification](https://github.groupondev.com/Push/deal-performance-api-v2/blob/master/src/main/resources/swagger.yaml).

## Endpoints

> Not applicable. This service is invoked as a batch job, not as an HTTP server.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable.

## Versioning

> Not applicable.

## OpenAPI / Schema References

- Avro schema for bucketed output: `src/main/resources/schema/DealPerformance.avsc`
- Avro schema for deal option performance: `src/main/resources/schema/DealOptionPerformance.avsc`
- REST API Swagger (in separate subservice repo): `https://github.groupondev.com/Push/deal-performance-api-v2/blob/master/src/main/resources/swagger.yaml`
