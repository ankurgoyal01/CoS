---
service: "logging-elasticstack"
title: Configuration
generated: "2026-03-02T00:00:00Z"
type: configuration
config_sources: [env-vars, config-files, helm-values]
---

# Configuration

## Overview

The Logging Elastic Stack is configured via a combination of environment variables (for endpoint addresses and environment identity), YAML configuration files (for Logstash pipelines and Ansible playbooks), and Helm chart values (for Kubernetes deployments). Sensitive credentials are stored in `elasticsearch_auth.yml` and injected at runtime. ILM retention behavior is controlled via named configuration parameters applied at index template creation.

## Environment Variables

| Variable | Purpose | Required | Default | Source |
|----------|---------|----------|---------|--------|
| `ELASTICSEARCH_API_VIP` | Virtual IP or hostname for the Elasticsearch REST API endpoint | yes | — | env |
| `KIBANA_API_VIP` | Virtual IP or hostname for the Kibana REST API endpoint | yes | — | env |
| `KAFKA_ENDPOINT` | Kafka broker connection string for Filebeat and Logstash Kafka plugins | yes | — | env |
| `KAFKA_PREFIX` | Topic name prefix applied to all Kafka log topics (e.g., `logging`) | yes | — | env |
| `CLUSTER_NAME` | Elasticsearch cluster name; used in ILM policies, index naming, and Ansible inventory | yes | — | env |
| `GROUPON_ENV` | Deployment environment identifier (e.g., `production`, `staging`) | yes | — | env |

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `default_ilm_managed` | Controls whether newly created indices are enrolled in ILM lifecycle management | `true` | per-sourcetype index template |
| `default_elasticsearch_post_rollover_retention_in_hours` | Defines how long post-rollover data is retained in the warm phase before deletion (in hours) | `384` (16 days) | per-sourcetype index template |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `elasticsearch_auth.yml` | YAML | Stores Elasticsearch cluster authentication credentials (username/password); consumed by Python management scripts and Ansible playbooks |
| Logstash pipeline configs (`*.conf`) | Logstash DSL | Defines per-sourcetype input (Kafka), filter (grok, mutate, date), and output (Elasticsearch) stages for each log type |
| Ansible playbooks (`*.yml`) | YAML | Infrastructure provisioning scripts for on-prem ELK cluster nodes; managed via ClusterShell and Ansible < 2.9 |
| Helm chart values (`values.yaml`) | YAML | Kubernetes deployment configuration for Logstash, Elasticsearch (ECK), and Kibana on GKE; overrides per cluster/region |
| Filebeat configuration (`filebeat.yml`) | YAML | Defines Filebeat inputs (log paths, container streams), Kafka output settings, and multiline patterns per service |

## Secrets

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| `elasticsearch_auth.yml` | Elasticsearch cluster username and password for API authentication | k8s-secret / file |
| AWS IAM credentials (boto3) | Authentication for S3 snapshot repository operations | AWS IAM / k8s-secret |
| Wavefront API token | Authentication for metric push to Wavefront TSDB | k8s-secret |
| Okta SAML/OAuth credentials | Kibana SSO integration client credentials | k8s-secret |
| GCP service account key | Authentication for GKE cluster access via Krane and Helm | k8s-secret |

> Secret values are NEVER documented. Only names and rotation policies.

## Per-Environment Overrides

Environments are differentiated via the `GROUPON_ENV` variable and corresponding Helm value overrides:

- **Production** (`production`): Full cluster sizing, ILM retention at `384` hours post-rollover, Kafka topics prefixed `logging_production_`, on-prem regions snc1/sac1/dub1 plus GCP multi-cluster
- **Staging** (`staging`): Reduced cluster sizing, shorter ILM retention, Kafka topics prefixed `logging_staging_`, GCP staging cluster only; Jenkins branch `release-gcp-staging`
- **GCP US** / **GCP EU**: Region-specific Helm values for GKE clusters; Jenkins branches `release-gcp-us` and `release-eu` control regional deployments
- **On-prem** (snc1, sac1, dub1): Provisioned via Ansible playbooks with region-specific inventory files; no Helm/GKE involvement
