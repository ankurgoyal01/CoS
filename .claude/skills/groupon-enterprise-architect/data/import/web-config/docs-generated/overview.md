---
service: "web-config"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Routing / Edge Configuration"
platform: "Continuum"
team: "Routing Service"
status: active
tech_stack:
  language: "Python, Go"
  language_version: "Python 2.7, Go (version tracked in go.mod)"
  framework: "Fabric3"
  framework_version: "1.14.post1"
  runtime: "Docker"
  runtime_version: "busybox 1.29.1 (config image), nginx 1.23.2 (validation)"
  build_tool: "Docker Compose + Jenkins (java-pipeline-dsl)"
  package_manager: "pipenv (Python), go modules (Go)"
---

# web-config Overview

## Purpose

web-config generates all nginx routing configuration for Groupon's global web tier from version-controlled Mustache templates and YAML data files. It produces per-environment, per-virtual-host nginx config artifacts that are packaged into Docker images and deployed to Kubernetes routing clusters. A companion Go CLI (`redirect-requests`) reads Jira tickets for redirect requests and automates the creation of nginx rewrite rules, branch creation, and pull-request submission on GitHub Enterprise.

## Scope

### In scope

- Rendering nginx `main.conf`, `virtual_hosts/*.conf`, and `includes/*.conf` from Mustache templates and YAML data
- Generating per-country, per-virtual-host config files for all Groupon international markets (US, DE, FR, GB, AU, etc.)
- Generating locale-aware error pages (4xx/5xx) via translated templates
- Packaging generated config into environment-tagged Docker images (`uat`, `staging`, `production`)
- Deploying config to routing hosts via Fabric SSH tasks (`fab {ENV} deploy:{REVISION}`)
- Automated redirect-rule creation: reading MESH-project Jira tickets, parsing source/destination URLs, writing nginx rewrite rules, pushing branches, and opening pull requests
- Updating Jira ticket status to `In PR - Needs Review` after PR creation
- Deploying locale-specific error HTML pages to routing hosts

### Out of scope

- Live request proxying and upstream routing decisions (handled by `apiProxy` / grout)
- Akamai CDN configuration and cache policy management
- TLS certificate issuance (certificates are mounted from Kubernetes secrets)
- Service discovery and upstream health checking

## Domain Context

- **Business domain**: Routing / Edge Configuration
- **Platform**: Continuum
- **Upstream consumers**: Kubernetes routing clusters consume the Docker config images; on-premises routing hosts receive config via Fabric SSH deploys
- **Downstream dependencies**: `apiProxy` (grout, receives config), `continuumJiraService` (Jira — redirect ticket source), `cloudPlatform` (AWS Secrets Manager — Jira credentials), `githubEnterprise` (GitHub — branch/PR creation)

## Stakeholders

| Role | Description |
|------|-------------|
| Routing Service | Primary owner; manages templates, data files, and deployment pipeline |
| SOC (soc@groupon.com) | Security operations; reviews security rule changes |
| Prod-ops (prod-ops@groupon.com) | Monitors and coordinates production deployments |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Python | 2.7 | `Pipfile`, `generator/*.py`, `fabfile.py` |
| Language | Go | — | `go/redirect-requests/*.go` |
| Framework | Fabric3 | 1.14.post1 | `Pipfile` |
| Template engine | pystache | 0.5.4 | `Pipfile`, `generator/template.py` |
| Config serialization | PyYAML | 3.11 | `Pipfile`, `generator/fs.py` |
| Runtime (config image) | busybox | 1.29.1 | `Dockerfile` |
| Runtime (validation) | nginx | 1.23.2 | `.ci/docker-compose.yml` |
| Deployment tool | kustomize | v1.0.11 | `.ci/Dockerfile.deployment` |
| Build tool | Docker Compose + Jenkins | — | `Jenkinsfile`, `.ci/docker-compose.yml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Fabric3 | 1.14.post1 | scheduling | SSH-based deployment tasks (`fab generate`, `deploy`, `rollback`) |
| pystache | 0.5.4 | serialization | Mustache template rendering for nginx config files |
| PyYAML | 3.11 | serialization | Loading environment and virtual-host YAML data files |
| paramiko | 2.10.6 | http-framework | SSH transport used by Fabric for remote host operations |
| ecdsa | 0.11 | auth | SSH key cryptography support |
| pycrypto | 2.6.1 | auth | Cryptographic primitives for SSH session |
| pest-fab | (git) | scheduling | Groupon-internal Fabric extension for deployment utilities |
| go-jira (andygrunwald) | — | http-framework | Jira REST API client for reading and updating redirect tickets |
| go-github (google) | — | http-framework | GitHub Enterprise API client for PR creation |
| aws-sdk-go | — | db-client | AWS Secrets Manager client for retrieving Jira credentials |
| oauth2 (golang.org/x) | — | auth | OAuth2 token transport for GitHub API authentication |
| gopkg.in/yaml.v2 | — | serialization | YAML config file parsing in the Go redirect CLI |
