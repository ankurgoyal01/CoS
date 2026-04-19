---
service: "minio"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Object Storage / Infrastructure"
platform: "Continuum"
team: "Conveyor Cloud"
status: active
tech_stack:
  language: "N/A"
  language_version: "N/A"
  framework: "MinIO"
  framework_version: "RELEASE.2025-09-07T16-13-09Z"
  runtime: "Alpine Linux"
  runtime_version: "latest (FROM alpine)"
  build_tool: "Docker + Helm"
  package_manager: "N/A"
---

# MinIO Overview

## Purpose

MinIO is Groupon's self-hosted, S3-compatible object storage service deployed within the Continuum platform. It provides an on-premises object storage layer that exposes the S3 API, allowing Continuum services to store and retrieve binary objects (files, images, documents, archives) without relying on AWS S3 directly in all environments. This repository packages and deploys the upstream MinIO binary image into Groupon's Kubernetes infrastructure.

## Scope

### In scope
- Building and publishing a Groupon-specific Docker image wrapping the upstream MinIO release
- Deploying MinIO as a Kubernetes worker across staging and production environments (AWS eu-west-1, GCP us-central1, GCP europe-west1)
- Exposing the S3-compatible HTTP API on port 9000
- Serving object storage to internal Continuum consumers
- Managing environment-specific scaling and configuration via Helm values

### Out of scope
- Application-level business logic (this is a deployment wrapper for an upstream binary)
- Custom authentication or authorization layer beyond MinIO's built-in S3 auth
- Object lifecycle policy management (handled externally via MinIO console or API calls from consumers)
- Long-term data archival or tiering (not configured in this repository)

## Domain Context

- **Business domain**: Object Storage / Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Internal Continuum platform services that require S3-compatible object storage (consumers tracked in the central architecture model)
- **Downstream dependencies**: None — MinIO is a self-contained storage server; it writes to a local volume mount (`/home/shared`) within the container

## Stakeholders

| Role | Description |
|------|-------------|
| Conveyor Cloud Team | Owns deployment, configuration, and capacity planning for this service |
| Continuum Platform Engineers | Consumers of the object storage API for application use cases |
| Platform SRE | Responsible for uptime, scaling alerts, and incident response |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Application | MinIO (upstream binary) | RELEASE.2025-09-07T16-13-09Z | `.meta/deployment/cloud/components/minio/common.yml` |
| Base image | Alpine Linux | latest | `Dockerfile` |
| Container image | docker-conveyor.groupondev.com/minio/minio | RELEASE.2025-09-07T16-13-09Z | `common.yml` (appImage / appVersion) |
| Helm chart | cmf-generic-worker | 3.92.0 | `.meta/deployment/cloud/scripts/deploy.sh` |
| Deployment tool | krane | N/A | `.meta/deployment/cloud/scripts/deploy.sh` |

### Key Libraries

> No evidence found in codebase. This service deploys an upstream MinIO binary with no custom application code and therefore has no application-level library dependencies.
