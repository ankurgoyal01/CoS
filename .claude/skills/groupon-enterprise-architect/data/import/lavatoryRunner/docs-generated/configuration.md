---
service: "lavatoryRunner"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "ansible-vault"]
---

# Configuration

## Overview

Lavatory Runner is configured exclusively through environment variables passed to the Docker container at runtime. These are injected by the host cron script (`/opt/lavatory/lavatory_cron_job.sh`) which is deployed and managed by an Ansible playbook. Sensitive credentials (Artifactory password) are stored encrypted in an Ansible vault. No external config stores (Consul, Vault service, Helm values) are used.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ARTIFACTORY_HOST` | Hostname of the target Artifactory instance | yes | none | env (cron script) |
| `ARTIFACTORY_PORT` | Port of the target Artifactory instance | yes | none | env (cron script) |
| `ARTIFACTORY_PATH` | URL path prefix for the Artifactory API (e.g., `/artifactory`) | yes | none | env (cron script) |
| `ARTIFACTORY_USERNAME` | Username for Artifactory API authentication | yes | none | env (cron script) |
| `ARTIFACTORY_PASSWORD` | Password for Artifactory API authentication (lavatory admin user) | yes | none | ansible-vault |
| `TARGET_COLOS` | Space-separated list of Artifactory colo endpoints for multi-colo download-date checking | yes | none | env (cron script) |
| `LOCAL_COLO` | Endpoint of the local Artifactory colo for primary purge operations | yes | none | env (cron script) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are documented here.

## Feature Flags

> No evidence found in codebase. No feature flags are implemented.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `policies/docker_conveyor.py` | Python module | Retention policy for `docker-conveyor` repository (and regional variants via symlinks) |
| `policies/docker_conveyor_snapshots.py` | Python module | Retention policy for `docker-conveyor-snapshots` repository (and regional variants via symlinks) |
| `policies/X-artifacts_generic.py` | Python module | One-time GDPR cleanup policy for `artifacts-generic` (disabled — raises exception if called) |
| `policies/policy.py` | Python module | Abstract base class defining the `Policy` interface and shared AQL helper methods |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `ARTIFACTORY_PASSWORD` | Credentials for the `lavatory` Artifactory admin user | ansible-vault (encrypted in `ansible/env/*/group_vars/primary` files in the Ansible repo) |
| `artifactory/secret` GitHub repo | Artifactory Pro license file for integration test container | GitHub (access restricted to `rapt` team and `svc-dcos`) |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Lavatory Runner uses the same Docker image across all environments; per-environment differences are controlled by the environment variables injected by the Ansible-deployed cron script:

- **uat**: Cron jobs run against uat Artifactory; `ARTIFACTORY_HOST` points to uat instance.
- **staging**: Cron jobs run against staging Artifactory. Dry-run mode (`make dry-run-staging`) targets `stable-internal.us-west-2.aws.groupondev.com`.
- **production (snc1, sac1, dub1)**: Cron jobs run on a single primary `artifactory-utility` machine per colo. `TARGET_COLOS` includes all production colos for cross-colo download-date verification. The `docker-conveyor-snapshots` policy runs on schedule `0 10-15 * * 1-5` (UTC, weekdays only).
