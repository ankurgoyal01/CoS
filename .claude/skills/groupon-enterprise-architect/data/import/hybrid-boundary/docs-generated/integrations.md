---
service: "hybrid-boundary"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 5
---

# Integrations

## Overview

Hybrid Boundary integrates with three external systems (Akamai CDN, Conveyor deployment platform, ProdCat change management) and five internal AWS-managed systems (DynamoDB, Route53, Step Functions, API Gateway, ELB). All communication is HTTPS or AWS SDK calls. There are no circuit breakers implemented; AWS SDK retries are configurable.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Akamai | HTTPS / AWS S3 | Retrieve Akamai CDN IP ranges for edge proxy allow-list maintenance | yes | `akamai` (stub) |
| Conveyor | HTTPS (internal mTLS) | Check for active cluster promotion maintenance windows before allowing API mutations | yes | Not modelled |
| ProdCat | HTTPS (internal mTLS) | Verify production change approval tickets before allowing production API mutations | yes | Not modelled |
| Service Portal | HTTPS (internal mTLS) | Validate that a service name exists in the service registry before registration | no | Not modelled |

### Akamai Detail

- **Protocol**: HTTPS — Akamai SiteShield Map API and S3 bucket storage
- **Base URL / SDK**: Akamai SiteShield Map ID `2622`; IP ranges stored in S3 bucket configured via `-akamaibucketname` flag
- **Auth**: AWS IAM role (S3 bucket access); Akamai API credentials embedded in agent configuration
- **Purpose**: Periodically fetches Akamai CDN egress IP ranges and writes them to a local ipset script file on edge proxy instances, maintaining the edge proxy allow-list
- **Failure mode**: Ipset update fails; agent logs error and increments `edgeproxy_agent_ipsetupdate_error_total`. Previous allow-list remains in place.
- **Circuit breaker**: No. AWS SDK retry configured via `-awsDefaultMaxRetries` (default 5).

### Conveyor Detail

- **Protocol**: HTTPS with Groupon root CA mTLS (`agent/lambda-api/GrouponRootCA.pem`)
- **Base URL / SDK**: `https://conveyor-cloud--maintenance.<env>.service/maintenance`
- **Auth**: Service-to-service mTLS (Groupon internal PKI)
- **Purpose**: Before any mutating API call in `gensandbox`, `staging`, or `production`, the API Lambda checks whether Conveyor is in maintenance mode. If `true`, the request is rejected with HTTP 409.
- **Failure mode**: Returns HTTP 500 if Conveyor is unreachable. Admins can override via `ConveyorMaintenanceOverride: true` in the request body.
- **Circuit breaker**: No. HTTP client timeout 20 seconds.

### ProdCat Detail

- **Protocol**: HTTPS with Groupon root CA mTLS
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-west-1.aws.groupondev.com/v1/changes/` (host rewritten to `prodcat.production.service`)
- **Auth**: Service-to-service mTLS (Groupon internal PKI)
- **Purpose**: In production environments, every mutating API call must carry a GProd ticket reference. The API Lambda submits the ticket to ProdCat for approval verification before proceeding.
- **Failure mode**: Returns HTTP 403 if ProdCat rejects the ticket. Admins can override via `ProdcatOverride: true` in the request body.
- **Circuit breaker**: No. HTTP client timeout 20 seconds.

### Service Portal Detail

- **Protocol**: HTTPS with Groupon root CA mTLS
- **Base URL / SDK**: `https://edge-proxy--production--default.prod.us-west-1.aws.groupondev.com/services.json` (host rewritten to `service-portal.production.service`)
- **Auth**: Service-to-service mTLS (Groupon internal PKI)
- **Purpose**: When creating a new service, the API Lambda validates that the service name exists in the service portal. Can be skipped via `?skipServiceNameCheck=true` query parameter.
- **Failure mode**: Returns HTTP 500 if service portal is unreachable. Can be bypassed with the query param.
- **Circuit breaker**: No. HTTP client timeout 20 seconds.

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| AWS DynamoDB | AWS SDK | Primary state store for service registry and history | `continuumHybridBoundaryServiceRegistryTable` |
| AWS Route53 | AWS SDK | DNS record management for edge proxy target discovery | `continuumHybridBoundaryDns` |
| AWS Step Functions | AWS SDK | Traffic shift workflow orchestration | `continuumHybridBoundaryStepFunctions` |
| AWS API Gateway | AWS Lambda invocation | Routes administrative API calls to the API Lambda | `continuumHybridBoundaryApiGateway` |
| AWS ELB / Target Groups | AWS SDK | Checks health state of edge proxy EC2 instances for drain detection | Not separately modelled |

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers include:
> - Platform and service teams (via API Gateway REST API)
> - Envoy proxy instances on the edge proxy fleet (via xDS gRPC on the Agent)

## Dependency Health

- AWS SDK max retries configurable via `AWS_DEFAULT_MAX_RETRIES` environment variable (default `5` per `lambda.go`; default `5` per agent `-awsDefaultMaxRetries` flag).
- Akamai ipset update runs on a 24-hour ticker (configurable via `-ipsetupdateinterval`); failures are logged and counted by `edgeproxy_agent_ipsetupdate_error_total`.
- Envoy configuration update runs on a 30-second ticker (configurable via `-pollafter`); failures are logged and counted by `edgeproxy_agent_update_error_total`.
- Agent monitors ELB target health state on each poll tick; if an instance transitions to `draining`, it calls `POST http://localhost:{envoyadminport}/healthcheck/fail` to signal Envoy to stop accepting new connections.
