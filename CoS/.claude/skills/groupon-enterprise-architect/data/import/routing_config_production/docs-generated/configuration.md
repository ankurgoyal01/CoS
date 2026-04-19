---
service: "routing_config_production"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "cli-flags"]
---

# Configuration

## Overview

`routing_config_production` is configured at build/deploy time through a small set of environment variables injected by the Jenkins pipeline, build-time CLI flags passed to the Python template renderer, and static Flexi DSL files committed to the repository. There is no runtime configuration store (no Consul, Vault, or Helm values are read at runtime). The compiled routing config itself is the artifact; all routing behavior is encoded in the Flexi source files.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ARTIFACT` | Full Docker image reference (e.g., `docker-conveyor.groupondev.com/routing/routing-config:production_<version>`) used during image build, push, and deployment repo update | yes | — | Jenkins pipeline (`Jenkinsfile`) |
| `DEPLOYMENT_REPO` | Name of the deployment Git repository (`routing-deployment`) cloned and updated during the deploy stage | yes | — | Jenkins pipeline (`Jenkinsfile`) |
| `GITHUB_BRANCH` | Branch name from GitHub trigger; used to determine if the build is on a releasable branch | no | falls back to `GIT_REF` | Jenkins environment |
| `GIT_REF` | Git ref from build trigger; used if `GITHUB_BRANCH` is not set | no | — | Jenkins environment |
| `GITHUB_PULL_REQUEST` | Pull request indicator; if set and not `"false"`, suppresses publish and deploy stages | no | — | Jenkins environment |

> IMPORTANT: Never document actual secret values. Only document variable names and purposes.

## Feature Flags

> No evidence found in codebase.

No feature flags are managed in this repository. Routing rule changes are gated by the pull request review process and CI validation, not by feature-flag toggles.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/applications/index.flexi` | Flexi DSL | Root manifest that includes all per-application Flexi files to form the complete routing config |
| `src/applications/*.flexi` | Flexi DSL (Jinja2-templated) | Per-application route group and destination definitions; approximately 65 files |
| `render_templates.py` | Python script | Renders all Flexi templates in `src/applications/` using Jinja2; accepts `-onprem` flag to toggle on-premises vs. cloud routing behavior |
| `build.gradle` | Groovy (Gradle) | Defines validation, bundling, SSH-based deployment, and lock/unlock tasks; configures remote app node hostnames |
| `.ci.yml` | YAML | CI environment descriptor specifying Java 1.8.0_31 and the `./gradlew validate` build command |
| `.ci/docker-compose.yml` | YAML | Docker Compose service definitions for CI test (validation) and deployment-repo update steps |
| `Pipfile` | TOML (Pipenv) | Declares Python 2.7 requirement and `jinja2==2.10` dependency for template rendering |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `svcdcos-ssh` (Jenkins credential ID) | SSH key used to clone and push to the `routing-deployment` Git repository during the deploy stage | Jenkins credentials store |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

The repository is exclusively the **production** config. A companion repository (`routing-config-staging`) manages staging routing rules. Within the production config, environment differences (on-premises vs. cloud) are handled via the `-onprem` flag passed to `render_templates.py`, which controls Jinja2 template variables before DSL compilation. Kubernetes deployment targets are split across four regional overlays in the `routing-deployment` repository:

- `overlays/routing-service-production-us-west-1`
- `overlays/routing-service-production-eu-west-1`
- `overlays/routing-service-production-us-central1`
- `overlays/routing-service-production-europe-west1`

On-premises deployment targets are the `routing-app[1-10]` nodes in `snc1`, `sac1`, and `dub1` (Dublin) data centers.
