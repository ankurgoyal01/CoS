---
service: "netops_awsinfra"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`netops_awsinfra` is a pure infrastructure-as-code repository. It does not expose any HTTP endpoints, gRPC services, GraphQL APIs, or message-based consumer interfaces. All interactions occur through the AWS API via Terraform/Terragrunt plan and apply operations executed by engineers or CI pipelines.

The Makefile wraps Terragrunt and exposes the following operator-facing commands (not network endpoints):

| Make Target Pattern | Action |
|--------------------|--------|
| `make <account>/<region>/<module>/plan` | Runs `terragrunt run-all plan` against the specified path |
| `make <account>/<region>/<module>/APPLY` | Runs `terragrunt run-all apply` against the specified path (capitalized = destructive-safe gate) |
| `make <account>/<region>/<module>/DESTROY-ALL` | Runs `terragrunt run-all destroy` with interactive confirmation |
| `make <account>/<region>/<module>/validate` | Runs `terragrunt run-all validate` |

## Endpoints

> Not applicable — this service does not expose network endpoints.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable — AWS API rate limits apply at the provider level, not at this service level.

## Versioning

> Not applicable — infrastructure modules are versioned via Git tags and referenced by path in `terragrunt.hcl` source blocks.

## OpenAPI / Schema References

> Not applicable — no API schema files exist in this repository.
