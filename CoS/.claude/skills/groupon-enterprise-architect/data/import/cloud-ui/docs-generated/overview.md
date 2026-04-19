---
service: "cloud-ui"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Cloud Platform — Application Lifecycle Management"
platform: "Continuum / GCP GKE"
team: "Cloud Platform Team"
status: active
tech_stack:
  language: "TypeScript / Go"
  language_version: "TypeScript 5 / Go 1.x"
  framework: "Next.js"
  framework_version: "14"
  runtime: "Node.js"
  runtime_version: "22"
  build_tool: "npm"
  package_manager: "npm >= 10.0.0"
---

# Cloud UI Overview

## Purpose

Cloud UI is a web-based platform management interface for Groupon's GCP Kubernetes environment. It provides a unified interface for creating, configuring, and deploying multi-component applications through a GitOps pipeline — from configuration editing through Git commit, Jenkins build, and Deploybot delivery. The system comprises a Next.js frontend (`continuumCloudUi`) and a paired Go backend API (`continuumCloudBackendApi`) built with the Encore framework.

## Scope

### In scope

- Creating and managing multi-component Kubernetes applications within organizations
- Configuring per-component Helm chart selection (`cmf-generic-api`, `cmf-generic-worker`), version, autoscaling, resource requests, health probes, environment variables, secrets, and storage
- Environment-specific component configuration (staging vs. production isolation)
- GitOps sync: generating Helm values files and committing them to application Git repositories via SSH
- Deployment lifecycle tracking across phases: `queued` → `syncing` → `synced` → `building` → `ready_to_deploy`
- Jenkins build status polling by commit hash
- Helm chart rendering and manifest preview (from Artifactory)
- Configuration diff between current and last-deployed state
- Organization management (team groupings aligned to GitHub structure)

### Out of scope

- Actual Kubernetes cluster provisioning (handled externally)
- Secret rotation or vault management
- Deploybot deployment execution (Deploybot URL is surfaced but invocation is external)
- Jenkins job creation or pipeline definition
- Container image builds

## Domain Context

- **Business domain**: Cloud Platform — Application Lifecycle Management
- **Platform**: Continuum / GCP GKE
- **Upstream consumers**: Platform engineers and application teams via web browser
- **Downstream dependencies**: Cloud Backend API (Encore/Go), PostgreSQL, Git repositories (SSH), Jenkins (`https://cloud-jenkins.groupondev.com`), Deploybot (`https://deploybot.groupondev.com`), Artifactory Helm registry (`https://artifactory.groupondev.com/artifactory/list/helm-generic/`)

## Stakeholders

| Role | Description |
|------|-------------|
| Cloud Platform Team | Maintainers; responsible for backend API, CI/CD, and infrastructure |
| Application Teams | Primary users; manage their applications and trigger deployments via the UI |
| Platform Engineers | Onboard new applications, manage organizations and GitOps configuration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language (frontend) | TypeScript | 5 | `README.md` |
| Language (backend) | Go | 1.x | `cloud-backend/` package |
| Framework (frontend) | Next.js App Router | 14 | `README.md` |
| Framework (backend) | Encore | latest | `go.mod`, `encore.gen.go` |
| Runtime | Node.js | 22 | `Dockerfile`, `.github/workflows/ci-tests.yml` |
| Build tool | npm | >= 10.0.0 | `README.md` |
| Package manager | npm | >= 10.0.0 | `README.md` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `tailwindcss` | latest | ui-framework | Utility-first CSS styling |
| `shadcn/ui` | latest | ui-framework | Component library built on Radix UI |
| `react-hook-form` | latest | validation | Form state management |
| `zod` | latest | validation | Schema validation for form inputs |
| `go-git/go-git` | v5 | git-client | Programmatic Git clone/commit/push via SSH |
| `helm.sh/helm/v3` | v3 | helm-client | Helm chart loading and template rendering |
| `encore.dev/storage/sqldb` | latest | db-client | Encore-managed PostgreSQL access |
| `encore.dev/beta/errs` | latest | http-framework | Encore typed error handling |
| `encore.dev/rlog` | latest | logging | Structured logging in Encore services |
| `golang.org/x/crypto/ssh` | latest | auth | SSH key auth for Git operations |
| `tini` | latest | process-management | PID 1 init for Docker container |
| `dumb-init` | latest | process-management | Signal-forwarding init (deps stage) |
