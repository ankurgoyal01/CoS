---
service: "sem-gtm"
title: Overview
generated: "2026-03-03"
type: overview
domain: "SEM / Marketing Technology"
platform: "Continuum"
team: "SEM (gtm-engineers@groupon.com)"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "Google Tag Manager Server-Side"
  framework_version: "stable (gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable)"
  runtime: "gtm-cloud-image"
  runtime_version: "stable"
  build_tool: "Jenkins (java-pipeline-dsl@latest-2)"
  package_manager: "N/A"
---

# GTM Server Side Overview

## Purpose

`sem-gtm` deploys and operates Google Tag Manager (GTM) server-side infrastructure for Groupon's marketing and analytics stack. The service runs two sub-deployments: a production tagging server that processes real-time tag management requests from web and app clients, and a preview server that allows tag engineers to validate and debug tag configurations before they reach production. By hosting GTM server-side, Groupon gains control over data routing, latency, and privacy compliance versus client-side GTM execution.

## Scope

### In scope

- Deploying the GTM server-side tagging server (`sem-gtm::tagging`) to GCP Kubernetes
- Deploying the GTM server-side preview server (`sem-gtm::preview`) to GCP Kubernetes
- Managing Helm chart configuration and Kubernetes manifests for both sub-services
- Maintaining GTM container configuration (`CONTAINER_CONFIG`) for both servers
- Defining horizontal pod autoscaling policies for each sub-service
- Providing a health check endpoint (`/healthz`) for liveness and readiness probing

### Out of scope

- GTM workspace authoring, tag logic, and trigger rule management (handled in the Google Tag Manager UI)
- Client-side GTM data layer instrumentation (handled by web/app teams)
- Central marketing attribution logic (handled by other SEM services)
- Groupon analytics pipeline ingestion downstream of GTM events

## Domain Context

- **Business domain**: SEM / Marketing Technology
- **Platform**: Continuum
- **Upstream consumers**: Web browsers and Groupon applications that route tag requests to the server-side endpoint; GTM preview/debug clients used by tag engineers
- **Downstream dependencies**: Google Tag Manager Cloud API (external); preview server referenced by the tagging server at `https://gtm.groupon.com/preview/` for debug-mode routing

## Stakeholders

| Role | Description |
|------|-------------|
| SEM Team Owner | dredmond — service owner and primary escalation contact |
| SEM Engineer | marcgarcia — team member |
| Tag Engineers | Use the preview server to validate tag configurations before production rollout |
| Marketing Analytics | Rely on the tagging server for accurate event capture driving SEM reporting |
| SRE On-Call | Respond to PagerDuty alerts under service `P6BR82L` |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Runtime image | gcr.io/cloud-tagging-10302018/gtm-cloud-image | stable | `Dockerfile` |
| Container orchestration | Kubernetes (GKE) | 1.29.0 | `.deploy_bot.yml` |
| Helm chart | cmf-generic-api | 3.89.0 | `.meta/deployment/cloud/scripts/deploy.sh` |
| Kustomize | kustomize post-renderer | base + overlays | `.meta/kustomize/` |
| Deploy tooling | krane | — | `.meta/deployment/cloud/scripts/deploy.sh` |
| CI pipeline | Jenkins (java-pipeline-dsl@latest-2) | latest-2 | `Jenkinsfile` |

### Key Libraries

> The service runs an unmodified Google-managed container image (`gtm-cloud-image:stable`). There are no application-level language dependencies or libraries to enumerate — all tag execution logic is provided by the GTM Cloud image. See the [Google Tag Manager server-side manual setup guide](https://developers.google.com/tag-platform/tag-manager/server-side/manual-setup-guide) for internal image details.
