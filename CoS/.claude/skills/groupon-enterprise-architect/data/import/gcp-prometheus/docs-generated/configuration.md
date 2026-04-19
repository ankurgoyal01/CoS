---
service: "gcp-prometheus"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: [env-vars, helm-values, k8s-secrets, k8s-configmaps]
---

# Configuration

## Overview

`gcp-prometheus` is configured through a combination of Kubernetes environment variables (injected from Secrets and field references), Helm values files per environment, and Kubernetes ConfigMaps. Sensitive values (GCS credentials, Grafana admin credentials, Okta secrets, Kafka TLS certs) are stored in Kubernetes Secrets. Non-sensitive environment-specific parameters (region, replica counts, resource requests) are specified in Helm values YAML files under `.meta/deployment/cloud/components/thanos-stack/`.

## Environment Variables

### Thanos Receive

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OBJSTORE_CONFIG` | GCS bucket configuration for block storage | yes | — | k8s-secret `thanos-objectstorage` key `thanos.yaml` |
| `NAME` | Pod name used as Thanos Receive replica label | yes | — | `metadata.name` field ref |
| `NAMESPACE` | Kubernetes namespace for hashring endpoint resolution | yes | — | `metadata.namespace` field ref |
| `HOST_IP_ADDRESS` | Host node IP for local endpoint advertisement | yes | — | `status.hostIP` field ref |

### Thanos Query

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `HOST_IP_ADDRESS` | Host node IP for tracing/logging | no | — | `status.hostIP` field ref |

### Thanos Store Gateway

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OBJSTORE_CONFIG` | GCS bucket configuration for block reads | yes | — | k8s-secret `thanos-objectstorage` key `thanos.yaml` |
| `HOST_IP_ADDRESS` | Host node IP | no | — | `status.hostIP` field ref |

### Thanos Compact

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `OBJSTORE_CONFIG` | GCS bucket configuration for compaction | yes | — | k8s-secret `thanos-objectstorage` key `thanos.yaml` |
| `HOST_IP_ADDRESS` | Host node IP | no | — | `status.hostIP` field ref |

### Grafana

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `GF_SERVER_ROOT_URL` | Public root URL for Grafana | yes | `http://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/` | env (helm values) |
| `GF_SERVER_CERT_KEY` | Path to TLS private key | yes | `/var/groupon/tls.key` | env |
| `GF_SERVER_CERT_FILE` | Path to TLS certificate | yes | `/var/groupon/tls.crt` | env |
| `GF_SERVER_PROTOCOL` | Server protocol (https) | yes | `https` | env |
| `GF_SERVER_HTTP_PORT` | HTTP listen port | yes | `3000` | env |
| `GF_SECURITY_ADMIN_USER` | Grafana admin username | yes | — | k8s-secret `grafana` key `admin-user` |
| `GF_SECURITY_ADMIN_PASSWORD` | Grafana admin password | yes | — | k8s-secret `grafana` key `admin-password` |
| `GF_AUTH_OKTA_CLIENT_ID` | Okta OAuth2 client ID | yes | — | k8s-secret `grafana` key `okta-client-id` |
| `GF_AUTH_OKTA_CLIENT_SECRET` | Okta OAuth2 client secret | yes | — | k8s-secret `grafana` key `okta-client-secret` |
| `GF_AUTH_OKTA_REDIRECT_URL` | Okta OAuth2 redirect callback URL | yes | `https://prod-grafana.us-central1.logging.prod.gcp.groupondev.com/login/okta` | env |
| `GF_DATABASE_URL` | Grafana database connection string | yes | — | k8s-secret `grafana` key `db-url` |
| `GF_DATABASE_LOG_QUERIES` | Enable database query logging | no | `true` | env |
| `GF_DATABASE_MIGRATION_LOCKING` | Enable database migration locking | no | `false` | env |
| `GF_PATHS_DATA` | Grafana data directory | no | `/var/lib/grafana/` | env |
| `GF_PATHS_LOGS` | Grafana log directory | no | `/var/log/grafana` | env |
| `GF_PATHS_CONFIG` | Grafana config file path | no | `/etc/grafana/grafana.ini` | env |
| `REGION` | GCP region for Filebeat metadata | no | `us-central1` | env |
| `KAFKA_ENDPOINT` | Kafka bootstrap endpoint for Filebeat | no | `kafka-logging-kafka-bootstrap.kafka-production.svc.cluster.local` | env |
| `KAFKA_PORT` | Kafka port for Filebeat | no | `9093` | env |
| `KAFKA_PREFIX` | Kafka topic prefix for Filebeat | no | `logging_production_` | env |

> IMPORTANT: Actual secret values are never documented. Only variable names and purposes are listed above.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `--query.auto-downsampling` | Automatically selects appropriate resolution on Thanos Query | enabled | global |
| `--query.partial-response` | Returns partial results when some stores are unavailable | enabled | global |
| `--debug.accept-malformed-index` | Allows Thanos Compact to process blocks with malformed indexes | enabled | global |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `.meta/deployment/cloud/components/thanos-stack/common.yml` | YAML | Shared Helm values (scaling, probes, resource limits) |
| `.meta/deployment/cloud/components/thanos-stack/staging-us-central1.yml` | YAML | Staging US-Central1 region override |
| `.meta/deployment/cloud/components/thanos-stack/production-us-central1.yml` | YAML | Production US-Central1 region override |
| `.meta/deployment/cloud/components/thanos-stack/production-europe-west1.yml` | YAML | Production Europe-West1 region override |
| `.meta/deployment/cloud/components/thanos-stack/europe-west1/staging/thanos-querier.yml` | YAML | Staging EU Thanos Querier-specific values |
| `charts/thanos-groupon-stack/templates/prd/hashring-configmap.yaml` (rendered) | JSON in ConfigMap | Thanos Receive hashring — lists all 5 receive pod endpoints |
| `charts/thanos-groupon-stack/templates/filebeat.yml` | YAML | Filebeat sidecar log shipping configuration |
| `charts/grafana/templates/prd/configmap.yaml` | YAML | Grafana `grafana.ini` configuration |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `thanos-objectstorage` (key: `thanos.yaml`) | GCS bucket credentials and configuration for Thanos components | k8s-secret |
| `grafana` (key: `admin-user`) | Grafana admin username | k8s-secret |
| `grafana` (key: `admin-password`) | Grafana admin password | k8s-secret |
| `grafana` (key: `okta-client-id`) | Okta OAuth2 client ID | k8s-secret |
| `grafana` (key: `okta-client-secret`) | Okta OAuth2 client secret | k8s-secret |
| `grafana` (key: `db-url`) | Grafana database connection string | k8s-secret |
| `grouponcerts` | Groupon internal TLS certificate bundle | k8s-secret |
| `telegraf-production-tls-identity` | Filebeat TLS identity certificate for Kafka | k8s-secret |
| `telegraf--gateway--default-kafka-secret` | Kafka TLS certificates for Filebeat | k8s-secret |
| `.meta/deployment/cloud/secrets/thanos/gcp/<target>.yml` | Per-environment deployment secrets (git submodule: `metrics/secrets`) | git-submodule |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

- **Staging (`staging-us-central1`, `staging-europe-west1`)**: Uses `gcp-stable-us-central1` and `gcp-stable-europe-west1` GKE clusters. Filebeatreports to MSK staging Kafka. Thanos Querier minimum replicas: 5, maximum: 10.
- **Production (`production-us-central1`, `production-europe-west1`)**: Uses `gcp-production-us-central1` and `gcp-production-europe-west1` GKE clusters. Thanos Querier resources: 5Gi memory request, 80Gi limit, 500m CPU request.
- Both environments use the `monitoring-platform` GKE node pool with a `NoSchedule` taint toleration.
- Secrets are sourced from environment-specific files in the `metrics/secrets` git submodule (`.meta/deployment/cloud/secrets/thanos/gcp/<target>.yml`).
