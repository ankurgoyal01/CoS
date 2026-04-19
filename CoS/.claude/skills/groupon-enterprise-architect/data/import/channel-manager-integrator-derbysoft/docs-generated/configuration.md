---
service: "channel-manager-integrator-derbysoft"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secrets]
---

# Configuration

## Overview

The service is configured via JTier YAML config files selected at runtime by the `JTIER_RUN_CONFIG` environment variable. Kubernetes deployment overlays provide per-environment YAML paths and non-secret environment variables. Secrets (database credentials, Derbysoft auth header, Kafka TLS keystores) are stored in Kubernetes secrets and injected at runtime. Non-secret runtime tuning values (e.g., `MALLOC_ARENA_MAX`) are set via Kubernetes `envVars` in the deployment manifests.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Selects the environment-specific YAML config file path (e.g., `/var/groupon/jtier/config/cloud/production-us-central1.yml`) | yes | None | helm / k8s deployment manifest |
| `MALLOC_ARENA_MAX` | Caps glibc malloc arenas to prevent virtual memory explosion in containers | no | `4` | `.meta/deployment/cloud/components/app/common.yml` |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | Controls whether the APM agent verifies the server TLS certificate (set to `"false"` in non-production to accommodate self-signed certs) | no | `"true"` | `.meta/deployment/cloud/components/app/production-us-central1.yml`, `staging-us-central1.yml` |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `kafkaConfig.enabled` | Enables or disables the Kafka ARI message producer. When `false`, the producer is not initialized and ARI payloads are not forwarded to Kafka. | `true` (expected; disabled returns no-op producer) | global |
| `kafkaConfig.tlsEnabled` | Controls whether TLS mutual authentication is used for Kafka connections | `true` in production | global |
| `kafkaConfig.useHotelIdAsKafkaPartionKey` | Uses the hotel ID as the Kafka partition key for ARI messages to preserve ordering per hotel | configurable | global |
| `mbusConfiguration.iswBookingMessageListenerConfig.isActive` | Enables or disables the ISW booking MBus listener | `true` | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `src/main/resources/config/development.yml` | YAML | Local development configuration (referenced by `development.yml` at repo root) |
| `/var/groupon/jtier/config/cloud/production-us-central1.yml` | YAML | GCP us-central1 production runtime configuration (injected via Kubernetes volume) |
| `/var/groupon/jtier/config/cloud/production-eu-west-1.yml` | YAML | AWS eu-west-1 production runtime configuration |
| `/var/groupon/jtier/config/cloud/staging-us-central1.yml` | YAML | GCP us-central1 staging runtime configuration |
| `/var/groupon/jtier/config/cloud/staging-europe-west1.yml` | YAML | GCP europe-west1 staging runtime configuration |
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared Kubernetes deployment config (replicas, ports, resources, log config) |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | GCP production Kubernetes overlay (replicas, CPU, probes, APM) |
| `.meta/deployment/cloud/components/app/production-eu-west-1.yml` | YAML | AWS production Kubernetes overlay |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | GCP staging Kubernetes overlay |
| `.meta/deployment/cloud/components/app/staging-europe-west1.yml` | YAML | GCP staging EMEA Kubernetes overlay |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `derbysoftAuthenticationConfig.authorizationHeaderValue` | Authorization header value used to authenticate inbound requests from Derbysoft; also used as credential for outbound calls | k8s-secret (`.meta/deployment/cloud/secrets`) |
| `postgres.*` (host, port, username, password) | PostgreSQL connection credentials | k8s-secret |
| `kafkaConfig.keystorePassword` | Kafka TLS keystore password | k8s-secret |
| `kafkaConfig.keyPassword` | Kafka TLS key password | k8s-secret |
| `kafkaConfig.truststorePassword` | Kafka TLS truststore password | k8s-secret |
| Elastic APM credentials | APM agent authentication for production/staging APM endpoints | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

| Setting | Development | Staging | Production (US) | Production (EU) |
|---------|-------------|---------|-----------------|-----------------|
| `JTIER_RUN_CONFIG` | `development.yml` | `staging-us-central1.yml` / `staging-europe-west1.yml` | `production-us-central1.yml` | `production-eu-west-1.yml` |
| Min replicas | 1 (local) | 1 | 2 (US), 1 (EU) | — |
| Max replicas | — | 2 | 15 | 5 |
| CPU request (main) | — | — | 1000m | 1000m |
| Memory request/limit | — | — | 1700Mi / 2000Mi | (common.yml) |
| APM enabled | no | yes (staging endpoint) | yes (production endpoint) | no |
| `ELASTIC_APM_VERIFY_SERVER_CERT` | — | `"false"` | `"false"` | — |
| Kafka | Plaintext (bitnami/kafka:3.3 container) | TLS | TLS | TLS |
