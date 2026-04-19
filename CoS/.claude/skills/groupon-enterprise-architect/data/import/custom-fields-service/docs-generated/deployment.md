---
service: "custom-fields-service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [dev-us-west-1, dev-us-west-2, staging-us-west-1, staging-us-west-2, staging-us-central1, staging-europe-west1, production-us-west-1, production-eu-west-1, production-us-central1, production-europe-west1]
---

# Deployment

## Overview

Custom Fields Service is deployed as a containerized JVM application on Kubernetes via Groupon's Conveyor Cloud platform. It runs on both AWS and GCP across multiple regions. Deployments are triggered through DeployBot, which wraps a Helm-based rendering pipeline. Every PR merge to `master` triggers an automatic CI build and image push; promotions from staging to production are authorized manually through the DeployBot UI.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile` — base image `docker.groupondev.com/jtier/prod-java17-jtier:3` |
| Orchestration | Kubernetes | Manifests rendered via Helm chart `cmf-jtier-api` (version 3.8.0); config in `.meta/deployment/cloud/` |
| Load balancer | Hybrid-boundary VIP | Manages VIP infrastructure; routes external traffic to Kubernetes services |
| CDN | None | Not applicable for this internal API service |
| Metrics collection | Telegraf | Sidecar agent; URL configured per environment (e.g., `http://metrics.prod.us-west-1.aws.groupondev.com:8186`) |
| Log shipping | Filebeat | Sidecar agent; log index `custom_fields` in Splunk/Kibana |
| Service mesh | Envoy | Sidecar proxy for service-mesh traffic |

## Environments

| Environment | Purpose | Cloud / Region | VIP |
|-------------|---------|----------------|-----|
| dev-us-west-1 | Local developer testing (AWS) | AWS / us-west-1 | Internal dev VIP |
| dev-us-west-2 | Local developer testing (AWS) | AWS / us-west-2 | Internal dev VIP |
| staging-us-west-1 | Pre-production validation | AWS / us-west-1 | `custom-fields-service.staging.stable.us-west-1.aws.groupondev.com` |
| staging-us-west-2 | Pre-production validation | AWS / us-west-2 | Staging VIP |
| staging-us-central1 | Pre-production validation (GCP) | GCP / us-central1 | Staging VIP |
| staging-europe-west1 | Pre-production validation (GCP EMEA) | GCP / europe-west1 | Staging VIP |
| production-us-west-1 | Production (NA — AWS) | AWS / us-west-1 | `custom-fields-service.prod.us-west-1.aws.groupondev.com` |
| production-eu-west-1 | Production (EMEA — AWS) | AWS / eu-west-1 | `custom-fields-service.prod.eu-west-1.aws.groupondev.com` |
| production-us-central1 | Production (NA — GCP) | GCP / us-central1 | `custom-fields-service.us-central1.conveyor.prod.gcp.groupondev.com` |
| production-europe-west1 | Production (EMEA — GCP) | GCP / europe-west1 | GCP EMEA production VIP |

## CI/CD Pipeline

- **Tool**: Jenkins (Cloud Jenkins)
- **Config**: `Jenkinsfile` (root of repository)
- **Library**: `java-pipeline-dsl@latest-2` shared library
- **Trigger**: Automatic on every PR merge to `master` branch; manual dispatch available

### Pipeline Stages

1. **Build**: Runs `mvn deploy` — compiles, tests, packages, and publishes JAR artifact to Artifactory (`releases-us-west-2/com/groupon/engage/customfieldservice`)
2. **Docker image push**: Builds and pushes Docker image to `docker-conveyor.groupondev.com/engage/custom-fields-service`
3. **Staging deployment**: DeployBot automatically creates deployment tags for `staging-us-west-2` and `staging-us-west-1`; operator authorizes via DeployBot UI
4. **Production promotion**: Operator clicks **Promote** in DeployBot to promote staging build to production regions

### Release version format

`2.0.<timestamp>.<commit-sha>` — tracked at `https://github.groupondev.com/engage/custom-fields-service/releases`

### Helm rendering (manual)

```bash
helm template cmf-jtier-api \
  --repo http://artifactory.groupondev.com/artifactory/helm-generic/ \
  --version '3.8.0' \
  -f .meta/deployment/cloud/components/app/common.yml \
  -f .meta/deployment/cloud/secrets/cloud/${DEPLOYBOT_KUBE_CONTEXT} \
  -f .meta/deployment/cloud/components/app/${DEPLOYBOT_KUBE_CONTEXT} \
  --set appVersion=${DEPLOYBOT_PARSED_VERSION} > render.yml
kubectl apply -f render.yml
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (production US-W1) | Kubernetes HPA | min: 2 / max: 12 replicas |
| Horizontal (production EU-W1) | Kubernetes HPA (CPU target 30%) | min: 6 / max: 20 replicas |
| Horizontal (production GCP US-C1) | Kubernetes HPA + VPA | min: 2 / max: 12 replicas |
| Horizontal (staging US-W1) | Kubernetes HPA | min: 1 / max: 7 replicas |
| Horizontal (common default) | Kubernetes HPA | min: 3 / max: 3 replicas (common.yml baseline) |
| Capacity addition | Increase `maxReplicas` in environment binding file | Via DeployBot re-deploy |

## Resource Requirements

### Common baseline (from `common.yml`)

| Resource | Container | Request | Limit |
|----------|-----------|---------|-------|
| CPU | main | 500m | — |
| CPU | filebeat | 50m | 100m |
| CPU | envoy | 100m | — |
| Memory | main | 500Mi | 500Mi |
| Memory | filebeat | 100Mi | — |
| Memory | envoy | 50Mi | — |

### Production overrides (representative — us-west-1 AWS)

| Resource | Container | Request | Limit |
|----------|-----------|---------|-------|
| CPU | main | 170m | — |
| Memory | main | 3.5Gi | 5Gi |

### Health probes

| Probe | Path | Port | Initial Delay | Period |
|-------|------|------|---------------|--------|
| Readiness | `/grpn/healthcheck` | 8080 | 20s | 5s |
| Liveness | `/grpn/healthcheck` | 8080 | 30s | 15s |

## Rollback

Rollback is performed via DeployBot by redeploying a prior release version using the **Retry** option with the appropriate version tag. Database schema rollbacks are not supported — schema changes must be backward compatible.
