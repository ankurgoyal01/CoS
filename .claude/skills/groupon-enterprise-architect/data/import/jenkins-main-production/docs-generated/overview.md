---
service: "cloud-jenkins-main"
title: Overview
generated: "2026-03-03"
type: overview
domain: "CI/CD Infrastructure"
platform: "Continuum"
team: "CICD"
status: active
tech_stack:
  language: "Groovy"
  language_version: ""
  framework: "Jenkins Configuration as Code (JCasC)"
  framework_version: ""
  runtime: "Jenkins"
  runtime_version: ""
  build_tool: "Terragrunt / Terraform"
  package_manager: ""
---

# Cloud Jenkins Main Overview

## Purpose

Cloud Jenkins Main is the production Jenkins CI/CD controller for Groupon's engineering organisation. It serves as the central orchestration hub for all software pipeline execution across hundreds of repositories, provisioning ephemeral EC2 build agents on demand and routing jobs to the correct node type (x86, Graviton, Android, macOS, infra-specific). A companion AWS Lambda function runs on a fixed schedule to detect and terminate dangling EC2 agents that were not cleaned up by the controller.

## Scope

### In scope

- Declarative pipeline execution for all Groupon engineering repositories
- JCasC-driven controller configuration (security, clouds, credentials, tools, libraries)
- Ephemeral EC2 agent provisioning and lifecycle management via the Amazon EC2 plugin
- Static macOS (iOS) and Android node registration for mobile builds
- Role-based access control (RBAC) via SAML/Okta SSO
- Deployment of self via Terraform/Terragrunt into AWS `grpn-internal-prod` (account 744390875592)
- Metrics and alerting integration with Wavefront and Slack
- Scheduled stale-agent cleanup via a companion AWS Lambda

### Out of scope

- Application business logic (owned by individual product teams)
- Artifact storage (owned by Artifactory)
- Source code hosting (owned by GitHub Enterprise)
- Log storage and search (owned by the centralised Logging Stack)
- Metrics storage (owned by the Wavefront/Telegraf stack)

## Domain Context

- **Business domain**: CI/CD Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: All engineering teams submitting builds through GitHub Enterprise webhooks and the Conveyor CI framework
- **Downstream dependencies**: GitHub Enterprise (source), Artifactory (artifacts), AWS EC2/Lambda (compute), Wavefront (metrics), Slack (alerts), SonarQube (code quality), Service Portal (build tracking)

## Stakeholders

| Role | Description |
|------|-------------|
| CICD Team | Owns and operates the Jenkins platform; contact cicd@groupon.com or #cicd in Slack |
| Engineering teams | Build and deploy their services using pipelines executed on this controller |
| SRE / On-call | Respond to PagerDuty incidents via service PCDVZJN |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Controller runtime | Jenkins | Managed via Docker image | `jenkins-config/Dockerfile` |
| Configuration framework | Jenkins Configuration as Code (JCasC) | — | `jenkins-config/casc/*.yaml` |
| Init scripting | Groovy hook scripts | — | `jenkins-config/init.groovy.d/` |
| Infrastructure as code | Terraform + Terragrunt | Pinned via `.terraform-version` / `.terragrunt-version` | `terraform/` |
| Config image base | Alpine Linux 3.15 | 3.15 | `jenkins-config/Dockerfile` |
| Smoke tests | Python (pytest) | — | `smoke-tests/requirements.txt` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| jenkins-python | — | testing | Smoke-test client for Jenkins REST API (`smoke-tests/test_jenkins.py`) |
| conveyor-ci-dsl-library | 1.5 (default) | scheduling | Implicit shared pipeline DSL library loaded by all jobs |
| ruby-pipeline-dsl | latest | scheduling | Pipeline DSL library for Ruby service pipelines |
| java-pipeline-dsl | latest | scheduling | Pipeline DSL library for Java service pipelines |
| data-pipeline-dsl | latest | scheduling | Pipeline DSL library for data/analytics pipelines |
| helm-pipeline-dsl | latest | scheduling | Pipeline DSL library for Helm/Kubernetes deployments |
| itier-pipeline-dsl | latest-1 | scheduling | Pipeline DSL for I-tier service pipelines |
| security-scan | latest-2 | auth | Shared security scanning library for all pipelines |
| conveyor-ci-util | r0.8.0 | scheduling | Utility functions for Conveyor CI pipelines |
| sonarqube-scanner | 3.2.0.1227 | metrics | Static code analysis integration |
| gchatnotification | latest | logging | Google Chat notification library |
