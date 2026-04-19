---
service: "aws-transfer-for-sftp"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [sftp]
auth_mechanisms: [ssh-key, service-managed-iam]
---

# API Surface

## Overview

AWS Transfer for SFTP does not expose an HTTP/REST API. The only consumer-facing interface is the SFTP protocol (SSH File Transfer Protocol, typically port 22) provided by the AWS Transfer Family managed endpoint. Clients authenticate using SSH keys managed by AWS Transfer (identity provider type: `SERVICE_MANAGED`). Each authenticated user is mapped to an IAM role that scopes their access to a specific S3 bucket home directory. There is no versioning, pagination, or rate-limit configuration discoverable in the codebase; those characteristics are managed by AWS Transfer Family service limits.

## Endpoints

### SFTP Transfer Endpoint

| Protocol | Endpoint | Purpose | Auth |
|----------|----------|---------|------|
| SFTP (SSH) | AWS Transfer Family server endpoint (DNS assigned by AWS at server creation) | Secure file upload and download for authorised SFTP users | SSH key pair; IAM role assumed via `transfer.amazonaws.com` principal |

> The concrete DNS hostname of the SFTP endpoint is assigned by AWS at server creation time and is not hardcoded in this repository. It is available in the AWS Console or via `aws transfer describe-server`.

## Request/Response Patterns

### Common headers

> Not applicable. SFTP is a binary protocol; HTTP headers do not apply.

### Error format

> Not applicable. SFTP uses SSH protocol-level error codes (e.g., `SSH_FX_PERMISSION_DENIED`, `SSH_FX_NO_SUCH_FILE`). Errors are surfaced to the SFTP client and logged to CloudWatch Logs under `/aws/transfer/<server-id>`.

### Pagination

> Not applicable. Directory listing and file transfer are handled natively by the SFTP client.

## Rate Limits

> No rate limiting configured in this repository. AWS Transfer Family service quotas (e.g., concurrent sessions, throughput) apply at the AWS account level.

## Versioning

> Not applicable. SFTP protocol versioning is handled by the AWS Transfer Family managed service. There is no application-level API versioning in this repository.

## OpenAPI / Schema References

> No evidence found in codebase. This service uses the SFTP binary protocol; no OpenAPI, proto, or GraphQL schema exists.
