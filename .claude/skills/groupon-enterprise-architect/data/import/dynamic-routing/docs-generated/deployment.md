---
service: "dynamic-routing"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "vm"
environments: ["production-snc1", "production-dub1", "staging-snc1", "emea-staging-snc1", "uat-snc1"]
---

# Deployment

## Overview

The dynamic-routing service is packaged as a WAR file and deployed inside a Tomcat container managed by Ansible on roller-based (VM) infrastructure. Docker is used only for CI builds (Maven build in a `maven:3.5.4-jdk-8-alpine` container via `docker-compose`). The service is not deployed to Kubernetes. Multiple environment instances run in snc1 (production, staging, EMEA staging, UAT) and dub1 (production). Deployment is managed by the Ansible playbook referenced in the Confluence Owners Manual.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container (CI only) | Docker | `FROM library/maven:3.5.4-jdk-8-alpine`; used only for Jenkins CI builds via `docker-compose.yml` |
| Application server | Tomcat 7+ | WAR deployed as `jms-dynamic-routing.war`; managed by Ansible |
| Orchestration | Ansible (roller-based VM) | Ansible playbooks — see Confluence Dynamic Routes Owners Manual |
| Load balancer | Internal VIP | e.g., `mbus-camel1.snc1`, `mbus-camel1.dub1` (from `.service.yml` `base_urls`) |
| CDN | None | Internal-only service; no CDN |

## Environments

| Environment | Purpose | Region / Colo | Internal URL |
|-------------|---------|--------------|--------------|
| Production | Live production traffic | snc1 | `http://mbus-camel1.snc1` |
| Production | Live production traffic | dub1 | `http://mbus-camel1.dub1` |
| Staging | Pre-production validation | snc1 | `http://mbus-camel1-staging.snc1` |
| EMEA Staging | EMEA-region staging | snc1 | `http://mbus-camel1-emea-staging.snc1` |
| UAT | User acceptance testing | snc1 | `http://mbus-camel1-uat.snc1` |

## CI/CD Pipeline

- **Tool**: Jenkins (Conveyor CI) using `java-pipeline-dsl@latest-2` shared library
- **Config**: `Jenkinsfile` at repository root
- **Trigger**: Push to any branch (standard Java pipeline); release required before production deploy
- **Maven parameters**: `-Duser.timezone=Europe/Berlin`
- **Agent**: `dind_8gb_2cpu` (Docker-in-Docker, 8 GB RAM, 2 CPU)
- **Slack notifications**: `#mbus-ci`
- **CI job URL**: `https://cci.groupondev.com/job/MBus/job/dynamic-routing/`

### Pipeline Stages

1. **Build**: `mvn package` — compiles Java, runs unit tests, produces `jms-dynamic-routing.war` and configuration assembly artifact
2. **Test**: Unit tests executed as part of `mvn package`; SonarQube analysis configured via `sonar-project.properties`
3. **Archive**: WAR and configuration assembly artifacts archived by Jenkins
4. **Deploy** (manual/release): Ansible deploys WAR to target Tomcat environment; requires a release version (no SNAPSHOTs in production, enforced by `checkNoSnapshotDeps` Maven profile)

## Artifact Versioning

- Version scheme: `<major-minor>.<patch>` — e.g., `3.12.42`
- `major-minor` is `3.12` (set in `pom.xml`)
- `patch` is supplied at build time via `-Dpatch=<buildNumber>`; defaults to `local-SNAPSHOT`
- Maven SCM: `ssh://git@github.groupondev.com/MBus/dynamic-routing.git`
- Nexus repository: `http://nexus-dev.snc1/content/repositories/releases`

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Manual (Ansible playbook) | One instance per environment (single named host per colo) |
| Memory | JVM heap — not specified in repo | Deployment configuration managed externally via Ansible |
| CPU | Not specified in repo | Deployment configuration managed externally via Ansible |

## Resource Requirements

> Deployment configuration managed externally via Ansible. No Kubernetes manifests or resource limit specs found in the repository.

| Resource | Request | Limit |
|----------|---------|-------|
| CPU | Not specified in repo | Not specified in repo |
| Memory | Not specified in repo | Not specified in repo |
| Disk | Not specified in repo | Not specified in repo |
