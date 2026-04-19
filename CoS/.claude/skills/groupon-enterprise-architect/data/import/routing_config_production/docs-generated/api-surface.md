---
service: "routing_config_production"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`routing_config_production` is a configuration repository, not a service that exposes an API. It does not listen on any port or serve HTTP requests directly. Its "surface" is the set of routing rules it defines, which are loaded and applied by the routing service runtime. The routing service itself exposes the hot-reload endpoint `POST localhost:9001/config/routes/reload`, but that endpoint belongs to the routing runtime, not this config repo.

For documentation of the URL patterns this config maps (i.e., the routes that Groupon's routing layer handles), see [Flows](flows/index.md) and the per-application Flexi source files under `src/applications/`.

## Endpoints

> Not applicable — this service does not expose HTTP endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable — no API is exposed.

## Versioning

> Not applicable — routing config versions are tracked via Docker image tags in the format `production_<YYYY.MM.DD_HH.MM>_<short-git-sha>`, managed by the CI pipeline.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The Flexi DSL grammar is defined by the `grout-tools-gradle` plugin (internal Groupon tooling).
