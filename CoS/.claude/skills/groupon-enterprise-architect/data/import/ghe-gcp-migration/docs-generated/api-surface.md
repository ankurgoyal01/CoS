---
service: "ghe-gcp-migration"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

This repository is infrastructure-as-code only (Terraform). It provisions GCP resources but does not implement or expose any application-level API. All API access is provided by GitHub Enterprise itself once provisioned, and Terraform's own state is managed via the Terraform CLI.

## Endpoints

> No evidence found in codebase.

The `ghe-gcp-migration` Terraform project does not define any HTTP endpoints, gRPC services, or other API surfaces. GitHub Enterprise's web and API endpoints are exposed through the load balancers provisioned by this code:

| Load Balancer | Ports | Protocol | Purpose |
|---------------|-------|----------|---------|
| `http-lb` | 80 | HTTP | HTTP web traffic to Nginx backend |
| `https-lb` | 443 | HTTP(S) | HTTPS web traffic to Nginx backend |
| `custom-https-lb` | 8443 | HTTP(S) | Custom HTTPS traffic to Nginx backend |
| `github-ssh-lb` | 22, 122 | TCP | SSH access to GitHub Enterprise instance group |

These are GCP forwarding rule names. The GitHub Enterprise application API is not documented in this repository.

## Request/Response Patterns

> No evidence found in codebase.

## Rate Limits

> No evidence found in codebase.

No rate limiting is configured at the infrastructure layer.

## Versioning

> No evidence found in codebase.

## OpenAPI / Schema References

> No evidence found in codebase.
