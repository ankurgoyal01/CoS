---
service: "gcp-dataplex-infra"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`gcp-dataplex-infra` is a pure infrastructure-as-code repository. It does not expose any HTTP, gRPC, GraphQL, or other runtime API endpoints. All interactions occur through Terraform/Terragrunt CLI operations that call the GCP Dataplex and GCS APIs on behalf of the operator. Consumers interact with the provisioned GCP resources directly via GCP's own APIs — not through this service.

## Endpoints

> Not applicable. This service provisions GCP resources and does not expose endpoints.

## Request/Response Patterns

### Common headers

> Not applicable.

### Error format

> Not applicable.

### Pagination

> Not applicable.

## Rate Limits

> Not applicable. No runtime service is exposed.

## Versioning

> Not applicable. Infrastructure modules are versioned via git tags (e.g., `module_version` in `account.hcl`).

## OpenAPI / Schema References

> Not applicable. No API schema files are present in the repository.
