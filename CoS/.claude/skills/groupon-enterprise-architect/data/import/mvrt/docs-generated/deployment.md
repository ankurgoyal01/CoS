---
service: "mvrt"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging-us-central1, staging-us-west-2, production-eu-west-1, production-us-west-1]
---

# Deployment

## Overview

MVRT is containerized and deployed to Kubernetes via the Groupon `napistrano`/Deploybot pipeline. The Docker image is built by cloud-jenkins on every PR merge and pushed to Artifactory. Deployments are manually approved via Deploybot. MVRT is a SOX in-scope application with production primarily in the `eu-west-1` (DUB) region per `cloud_runbook.md`. The Kubernetes namespace is `mvrt-production-sox` (production) and `mvrt-staging-sox` (staging). Hybrid-boundary manages VIP ingress/egress.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `Dockerfile` at repo root; base image `docker-conveyor.groupondev.com/conveyor/alpine-node14.17.0:2021.05.15-12.50.59-6858aa5` |
| Image registry | Artifactory | `docker-conveyor.groupondev.com/sox-inscope/mvrt` |
| Orchestration | Kubernetes | Namespaces: `mvrt-production-sox`, `mvrt-staging-sox` |
| Ingress | Hybrid-boundary | VIP per region; mTLS interceptor enabled |
| Log shipping | Filebeat + Kafka | Logs shipped to ELK; Kafka endpoint per region |
| Log indexing | Splunk (Steno) | `sourcetype=mvrt_itier`, `index=steno` |

## Environments

| Environment | Purpose | Region / Provider | VIP / URL |
|-------------|---------|-------------------|-----------|
| staging-us-central1 | Stable staging (GCP) | us-central1 / GCP | `mvrt.staging.stable.us-central1.gcp.groupondev.com` |
| staging-us-west-2 | Stable staging (AWS) | us-west-2 / AWS | `mvrt-staging-sox-us-west-2` (cluster context) |
| production-eu-west-1 | Primary production (DUB) | eu-west-1 / AWS | `mvrt.prod.eu-west-1.aws.groupondev.com` |
| production-us-west-1 | Secondary production | us-west-1 / AWS | `mvrt.prod.us-west-1.aws.groupondev.com` |

Legacy on-prem environments:
- Staging: `http://mvrt-app-stg.snc1` (snc1 colo)
- Production: `http://itier-mvrt-vip.dub1` (dub1 colo)

## CI/CD Pipeline

- **Tool**: cloud-jenkins (Jenkins)
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: On PR merge to `master`; manual dispatch via `nap --cloud deploy`
- **Deploy tool**: Deploybot (`https://deploybot.groupondev.com/sox-inscope/mvrt`)
- **SOX gate**: Mergebot requires two `ship it` comments to merge PRs (SOX in-scope control)

### Pipeline Stages

1. **Build**: cloud-jenkins builds Docker image on PR merge to `master`
2. **Publish**: Docker image pushed to Artifactory (`docker-conveyor.groupondev.com/sox-inscope/mvrt`)
3. **Stage deploy**: Manually approved via Deploybot for `staging us-west-2`; tag selection on Deploybot page
4. **Promote to production**: Promote button on Deploybot page; GPROD ticket required
5. **Sanity test**: Manual verification post-deploy on production hosts
6. **Monitor**: Watch Wavefront dashboards for error rate and latency anomalies

Rollback procedure:
- Redeploy a previous tag via Deploybot, or
- `nap --cloud rollback -j GPROD-XXX -a PREVIOUS_ARTIFACT production eu-west-1`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA | Production: min 2 / max 3 replicas; Staging: min 1 / max 2 replicas |
| Node.js clustering | cluster-master | `server.child_processes: 2` (configured via CSON) |
| Memory | Kubernetes limit | request: 1536Mi / limit: 3072Mi (all environments) |
| CPU | Kubernetes limit | main request: 1000m (no limit set); logstash: 400m req / 750m limit; filebeat: 400m req / 750m limit |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (main) | 1000m | Not set |
| Memory (main) | 1536Mi | 3072Mi |
| CPU (logstash) | 400m | 750m |
| CPU (filebeat) | 400m | 750m |
| Memory (filebeat) | 100Mi (sidecar) | 200Mi (sidecar) |

Additional Node.js tuning:
- `NODE_OPTIONS: --max-old-space-size=1024` (V8 old-space heap cap)
- `UV_THREADPOOL_SIZE: 75` (libuv async I/O thread pool)
- `PORT: 8000` (HTTP listener)
