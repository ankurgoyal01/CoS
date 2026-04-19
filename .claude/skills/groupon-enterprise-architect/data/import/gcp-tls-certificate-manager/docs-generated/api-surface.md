---
service: "gcp-tls-certificate-manager"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: []
auth_mechanisms: []
---

# API Surface

## Overview

> No evidence found in codebase.

This service exposes no HTTP endpoints, gRPC services, GraphQL API, or any other synchronous API surface. It is a pipeline-only service with no long-running server component. All interaction with this service occurs through:

1. **Git commits** — teams submit certificate requests by committing JSON files to the `requests/` directory and merging via Pull Request to the `main` branch.
2. **DeployBot UI / ARQ** — deployment authorization is performed via the DeployBot web interface at `https://deploybot.groupondev.com/dnd-gcp-migration-infra/gcp-tls-certificate-manager` and ARQ at `https://arq.groupondev.com/ra/ad_subservices/gcp-tls-certificate-manager`.
3. **GCP Secret Manager** — downstream consumers read provisioned TLS material from GCP Secret Manager secrets named `tls--{org}-{service}` (or `tls--{org}-{service}-legacy` for legacy mTLS).

## Endpoints

> Not applicable — this service has no HTTP or RPC endpoints.

## Request/Response Patterns

### Certificate request file format

Certificate requests are JSON files placed in the `requests/` directory. They follow this schema:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `org` | string | yes | Organization name; used in secret name and CN generation |
| `service` | string | yes | Service name; used in secret name and CN generation |
| `cntype` | string | no | Set to `"legacy"` to also generate a legacy mTLS certificate for AWS ACM |
| `environments` | object | yes | Map of environment names (`dev`, `staging`, `production`) to environment configs |
| `environments.{env}.project_id` | string | yes | GCP project ID for the target environment |
| `environments.{env}.accessors` | array | yes | List of GCP principal identifiers granted Secret Manager read access |
| `seq` | number | no | Optional integer to force certificate regeneration without other changes |

### Secret output format

The provisioned GCP Secret Manager secret contains a JSON object:

```json
{
  "certificate": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
  "key": "-----BEGIN RSA PRIVATE KEY-----...-----END RSA PRIVATE KEY-----",
  "certificate_chain": "-----BEGIN CERTIFICATE-----...-----END CERTIFICATE-----",
  "environment": "dev|staging|production"
}
```

### Secret naming convention

- Standard TLS: `tls--{org}-{service}` (e.g., `tls--seo-seo-deal-redirect`)
- Legacy mTLS: `tls--{org}-{service}-legacy`

### Certificate CN naming convention

- Standard TLS (Hybrid Boundary): `{environment}/{service}` (e.g., `staging/best-service`)
- Legacy mTLS (AWS ACM): `{service}.{environment}.service`

## Rate Limits

> Not applicable — no API surface is exposed.

## Versioning

> Not applicable — no API surface is exposed. Certificate request schema changes are handled via git commits and Pull Requests.

## OpenAPI / Schema References

> No OpenAPI spec, proto files, or GraphQL schema exist in this repository. The certificate request JSON schema is documented in `README.md` and `owners_manual.md`.
