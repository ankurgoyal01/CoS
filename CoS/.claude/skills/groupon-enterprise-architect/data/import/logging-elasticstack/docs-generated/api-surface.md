---
service: "logging-elasticstack"
title: API Surface
generated: "2026-03-02T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [basic-auth, oauth2]
---

# API Surface

## Overview

The Logging Elastic Stack exposes two REST APIs: the Elasticsearch REST API for index and document management (used by automation scripts and internal tooling) and the Kibana REST API for configuration management (used by onboarding automation). The Kibana web UI is the primary interface for engineers querying logs. Both APIs are internal-facing and not exposed to external consumers.

## Endpoints

### Elasticsearch REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET / PUT | `/_ilm/policy` | Read or create/update Index Lifecycle Management policies | Basic Auth |
| GET / POST | `/<index>/_search` | Search log documents within a named index | Basic Auth |
| GET / PUT | `/<index>/_mapping` | Read or set index field mappings | Basic Auth |
| PUT | `/_index_template/<template>` | Create or update index templates for new sourcetypes | Basic Auth |
| PUT | `/_snapshot/<repository>` | Register or update S3 snapshot repository | Basic Auth |
| POST | `/_snapshot/<repository>/<snapshot>` | Trigger manual snapshot to AWS S3 | Basic Auth |

### Kibana REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST / PUT | `/api/data_views/data_view` | Create or update Kibana data views for new sourcetypes | Okta OAuth |
| GET / POST | `/api/saved_objects` | Manage Kibana saved objects (dashboards, visualizations) | Okta OAuth |
| GET | `/api/status` | Kibana health status check | Okta OAuth |

### Kibana Web UI

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `:5601/login` | Engineer login entry point | Okta SSO |
| GET | `:5601/app/discover` | Ad-hoc log search via KQL or Lucene | Okta SSO |
| GET | `:5601/app/dashboards` | Pre-built operational dashboards | Okta SSO |

## Request/Response Patterns

### Common headers

- `Content-Type: application/json` — required for all write operations to Elasticsearch and Kibana REST APIs
- `Authorization: Basic <base64>` — Elasticsearch API authentication via `elasticsearch_auth.yml` credentials
- `kbn-xsrf: true` — required header for all mutating Kibana API requests

### Error format

Elasticsearch returns standard JSON error responses:
```json
{
  "error": {
    "type": "<error_type>",
    "reason": "<human-readable reason>"
  },
  "status": <http_status_code>
}
```

### Pagination

Elasticsearch search results use `from` / `size` parameters for offset pagination, and `search_after` for deep pagination of time-sorted log data.

## Rate Limits

> No rate limiting configured. Access is controlled via cluster-level authentication only.

## Versioning

No API versioning strategy is applied. Elasticsearch API compatibility is managed via the pinned client version (`elasticsearch` Python client 7.17.6 matching the cluster version). Kibana API paths are version-stable across the deployed Kibana release.

## OpenAPI / Schema References

> No evidence found in codebase. Elasticsearch API is documented by Elastic at https://www.elastic.co/guide/en/elasticsearch/reference/7.17/rest-apis.html
