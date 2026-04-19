---
service: "afl-rta"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, config-files, k8s-secret]
---

# Configuration

## Overview

AFL RTA is configured through a combination of environment variables and YAML configuration files following the JTier Dropwizard convention. The active configuration file is selected at runtime via the `JTIER_RUN_CONFIG` environment variable, which points to an environment-specific YAML file bundled in the container image. Secrets (database credentials, Kafka TLS certificates, MBus credentials) are injected via Kubernetes secrets. No Consul or Vault integration is explicitly visible in this repository.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `JTIER_RUN_CONFIG` | Path to the active Dropwizard configuration YAML file | yes | — | helm / env-vars |
| `DEPLOY_SERVICE` | Service identifier injected by Kubernetes deployment template | yes | `afl-rta` | k8s deployment template |
| `DEPLOY_COMPONENT` | Component identifier (`app`) | yes | `app` | k8s deployment template |
| `DEPLOY_INSTANCE` | Deployment instance name (`default`) | yes | `default` | k8s deployment template |
| `DEPLOY_ENV` | Deployment environment name (`staging`, `production`) | yes | — | k8s deployment template |
| `DEPLOY_NAMESPACE` | Kubernetes namespace; injected from pod metadata | yes | — | k8s fieldRef |
| `TELEGRAF_METRICS_ATOM` | Current git SHA for metrics tagging | yes | — | k8s deployment template |
| `TELEGRAF_URL` | Wavefront Telegraf endpoint for metrics shipping | yes | — | k8s deployment template |
| `KAFKA_ENDPOINT` | Kafka broker endpoint for Filebeat log shipping | yes | — | k8s deployment template (Filebeat sidecar) |
| `REGION` | GCP region, injected for Filebeat log routing | yes | — | k8s deployment template (Filebeat sidecar) |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

> No evidence found of feature flags or dynamic flag configuration in this repository.

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/app/common.yml` | YAML | Shared deployment configuration: image, ports, logging, health check, base scaling |
| `.meta/deployment/cloud/components/app/production-us-central1.yml` | YAML | Production GCP us-central1 overrides: scaling (2–10 replicas), resource requests, VIP, APM enabled |
| `.meta/deployment/cloud/components/app/staging-us-central1.yml` | YAML | Staging GCP us-central1 overrides: scaling (1–2 replicas), resource requests, VIP, APM disabled |
| `.meta/deployment/cloud/components/app/template/config/framework-defaults.yml` | YAML | JTier CMF framework defaults for probes, HPA, resource limits, log paths |
| `.meta/deployment/cloud/components/app/template/deployment.yml.erb` | ERB/YAML | Kubernetes Deployment manifest template |
| `.meta/deployment/cloud/components/app/template/hpa.yml.erb` | ERB/YAML | Kubernetes HorizontalPodAutoscaler manifest template |
| `docker/docker-compose.yml` | YAML | Local development MySQL instance |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `afl-rta--app--default--<secretName>` | Application secrets (DB credentials, MBus credentials, Kafka auth) injected as Kubernetes Secret env vars | k8s-secret |
| `<namespace>-tls-identity` | Kafka TLS client certificate for mutual TLS authentication with Kafka brokers; mounted at `/var/groupon/certs` | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies. Secret path base: `.meta/deployment/cloud/secrets` (git submodule, per `.meta/.raptor.yml`).

## Per-Environment Overrides

- **Staging** (`staging-us-central1`): `JTIER_RUN_CONFIG` points to `staging-us-central1.yml`; 1–2 replicas; lower CPU requests (15m main); VIP `afl-rta.us-central1.conveyor.stable.gcp.groupondev.com`; APM disabled; Filebeat low-volume storage
- **Production** (`production-us-central1`): `JTIER_RUN_CONFIG` points to `production-us-central1.yml`; 2–10 replicas; higher CPU requests (155m main); VPA enabled; VIP `afl-rta.us-central1.conveyor.prod.gcp.groupondev.com`; APM enabled; Filebeat medium-volume storage
- **Memory limits** (both environments): main container 750 Mi request / 2 Gi limit
- **Health check port**: `8080` (both environments); probe path `/grpn/healthcheck`
- **Admin port**: `8081` exposed as `admin-port` on the Kubernetes service
