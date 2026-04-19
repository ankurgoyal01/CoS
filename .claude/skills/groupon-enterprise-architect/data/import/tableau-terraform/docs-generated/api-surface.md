---
service: "tableau-terraform"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

`tableau-terraform` is an Infrastructure-as-Code repository and does not expose any HTTP, gRPC, or other network API surface of its own. All interactions occur through the Terraform/Terragrunt CLI against GCP APIs. The Tableau Server application that runs on the provisioned infrastructure exposes its own web UI and REST API (managed separately by Tableau), but those endpoints are not defined or owned by this repository.

## Endpoints

> Not applicable. This service provisions infrastructure and does not implement any API endpoints.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable. No rate limiting configured.

## Versioning

> Not applicable. No API versioning strategy; infrastructure is versioned through Terraform state and Git tags.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema present.
