---
service: "ultron-api"
title: API Surface
generated: "2026-03-03T00:00:00Z"
type: api-surface
protocols: [rest]
auth_mechanisms: [session]
---

# API Surface

## Overview

ultron-api exposes HTTP REST endpoints implemented as Play Framework controllers. The API serves two consumer types: programmatic job runner clients (which register job runs, instances, and watermarks) and human operators (who use the built-in HTML UI to view and manage jobs, resources, groups, and permissions). All controllers feed into a shared Repository Layer backed by Slick for database access.

## Endpoints

### Health and System

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/health` | Service health check | None |
| GET | `/evolutions` | Database schema evolution status | Internal |

### Job Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/jobs` | List all job definitions | Session |
| GET | `/jobs/:id` | Get job definition by ID | Session |
| POST | `/jobs` | Create a new job definition | Session |
| PUT | `/jobs/:id` | Update a job definition | Session |
| DELETE | `/jobs/:id` | Delete a job definition | Session |

### Job Instance Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/job-instances` | Query job instance history | Session |
| GET | `/job-instances/:id` | Get a specific job instance | Session |
| POST | `/job-instances` | Register a new job instance run | Session / API key |
| PUT | `/job-instances/:id` | Update job instance state | Session / API key |

### Resource Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/resources` | List registered resources | Session |
| POST | `/resources` | Register a resource | Session |
| GET | `/resource-types` | List resource types | Session |
| POST | `/resource-types` | Register a resource type | Session |
| GET | `/resource-locations` | List resource locations | Session |
| POST | `/resource-locations` | Register a resource location | Session |

### Group, User, and Permission Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/groups` | List groups | Session |
| POST | `/groups` | Create group | Session |
| GET | `/users` | List users | Session |
| POST | `/users` | Create user | Session |
| POST | `/memberships` | Add user to group | Session |

### Team Management

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/teams` | List teams | Session |
| POST | `/teams` | Create team | Session |
| PUT | `/teams/:id` | Update team | Session |
| DELETE | `/teams/:id` | Delete team | Session |

### Watchdog and Status

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/status` | Service and dependency status | Session |
| GET | `/watchdog` | Watchdog job health summary | Session |

### Data Dictionary and Lineage

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `/data-dictionary` | Resource lineage and data dictionary | Session |
| GET | `/lineage/:resourceId` | Lineage graph for a specific resource | Session |

> Exact route paths are inferred from the Play controller component names in `architecture/models/components/ultronApi.dsl`. Verify against the service's Play routes file.

## Request/Response Patterns

### Common headers

- Standard Play Framework session cookie for UI authentication
- JSON `Content-Type: application/json` for API consumers (job runner clients)

### Error format

> No evidence found in codebase. Play Framework standard error responses; JSON body for API errors, HTML for UI errors.

### Pagination

> No evidence found in codebase. Pagination patterns to be confirmed against the service routes file.

## Rate Limits

> No rate limiting configured. Rate limiting managed at the infrastructure / load balancer layer.

## Versioning

No explicit versioning strategy in the architecture model. Play routes are not versioned by path prefix. Updates deployed as in-place replacements.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec or proto files are present in the federated architecture module.
