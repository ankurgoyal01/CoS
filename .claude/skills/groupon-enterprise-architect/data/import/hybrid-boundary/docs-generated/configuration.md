---
service: "hybrid-boundary"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, cli-flags, config-files, vault]
---

# Configuration

## Overview

The Hybrid Boundary Agent (`continuumHybridBoundaryAgent`) is configured entirely via CLI flags passed at process startup. The API Lambda (`continuumHybridBoundaryLambdaApi`) is configured via environment variables injected by the Lambda execution environment. Python tooling and Terraform are configured via YAML config files under `configs/`. Encrypted secrets (credentials, GPG keys) are managed via git-crypt and Jenkins credentials.

## Environment Variables

### API Lambda (`continuumHybridBoundaryLambdaApi`)

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `STATE_MACHINE_ARN` | ARN of the AWS Step Functions state machine for shift workflows | yes | none | env / Lambda config |
| `ENV` | Deployment environment name (e.g. `production`, `staging`, `gensandbox`) | yes | none | env / Lambda config |
| `REGION` | AWS region (e.g. `eu-west-1`) | yes | none | env / Lambda config |
| `JWKS_URL` | URL of the JWKS endpoint for JWT public key retrieval | yes | none | env / Lambda config |
| `JWT_ISSUER` | Expected JWT issuer claim | yes | none | env / Lambda config |
| `JWT_AUDIENCE` | Comma-separated list of expected JWT audience claims | yes | none | env / Lambda config |
| `DEFAULT_ADMINS` | Comma-separated list of group names granted admin privileges | yes | none | env / Lambda config |
| `AWS_DEFAULT_MAX_RETRIES` | Maximum number of times AWS SDK requests will be retried | no | `5` | env / Lambda config |

### CI / Jenkins

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GPG_PASSPHRASE` | Passphrase for the headless GPG key used to decrypt git-crypt secrets | yes | none | Jenkins credentials |
| `AWS_REGION` | AWS region for CI operations | yes | `eu-west-1` | Jenkinsfile |
| `EDGE_PROXY_AGENT_VERSION` | Git commit SHA used as the agent version | yes | `${env.GIT_COMMIT}` | Jenkinsfile |
| `TF_VAR_git_revision` | Terraform variable for the git revision to bake into AMI | yes | `${env.GIT_COMMIT}` | Jenkinsfile |

## CLI Flags (Agent)

| Flag | Purpose | Required | Default |
|------|---------|----------|---------|
| `-env` | Environment name for this agent instance | yes | — |
| `-region` | AWS region for this instance | yes | — |
| `-namespace` | Namespace for service registration scoping | yes | — |
| `-cluster` | Cluster name for this instance | yes | — |
| `-instanceid` | EC2 instance ID | yes | — |
| `-pollafter` | Polling interval for DynamoDB service registry | no | `30s` |
| `-maxstreams` | Maximum concurrent gRPC streams to Envoy | no | `10000` |
| `-listenaddr` | Address for the Envoy gRPC server | no | `localhost:7000` |
| `-adminlistenaddr` | Address for the admin HTTP server (metrics/config) | no | `localhost:7001` |
| `-peercert` | Path to the mTLS peer certificate | yes | — |
| `-peercertkey` | Path to the mTLS peer certificate private key | yes | — |
| `-rootcert` | Path to the root CA certificate (skipped in sandbox) | yes | — |
| `-ipsetupdateinterval` | Interval for Akamai IP range refresh | no | `24h` |
| `-ipsetfilepath` | Path where the generated ipset script is written | yes | — |
| `-envoyadminport` | Envoy admin port for health check signalling | no | `9901` |
| `-akamaibucketname` | S3 bucket name for Akamai IP range storage | yes | — |
| `-targetgrouparn` | ARN of the ELB target group this instance is attached to | yes | — |
| `-jwtissuer` | JWT issuer for xDS stream authentication | yes | — |
| `-jwtaudiences` | Comma-separated JWT audiences for xDS stream authentication | yes | — |
| `-jwksurl` | JWKS URL for xDS JWT validation | yes | — |
| `-awsDefaultMaxRetries` | Maximum AWS SDK retry attempts | no | `5` |

## Feature Flags

> No evidence found in codebase. Feature behaviour is controlled via environment variable values rather than discrete feature flags.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `configs/*/*/*.yml` | YAML | Per-environment service routing configuration; validated by `bin/config.py validate` in CI |
| `Pipfile` | TOML | Python dependency declaration for tooling |
| `go.mod` | Go modules | Go dependency manifest |
| `agent/.air.toml` | TOML | Live reload configuration for local agent development |
| `packer/` | JSON/HCL | Packer AMI bake configuration for edge proxy instances |
| `terraform/` | HCL | Infrastructure-as-code for all AWS resources |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `GPG_PASSPHRASE` | Decrypts git-crypt–managed credentials in the repository | Jenkins credentials store |
| `credentials/gpg_private.key` | GPG private key for git-crypt unlock | git-crypt (encrypted in repo) |
| AWS IAM role credentials | Agent and Lambda AWS API access | AWS IAM instance role / Lambda execution role |
| `JWKS_URL` target credentials | Public keys for JWT validation | JWKS endpoint (no stored secret) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Sandbox (`gensandbox`, `consandbox`)**: Root certificate validation is skipped in the agent (sandbox environments detected by checking that `env` contains the string `sandbox`). Conveyor maintenance checks apply only to `gensandbox us-west-2`.
- **Staging**: Conveyor maintenance checks apply. ProdCat approval is not required.
- **Production**: Both Conveyor maintenance and ProdCat approval checks apply. Admins with the correct group membership can override both via request body flags.
- **DynamoDB table prefix**: All environments use `edge-proxy.<env>` as the table prefix, providing isolation without separate accounts for non-production tiers.
- **AMI regions**: CI bakes AMIs in `eu-west-1` staging and copies to production. Deployment tag format `<environment>-<region>-<timestamp>` controls which environment and region receives the apply.
