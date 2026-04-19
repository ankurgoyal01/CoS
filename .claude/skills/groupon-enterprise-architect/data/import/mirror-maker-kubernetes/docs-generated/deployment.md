---
service: "mirror-maker-kubernetes"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

MirrorMaker Kubernetes is deployed as a Kubernetes worker (type: `worker`, archetype: `java`) using the `cmf-java-worker` Helm chart (v3.88.1). Each distinct mirror pair (source cluster + topic whitelist + destination cluster) is deployed as a separate Helm release under the `mirror-maker-kubernetes-production` or `mirror-maker-kubernetes-staging` namespace. Deployment is coordinated by the deploy_bot toolchain using the `krane` apply tool. The service runs across multiple regions and cloud providers: AWS (eu-west-1, us-west-2) and GCP (europe-west1, us-central1).

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container image | docker-conveyor.groupondev.com/data/mirror-maker-kubernetes | Tagged by `DEPLOYBOT_PARSED_VERSION` at deploy time |
| Orchestration | Kubernetes | Namespace: `mirror-maker-kubernetes-production` (prod) / `mirror-maker-kubernetes-staging` (staging) |
| Helm chart | cmf-java-worker v3.88.1 | From `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy tool | krane (via deploy_bot) | `krane deploy <namespace> <context> --global-timeout=300s --filenames=-` |
| Deploy image | docker.groupondev.com/rapt/deploy_kubernetes:v2.8.5-3.13.2-3.0.1-1.29.0 | Used by deploy_bot targets |
| Log shipping | Filebeat sidecar | Log dir: `/var/log/mirror-maker`, file: `mirror-maker.log`, sourceType: `mirror_maker` |
| Metrics | Telegraf sidecar (jolokia2_agent) | Scrapes Jolokia at `http://localhost:8778/jolokia`, forwards to InfluxDB at `$TELEGRAF_URL` |
| TLS certificates | Kubernetes volume mount | `client-certs` volume mounted at `/var/groupon/certs` |
| Load balancer | None | Outbound connections only; no inbound LB required |

## Environments

| Environment | Purpose | Region | Cluster Context |
|-------------|---------|--------|-----------------|
| production | Live traffic replication (Janus, IM, mobile, msys, tracky, user-event) | eu-west-1 (AWS) | `mirror-maker-kubernetes-production-eu-west-1` |
| production | Janus GCP-MSK and MSK-GCP replication | europe-west1 (GCP) | GCP europe-west1 cluster |
| production | GCP NA Janus mirrors, batch-dispatch, CDP ingress | us-central1 (GCP) | GCP us-central1 cluster |
| production | Additional topic mirrors (mobile-tracking, janus staging) | us-west-2 (AWS) | `mirror-maker-kubernetes-production-us-west-2` |
| staging | Logging topic test mirror | europe-west1 (GCP) | GCP europe-west1 staging cluster |

## CI/CD Pipeline

- **Tool**: deploy_bot (`.deploy_bot.yml` v2 format)
- **Config**: `.deploy_bot.yml`
- **Trigger**: Manual dispatch via deploy_bot; Slack channel `kafka-deploys` receives start/complete/override notifications

### Pipeline Stages

1. **Template**: `helm3 template cmf-java-worker` renders Kubernetes manifests from `common.yml` + per-component YAML with `appVersion=${DEPLOYBOT_PARSED_VERSION}`
2. **Apply**: `krane deploy <namespace> <context> --global-timeout=300s --filenames=- --no-prune` applies rendered manifests to target Kubernetes cluster

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (Janus high-traffic) | HPA | min: 10, max: 40 (janus-all-eu forwarder) |
| Horizontal (Janus standard) | HPA | min: 10, max: 15 (k8s-msk and msk-k8s janus mirrors) |
| Horizontal (GCP Janus EU) | HPA | min: 3, max: 5 |
| Horizontal (GCP Janus NA) | HPA | min: 5, max: 10 |
| Horizontal (low-volume topics) | HPA | min: 1, max: 1 (im, user-event, tracky, mobile, msys) |
| Global HPA target utilization | HPA | 100% (common.yml) |
| Memory (main container) | Limits | Request: 100Mi–600Mi; Limit: 500Mi–3Gi (component-dependent) |
| Memory (Filebeat sidecar) | Limits | Request: 100Mi, Limit: 200Mi |
| CPU (main container) | Limits | Request: 100m–300m (component-dependent); no CPU limit set |
| CPU (Filebeat sidecar) | Limits | Request: 100m, Limit: 500m |

## Resource Requirements (Representative Janus Mirror)

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 200m | not set |
| Memory (main) | 500Mi | 3Gi |
| CPU (Filebeat) | 100m | 500m |
| Memory (Filebeat) | 100Mi | 200Mi |
| Disk | none | none (stateless) |
