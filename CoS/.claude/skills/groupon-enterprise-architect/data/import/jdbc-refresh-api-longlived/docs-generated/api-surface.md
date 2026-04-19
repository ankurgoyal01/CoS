---
service: "jdbc-refresh-api-longlived"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [jdbc, https, hive-thrift-http]
auth_mechanisms: [knox-ldap, ranger-policy]
---

# API Surface

## Overview

This service does not expose HTTP REST endpoints directly. The externally accessible API surface is provided by the Apache Knox gateway running on the proxy clusters. Knox front-doors JDBC connections and Hive Thrift HTTP connections from clients (BI tools, programmatic clients, Refresh API callers) and forwards them to the backend Dataproc clusters. Authorization decisions are enforced by Apache Ranger, which reads policies from the Cloud SQL for MySQL Ranger database.

## Endpoints

### Apache Knox JDBC / HiveServer2 Endpoints

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| TCP (JDBC) | Knox topology port (cluster-specific) | JDBC connections from BI tools and programmatic clients to HiveServer2 | Knox LDAP PAM |
| HTTP | `cliservice` (Hive Thrift HTTP path) | HiveServer2 Thrift HTTP transport on port `10000` | Knox LDAP PAM |

### Hive Server2 Configuration (Backend Clusters)

The backend clusters expose HiveServer2 with the following fixed properties (set via Terraform `override_properties`):

| Property | Value | Purpose |
|----------|-------|---------|
| `hive.server2.thrift.http.port` | `10000` | HiveServer2 HTTP port |
| `hive.server2.thrift.http.path` | `cliservice` | HiveServer2 HTTP endpoint path |
| `hive.server2.transport.mode` | `http` | Transport mode for Thrift connections |
| `hive.server2.enable.doAs` | `true` | Impersonation — queries run as the connecting user |
| `hive.server2.allow.user.substitution` | `true` | Allows user substitution for proxy access |
| `hive.server2.thrift.max.worker.threads` | `5000` | Maximum concurrent worker threads |
| `hive.server2.session.check.interval` | `3h` | Session check interval |
| `hive.server2.idle.session.timeout` | `1d` | Idle session timeout |

### YARN ResourceManager REST API

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET, HEAD, PUT | YARN ResourceManager web UI | Application management via REST API | Internal only |

> Note: `yarn.resourcemanager.webapp.methods-allowed` is restricted to `GET,HEAD,PUT` — DELETE is not permitted.

## Request/Response Patterns

### Common headers

> Not applicable. This service exposes JDBC/Thrift protocol endpoints via Knox, not HTTP REST APIs.

### Error format

> Not applicable. Error responses follow HiveServer2 Thrift exception semantics. Knox forwards Hive error codes to JDBC clients.

### Pagination

> Not applicable. Pagination is handled at the JDBC ResultSet / HiveServer2 cursor level, not at a REST API layer.

## Rate Limits

> No rate limiting configured at the Knox or HiveServer2 layer. YARN autoscaling manages compute resource availability; back-off is the client's responsibility per the SLA definition.

## Versioning

> No API versioning scheme. The Knox topology version is tied to the Dataproc image version (`1.5-debian10`). Changes to Knox topology templates are deployed via Terraform init-action script updates.

## OpenAPI / Schema References

> No evidence found in codebase. There is no OpenAPI spec or proto file — the protocol contract is HiveServer2 Thrift and standard JDBC driver semantics.
