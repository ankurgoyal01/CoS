---
service: "alligator"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["env-vars", "config-files", "vault"]
---

# Configuration

## Overview

Alligator is configured via YAML application config files loaded at startup (path controlled by the `JTIER_RUN_CONFIG` environment variable) and a small set of environment variables injected by the Raptor/Conveyor deployment system. The active Spring profile (e.g., `prod-na`, `staging`) determines which config file is loaded from `src/main/resources/config/`. Cloud-specific deployment overrides reside in `.meta/deployment/cloud/components/app/`. Secret values (Redis credentials, API keys, service authentication tokens) are injected at runtime via Vault through the JTier archetype `secret_path` mechanism defined in `.meta/.raptor.yml`.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active YAML application config file for the running environment (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`) | yes | — | helm / Raptor deployment |
| `MALLOC_ARENA_MAX` | Limits glibc memory arena count to prevent vmem explosion and OOM kills on high-core-count nodes | no | `4` | helm (common.yml) |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Disables TLS certificate verification for the Elastic APM agent in GCP production | no | `"false"` | helm (production-us-central1.yml) |
| `DEPLOYCAP_BUNDLE_ARGS` | Ruby bundler arguments passed during Capistrano-based deploy steps | no | `--path .bundle` | deploy_bot |
| `PRERELEASE` | Marks the release as a pre-release in the DeployBot promotion flow | no | `true` | deploy_bot |

> IMPORTANT: Never document actual secret values. Only variable names and purposes are listed here.

## Feature Flags

> No dedicated feature flag system (e.g., LaunchDarkly) was found in the codebase. Experiment and template bucketing is controlled through the Finch client (`com.groupon.optimize:finch:3.6.1`), which retrieves experiment assignments from the Finch service at request time. Deck-level `forced_experiments` fields stored in Redis can also pin specific experiment variant assignments for a deck.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Common Kubernetes deployment config: Docker image, default replica range (3–15), readiness/liveness probes, resource limits, port mapping (8080, 8081, 8009), logging, deploy strategy |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | GCP production US overrides: region `us-central1`, VPC `prod`, VIP, APM endpoint, replica range (5–15), CPU 600m, memory 10.5Gi |
| `.meta/deployment/cloud/components/app/production-europe-west1.yml` | YAML | GCP production EMEA overrides: region `europe-west1`, VPC `prod`, replica range (5–15), memory 10.5Gi |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | GCP staging US overrides: region `us-central1`, VPC `stable`, replica range (2–3) |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | GCP staging EMEA overrides: region `europe-west1`, VPC `stable` |
| `.meta/deployment/cloud/components/app/alpha-us-central1.yml` | YAML | Alpha (pre-staging) NA overrides |
| `.meta/deployment/cloud/components/app/alpha-europe-west1.yml` | YAML | Alpha (pre-staging) EMEA overrides |
| `.meta/deployment/cloud/components/app/beta-us-central1.yml` | YAML | Beta (canary) production NA overrides |
| `.meta/deployment/cloud/components/app/beta-europe-west1.yml` | YAML | Beta (canary) production EMEA GCP overrides |
| `.meta/deployment/cloud/components/app/beta-eu-west-1.yml` | YAML | Beta (canary) production legacy AWS EMEA overrides |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | Legacy AWS production EU-WEST-1 overrides |
| `.service.yml` | YAML | Service registry metadata: name, title, team, SRE dashboards, PagerDuty, status endpoint, on-prem colo URLs, dependency list |
| `.deploy_bot.yml` | YAML | DeployBot promotion targets: Kubernetes cluster, region, deploy command per environment |
| `doc/swagger/openapi.yaml` | YAML (OpenAPI 3.0.3) | Generated API contract specification |
| `pom.xml` | XML | Maven build configuration, dependency versions, plugin configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| Redis credentials | Authentication for `continuumAlligatorRedis` connection | vault (via JTier `secret_path` in `.meta/.raptor.yml`) |
| OpenWeather API key | Authentication for OpenWeather HTTP API calls | vault |
| Upstream service credentials | Auth tokens or client credentials for internal HTTP calls (where required) | vault |

> Secret values are NEVER documented here. Only names and purposes are listed.

## Per-Environment Overrides

| Environment | Key Differences |
|-------------|----------------|
| `alpha-us-central1` / `alpha-europe-west1` | GCP staging cluster, VPC `stable`; min 2 replicas, max 3; `JTIER_RUN_CONFIG` points to staging config file |
| `staging-us-central1` / `staging-europe-west1` | Same as alpha but with `promote_to` target configured for one-click production promotion in DeployBot |
| `beta-us-central1` / `beta-europe-west1` / `beta-eu-west-1` | Production GCP/AWS cluster with limited rollout; serves as canary before full production promotion |
| `production-us-central1` | GCP production US; VPC `prod`; min 5 replicas, max 15; Elastic APM enabled; CPU 600m; memory 10.5Gi |
| `production-europe-west1` | GCP production EMEA equivalent; min 5 replicas, max 15; memory 10.5Gi; CPU 1000m |
| `production-eu-west-1` | Legacy AWS-based production in eu-west-1 / dub1 datacenter |
| On-prem (sac1, snc1, dub1) | Legacy bare-metal JTier deployment via Capistrano; config loaded from host `env` and `colo` parameters; `sv restart jtier` to restart |
