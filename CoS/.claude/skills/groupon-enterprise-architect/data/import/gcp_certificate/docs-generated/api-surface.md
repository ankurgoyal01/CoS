---
service: "gcp_certificate"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

The `gcp_certificate` service is a pure infrastructure-as-code (IaC) repository. It does not expose any HTTP, gRPC, or other runtime API surface. All interactions occur through:

- **Terraform/Terragrunt CLI** — operators apply infrastructure changes via `make <env>/APPLY`
- **GCP Private CA API** — downstream consumers (authorized Google Groups) call `privateca.googleapis.com` directly to request certificates using their delegated IAM permissions
- **Helper scripts** — `scripts/fetch_cert` and `scripts/issue_cert` (Bash) are provided for retrieving certificates from AWS ACM; these are not networked services

## Endpoints

> Not applicable — this service has no HTTP or RPC endpoints.

## Request/Response Patterns

> Not applicable — this service has no runtime request/response interface.

## Rate Limits

> No rate limiting configured. Rate limits are governed by GCP Private CA API quotas at the GCP project level.

## Versioning

> Not applicable — no versioned API surface exists.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The external GCP Private CA API is documented at https://cloud.google.com/certificate-authority-service/docs/reference/rest.
