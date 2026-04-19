---
service: "contract_service"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "kubernetes"
environments: [staging, production]
---

# Deployment

## Overview

Contract Service is containerized and deployed on Google Cloud Platform (GCP us-central1) via Groupon's **Conveyor Cloud** platform (Kubernetes). The service runs under the service identity `cicero` in SOX-scoped namespaces. Each pod runs multiple containers: the main Rails application (Unicorn), an Nginx reverse proxy, Envoy sidecar for Hybrid Boundary mTLS, Filebeat for log shipping, and log-tail utility containers. Deployments are managed through **Deploybot V2**, with every merge to `master` triggering a staging deploy and production promotions requiring explicit authorization.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | Image: `docker-conveyor.groupondev.com/sox-inscope/contract_service` |
| Orchestration | Kubernetes (GCP) | Manifest templates: `.meta/deployment/cloud/components/app/template/deployment.yml.erb` |
| Load balancer | Nginx (in-pod) | Nginx 1.15.9 sidecar container; listens on port 80, proxies to Unicorn on port 8080 |
| Service mesh | Hybrid Boundary (Envoy) | Envoy v1.10.0 sidecar for mTLS and traffic interception; init container `traffic-interceptor` |
| Log shipping | Filebeat | Filebeat 7.5.2 sidecar; ships logs to Kafka endpoint (`KAFKA_ENDPOINT`) for ELK ingestion |
| HPA autoscaling | Kubernetes HPA | Target utilization: 100% (CPU); configurable min/max replicas per environment |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Pre-production validation | GCP us-central1 (VPC: stable) | `cicero.staging.service.us-central1.gcp.groupondev.com` |
| Production | Live merchant traffic | GCP us-central1 (VPC: prod) | `cicero.production.service.us-central1.gcp.groupondev.com` |
| On-prem (legacy) | Legacy bare-metal deployment (SNC1/SAC1/DUB1) | SNC1, SAC1, DUB1 | `http://contract-service-vip.snc1`, `http://contract-service-vip.sac1`, `http://contract-service-vip.dub1` |

## CI/CD Pipeline

- **Tool**: Jenkins (`ruby-pipeline-dsl@latest-2`)
- **Config**: `Jenkinsfile`
- **Trigger**: On push to `master` branch; releasable branch: `master`; deploy target: `staging-us-central1`

### Pipeline Stages

1. **Build**: Compiles Docker image tagged with the commit SHA; image pushed to `docker-conveyor.groupondev.com/sox-inscope/contract_service`
2. **Test**: Runs RSpec test suite inside the CI container (`.ci/Dockerfile`, `.ci/docker-compose.yml`)
3. **Deploy to Staging**: Deploybot V2 automatically deploys every merged commit to `cicero-staging-sox` namespace
4. **Promote to Production**: Manual promotion from a successful staging deploy in Deploybot; generates a GPROD ticket and runs ProdCAT verification; requires S-POG active directory access
5. **Database Migrations**: Run via `rake db:migrate` as a Kubernetes Job (`.meta/deployment/cloud/components/app/template/migrations.yml.erb`) before the main deployment rollout

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Kubernetes HPA (auto-scaling) | Staging: min 1 / max 2; Production: min 2 / max 4; target CPU utilization 100% |
| Memory | Resource requests and limits | Request: 500Mi / Limit: 1Gi (both environments) |
| CPU | Resource requests and limits | Request: 300m / Limit: 700m (both environments) |

## Resource Requirements

| Resource | Request | Limit |
|----------|---------|-------|
| CPU (app container) | 300m | 700m |
| Memory (app container) | 500Mi | 1Gi |
| CPU (Nginx sidecar) | Defined in common.yml | Defined in common.yml |
| Memory (Nginx sidecar) | Defined in common.yml | Defined in common.yml |
| Memory (log-tail containers) | 50Mi | 100Mi |
| Memory (Filebeat) | 100Mi | 200Mi |

## Rollback Procedure

To roll back, find the last healthy commit SHA in Deploybot's Deployment History and retrigger that staging deploy, then promote to production. If the SHA cannot be found in history, search Release Engineering Jira Issues. If re-releasing fails, delete the Kubernetes deployment (`kubectl delete deploy <deployment_name>`) and redeploy — requires GPROD access in production.

## Kubernetes Namespaces

| Environment | Namespace |
|-------------|-----------|
| Staging | `cicero-staging-sox` |
| Production | `cicero-production-sox` |
