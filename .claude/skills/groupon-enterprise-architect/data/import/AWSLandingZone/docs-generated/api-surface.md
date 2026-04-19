---
service: "aws-landing-zone"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

AWS Landing Zone does not expose any HTTP/gRPC/GraphQL service endpoints. It is an infrastructure delivery system, not a runtime service. There are no REST APIs, no service ports, and no network-accessible endpoints.

The "interface" to the Landing Zone is the GitHub pull request process: engineers open a PR to request new IAM roles, VPC resources, or DNS records; the Cloud Core team reviews and merges; the Jenkins pipeline applies the change.

Operational scripts (in `bin/`) are CLI tools invoked directly by engineers with AWS credentials; they do not expose any service endpoints.

## Endpoints

> Not applicable — this service exposes no network endpoints.

## Request/Response Patterns

> Not applicable.

## Rate Limits

> Not applicable — no API is exposed.

## Versioning

> Not applicable.

## OpenAPI / Schema References

> Not applicable — no API schema exists for this service.
