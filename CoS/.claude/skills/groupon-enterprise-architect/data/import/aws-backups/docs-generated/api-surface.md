---
service: "aws-backups"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

aws-backups is a Terraform infrastructure service with no HTTP API, gRPC interface, or user-facing network endpoints. All interaction occurs through the Terraform/Terragrunt CLI (`make plan` / `make APPLY`) operating against the AWS APIs that Terraform manages on behalf of operators. The status endpoint is explicitly disabled (`status_endpoint.disabled: true` in `.service.yml`).

## Endpoints

> Not applicable. This service exposes no HTTP, gRPC, or other network endpoints. Operators interact through the Terraform CLI and the AWS Console (read-only access via the `grpn-all-general-ro-backup` IAM role in production accounts).

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No API versioning strategy exists. Terraform module versions are pinned via the `module-ref` script and per-environment `.terraform-version` files.

## OpenAPI / Schema References

> Not applicable. No API schema files exist in this repository.
