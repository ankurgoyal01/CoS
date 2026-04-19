---
service: "map_proxy"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-europe-west1, production-us-central1, production-eu-west-1, production-europe-west1]
---

# Deployment

## Overview

MapProxy is containerised (Docker) and orchestrated on Kubernetes via Groupon's Conveyor Cloud platform. The service is deployed to five Kubernetes targets across two cloud providers (GCP and AWS) covering US and EMEA regions. Deployments are triggered by CI builds in Jenkins (Cloud Jenkins) and promoted through staging to production using DeployBot. A legacy on-premises deployment path (Roller/bare-metal at snc1/sac1/dub1) exists but the primary deployment target is Kubernetes.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` (root); base image `docker-conveyor.groupondev.com/jtier/prod-java11:3` |
| Container image | docker-conveyor.groupondev.com | `docker-conveyor.groupondev.com/geo/map_proxy:{version}` and `:latest` |
| Orchestration | Kubernetes (Conveyor Cloud) | Manifests generated from `.meta/deployment/cloud/components/app/*.yml` |
| CI/CD tool | Jenkins (Cloud Jenkins) | `Jenkinsfile` (root) — `java-pipeline-dsl@latest-2` shared library |
| Deployment tool | DeployBot | https://deploybot.groupondev.com/geo/map_proxy |
| Service mesh | Envoy sidecar (Hybrid Boundary) | Public hybrid boundary subdomain; `X-Forwarded-Proto: https` header injected |
| Log shipping | Filebeat → Kafka → ELK | `filebeat` config in `common.yml`; volume type `medium` |
| Metrics | Wavefront | https://groupon.wavefront.com/dashboards/mapproxy |
| On-prem (legacy) | Roller / bare-metal | snc1 (primary NA), sac1 (secondary NA), dub1 (EU); roller_deploy scripts in repo |

## Environments

| Environment | Purpose | Region / Cluster | URL |
|-------------|---------|-----------------|-----|
| staging-us-central1 | Pre-production validation (US) | GCP us-central1, `gcp-stable-us-central1` | `map-proxy.us-central1.conveyor.stable.gcp.groupondev.com` |
| staging-europe-west1 | Pre-production validation (EU) | GCP europe-west1, `gcp-stable-europe-west1` | `map-proxy.europe-west1.conveyor.stable.gcp.groupondev.com` |
| production-us-central1 | Production (US) | GCP us-central1, `gcp-production-us-central1` | `map-proxy.us-central1.conveyor.prod.gcp.groupondev.com` / `https://mapproxy.groupon.com` |
| production-eu-west-1 | Production (EU, AWS) | AWS eu-west-1, `production-eu-west-1` | `map-proxy.prod.eu-west-1.aws.groupondev.com` / `https://mapproxy-eu.groupon.com` |
| production-europe-west1 | Production (EU, GCP) | GCP europe-west1, `gcp-production-europe-west1` | — |
| on-prem snc1 | Production NA (legacy) | snc1 bare-metal VIP | `http://mapproxy-vip.snc1` |
| on-prem sac1 | Production NA secondary (legacy) | sac1 bare-metal VIP | `http://mapproxy-vip.sac1` |
| on-prem dub1 | Production EU (legacy) | dub1 bare-metal VIP | `http://mapproxy-vip.dub1` / `https://mapproxy-eu.groupon.com` |
| staging on-prem | Staging (legacy) | snc1 | `http://geo-mapproxy-staging-vip.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins — `cloud-jenkins.groupondev.com`)
- **Config**: `Jenkinsfile` (root) using `java-pipeline-dsl@latest-2` shared library
- **Trigger**: Merge to `master` branch (auto-deploy to staging); manual promote to production via DeployBot

### Pipeline Stages

1. **Build**: Maven `clean assembly:assembly` compiles Java sources, runs Gulp to bundle JS assets into the classpath, and produces `target/map_proxy-jar-with-dependencies.jar`.
2. **Docker Build and Push**: `dockerfile-maven-plugin` builds the Docker image and pushes to `docker-conveyor.groupondev.com/geo/map_proxy` with both `{version}` and `latest` tags.
3. **Auto-deploy to Staging**: DeployBot triggers deploy to `staging-us-central1` and `staging-europe-west1` automatically.
4. **Manual promote to Production**: Operator promotes `staging-us-central1` → `production-us-central1` and `staging-europe-west1` → `production-eu-west-1` / `production-europe-west1` via DeployBot UI.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | Kubernetes HPA | min 2 / max 5 replicas |
| Horizontal (production) | Kubernetes HPA | min 2 / max 15 replicas; `hpaTargetUtilization: 50` (from common.yml) |
| VPA | Disabled | `enableVPA: false` in all environment configs |

## Resource Requirements

| Resource | Staging Request | Production Request | Production Limit |
|----------|-----------|-----------|----|
| CPU (main) | 20–30m | 30–50m | — |
| CPU (envoy) | 30m | 30–40m | — |
| Memory (main) | 700Mi | 700Mi | 1Gi |
| JVM heap min | — | 512m | — |
| JVM heap max | — | 1G | — |

## Kubernetes Configuration Notes

- **HTTP port**: 8080 (mapped to service port 80 via `httpPort: 8080`)
- **Admin port**: 8081 (exposed as `admin-port`)
- **JMX port**: 8009 (exposed as `jmx-port`)
- **HTTPS ingress**: Enabled (`httpsIngress: enabled: true`)
- **Readiness probe**: GET `/heartbeat` on port 8080; initial delay 20s, period 10s
- **Liveness probe**: GET `/heartbeat` on port 8080; initial delay 30s, period 30s
- **Log directory**: `/var/groupon/log/mapproxy_service/map_proxy.log`; log source type `mapproxy`
- **Heartbeat file**: `/usr/local/mapproxy_service/heartbeat.txt`
- **Namespace (production)**: `map-proxy-production`
- **Namespace (staging)**: `map-proxy-staging`

## Rollback

- **Cloud**: Use DeployBot UI — click `RETRY` on the last stable deployment or `ROLLBACK` on a specific deployment.
- **On-prem**: Re-roll hosts using `deployment_scripts/prod_deployment.sh` with the previous stable Roller hostclass.
