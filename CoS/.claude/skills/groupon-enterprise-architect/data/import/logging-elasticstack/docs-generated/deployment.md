---
service: "logging-elasticstack"
title: Deployment
generated: "2026-03-02T00:00:00Z"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [production, staging, gcp-us, gcp-eu]
---

# Deployment

## Overview

The Logging Elastic Stack is deployed as containerized workloads on both on-premises hardware (snc1, sac1, dub1) and Google Cloud Platform GKE clusters. On-prem ELK clusters are provisioned and configured via Ansible playbooks using ClusterShell for parallel node management. GKE deployments use the Elastic Cloud on Kubernetes (ECK) operator with Helm charts, deployed via Krane. Jenkins manages the full CI/CD pipeline with region-specific release branches.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Separate Docker images for Logstash (Java 21 / Alpine 3.16), Elasticsearch (Alpine-based), and Ansible tooling |
| Orchestration (Cloud) | Kubernetes / ECK | GKE-hosted Elasticsearch via ECK operator; Logstash and Kibana via Helm charts; Krane for deployment |
| Orchestration (On-prem) | Ansible | Ansible playbooks (< 2.9) provision and configure on-prem cluster nodes in snc1, sac1, dub1 |
| CI/CD | Jenkins | Region-specific pipeline branches trigger builds, filter tests, and cluster deployments |
| Build | Make | Top-level Makefile orchestrates Docker image builds, filter tests, and deployment tasks |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| production (on-prem snc1) | Primary US production logging cluster | snc1 (Santa Clara) | `ELASTICSEARCH_API_VIP` / `KIBANA_API_VIP` per cluster |
| production (on-prem sac1) | Secondary US production logging cluster | sac1 (Sacramento) | `ELASTICSEARCH_API_VIP` / `KIBANA_API_VIP` per cluster |
| production (on-prem dub1) | EU production logging cluster | dub1 (Dublin) | `ELASTICSEARCH_API_VIP` / `KIBANA_API_VIP` per cluster |
| release-gcp-us | GCP US production logging cluster on GKE | GCP US | Kibana at `:5601/login` per GKE cluster |
| release-eu | GCP EU logging cluster on GKE | GCP EU | Kibana at `:5601/login` per GKE cluster |
| release-gcp-staging | GCP staging logging cluster | GCP Staging | Kibana at `:5601/login` (staging) |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: Jenkinsfile / Jenkins pipeline configuration per release branch
- **Trigger**: Branch push to `release-gcp-us`, `release-gcp-staging`, or `release-eu`; manual dispatch for on-prem Ansible runs

### Pipeline Stages

1. **Build**: Builds Docker images for Logstash, Elasticsearch, and Ansible tooling via Make
2. **Test Filters**: Executes Logstash filter unit tests to validate per-sourcetype parsing logic before deployment
3. **Deploy (GKE)**: Runs Krane to apply Helm chart releases to the target GKE cluster; ECK operator manages Elasticsearch and Kibana lifecycle
4. **Deploy (On-prem)**: Runs Ansible playbooks via ClusterShell to provision or reconfigure on-prem ELK cluster nodes
5. **Smoke Test**: Validates Elasticsearch cluster health (`/_cluster/health`) and Kibana status (`/api/status`) post-deployment

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Elasticsearch) | Manual node addition via Ansible (on-prem) or ECK node count (GKE) | Defined per cluster in Helm values / Ansible inventory |
| Horizontal (Logstash) | Kubernetes HPA or manual replica count increase via Helm values | Defined in Helm chart values per environment |
| Memory | Configured per container in Helm values and Ansible host vars | JVM heap for Logstash/Elasticsearch set via `ES_JAVA_OPTS` / `LS_JAVA_OPTS` |
| Hot/Warm Tier | Elasticsearch ILM policies control index migration from hot to warm nodes | Configured via `default_elasticsearch_post_rollover_retention_in_hours` (default 384h) |

## Resource Requirements

> Not applicable. Specific CPU and memory request/limit values are defined in Helm chart values files per environment and not centrally documented in the service inventory.
