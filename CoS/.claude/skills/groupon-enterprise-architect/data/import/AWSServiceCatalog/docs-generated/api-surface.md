---
service: "aws-service-catalog"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

AWSServiceCatalog is a pure Infrastructure-as-Code service. It does not expose any HTTP endpoints, REST APIs, gRPC services, or other network interfaces of its own. All interactions with the service are conducted through:

1. **AWS CloudFormation stacks** — operators run `aws cloudformation create-stack` / `update-stack` commands targeting the `ServiceCatalog-ConveyorCloud-{stage}` and `ServiceCatalog-Community-{stage}` stacks directly via the AWS CLI.
2. **AWS Service Catalog API** — end users provision products through the AWS Service Catalog console or API in their destination accounts; this is an AWS-managed interface, not owned by this repository.
3. **S3 bucket** — product templates are uploaded to `grpn-prod-cloudcore-service-catalog` and referenced by URL in portfolio stacks.

No rate limits, OpenAPI specs, or versioning strategies apply to this service directly.

## Endpoints

> No evidence found in codebase.

This service does not own any HTTP endpoints.

## Request/Response Patterns

### Common headers

> Not applicable — no HTTP API.

### Error format

> Not applicable — no HTTP API.

### Pagination

> Not applicable — no HTTP API.

## Rate Limits

> No rate limiting configured.

## Versioning

Product template versioning is managed via `VERSION` files in each template directory (e.g., `templates/products/ConveyorCloud/s3-with-iam-role-access/VERSION` currently at `v1.11`, `templates/products/ConveyorCloud/opensearch/VERSION` currently at `v0.13`). Each new version is uploaded to S3 with the version number appended to the filename (e.g., `template-v1.11.yaml`) and referenced in the portfolio CloudFormation template as a new `ProvisioningArtifactParameters` entry.

## OpenAPI / Schema References

> No evidence found in codebase.

No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The compliance schema for CloudFormation templates is defined in `cfn-guard/rules/guard_rules.guard`.
