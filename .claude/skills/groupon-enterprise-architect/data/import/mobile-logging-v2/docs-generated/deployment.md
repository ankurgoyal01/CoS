---
service: "mobile-logging-v2"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Mobile Logging V2 is deployed as a Docker container on Google Cloud Platform (GCP), orchestrated by Kubernetes via Groupon's Conveyor Cloud platform. Deployments are triggered through Deploybot using tagged releases. Two environments exist: staging (`gcp-stable-us-central1`) and production (`gcp-production-us-central1`). Helm chart rendering is performed via `helm3 template cmf-jtier-api` with the JTier API chart at version `3.89.0`, applied using `krane`.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `src/main/docker/Dockerfile`; base `docker.groupondev.com/jtier/prod-java11-jtier:3` |
| Image registry | Artifactory | `docker-conveyor.groupondev.com/mobile-notifications/mobile-logging` |
| Orchestration | Kubernetes (GCP) | Namespaces: `mobile-logging-staging`, `mobile-logging-production` |
| Helm chart | `cmf-jtier-api` | Version `3.89.0` from `http://artifactory.groupondev.com/artifactory/helm-generic/` |
| Deploy tool | krane | Applies templated manifests with 300-second global timeout |
| Load balancer | Conveyor VIP | Configured per environment (see Environments table) |
| CDN | None evidenced | — |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| staging | Pre-production validation; auto-promoted from CI | GCP us-central1 (stable VPC) | `mobile-logging.us-central1.conveyor.stable.gcp.groupondev.com` |
| production | Live traffic | GCP us-central1 (prod VPC) | `mobile-logging.us-central1.conveyor.prod.gcp.groupondev.com` |

## CI/CD Pipeline

- **Tool**: Jenkins (via JTier shared library `java-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: Push to `main` branch or `test-error` branch; manual release tag creation

### Pipeline Stages

1. **Build**: `mvn clean package` — compiles Java source, runs unit tests, generates fat JAR
2. **Docker build**: Builds and pushes Docker image tagged with the release version
3. **Deploy to staging**: Triggers Deploybot deployment to `staging-us-central1` automatically on releasable branches
4. **Promote to production**: Manual approval in Deploybot — select the staged tag and approve the `production-us-central1` deployment
5. **Post-deploy validation**: Check `/var/groupon/jtier/logs/jtier.steno.log` for errors; verify Grafana dashboard

### Deployment command (per environment)

```bash
bash ./.meta/deployment/cloud/scripts/deploy.sh <env-name> <deploy-env> <namespace>
# Example production:
bash ./.meta/deployment/cloud/scripts/deploy.sh production-us-central1 production mobile-logging-production
```

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal (staging) | HPA | min=1, max=2, targetUtilization=100% |
| Horizontal (production) | HPA + VPA | min=3, max=20, targetUtilization=100% |
| Memory | Kubernetes limits | request=500Mi, limit=4Gi (common.yml) |
| CPU (staging) | Default | request=1000m |
| CPU (production) | Override | request=2000m |

To add capacity manually: adjust `minReplicas` and `maxReplicas` in the appropriate environment Helm values file. If the service remains overloaded after scaling, contact `prod-sysadmin@groupon.com`.

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (staging) | 1000m | VPA-managed |
| CPU (production) | 2000m | VPA-managed |
| Memory | 500Mi | 4Gi |
| Disk | Not specified | — |

## Container Startup

At container startup, `kafka-tls.sh` is executed before the JTier service starts. This script:

1. Reads the TLS certificate and key from the Kubernetes-mounted volume at `/var/groupon/certs/`
2. Exports them to a PKCS12 file at `/var/groupon/jtier/kafka.client.p12`
3. Converts to JKS keystore at `/var/groupon/jtier/kafka.client.keystore.jks`
4. Builds a trust store at `/var/groupon/jtier/truststore.jks` from the embedded Groupon Root CA certificate
5. Hands off to `/var/groupon/jtier/service/run` (JTier service launcher)

## Additional Ports

| Port | Purpose |
|------|---------|
| 8080 | HTTP application port (primary) |
| 8081 | Admin port (Dropwizard admin, health checks) |
| 8009 | JMX port |
