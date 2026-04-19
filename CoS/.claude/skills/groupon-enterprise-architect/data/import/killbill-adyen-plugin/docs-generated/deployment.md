---
service: "killbill-adyen-plugin"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: true
orchestration: "docker"
environments: [staging, production]
---

# Deployment

## Overview

The plugin is packaged as an OSGi bundle JAR (with embedded dependencies) and deployed into a running Kill Bill platform instance. It is not deployed as a standalone service. The build produces an assembly JAR via `maven-assembly-plugin` that is published to Groupon's Nexus/Artifactory repository and then referenced from the `gkb-deploy` deployment repository, which drives Jenkins-based deployment to Docker environments via Deploybot.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | Docker | `.ci/Dockerfile` — `FROM library/maven:3.5.4-jdk-8-alpine` (used for CI builds); runtime container is part of Kill Bill platform image |
| Build image | Docker (Maven) | `maven:3.5.4-jdk-8-alpine` with Groupon Nexus `settings.xml` |
| Plugin packaging | OSGi Bundle JAR | Produced by `maven-bundle-plugin` + `maven-assembly-plugin`; artifact `org.kill-bill.billing.plugin.java:adyen-plugin` |
| Orchestration | Deploybot + Jenkins | `gkb-deploy` repository drives deployment; Deploybot UI triggers per-region deploys |
| Artifact repository | Nexus / Artifactory | Snapshots: `http://nexus-dev.snc1/content/repositories/snapshots`; Releases: Groupon Artifactory releases |
| CI pipeline | Jenkins (`Jenkinsfile`) | `mavenReleasePipeline` from `java-pipeline-dsl@latest-2` shared library |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| Staging | Integration testing with Adyen test credentials | Configurable per region | Deploybot staging target |
| Production | Live payment processing | EMEA and other regions | Deploybot production target |

## CI/CD Pipeline

- **Tool**: Jenkins
- **Config**: `Jenkinsfile` at repo root
- **Trigger**: Push to `backport-0.18.x` (releasable branch); manual dispatch via Jenkins

### Pipeline Stages

1. **Build**: `mvn clean compile package install` — compiles, runs WSDL code generation, assembles OSGi bundle JAR and fat JAR
2. **Test**: `mvn test` — runs TestNG unit and integration tests (can be skipped with `-DskipTests=true`)
3. **Deploy to Nexus**: `mvn deploy` — publishes snapshot or release artifact to Groupon Nexus/Artifactory
4. **Release preparation (release only)**: `mvn release:prepare` + `mvn release:perform` — tags release, publishes release artifact
5. **Image tagging (if needed)**: Manual Docker retag step required when `sox-inscope` image pull fails during Deploybot deploy (documented workaround in README)
6. **Deploybot trigger**: gkb-deploy repository update triggers Deploybot; operator selects region to deploy via Deploybot UI

### Slack Notifications

The Jenkins pipeline sends Slack notifications to `#kill-bill-builds` on: any failure, any start, releasable branch failure, releasable branch start.

## Scaling

> Deployment configuration managed externally (via `gkb-deploy` and Kill Bill platform). Scaling of the plugin is governed by Kill Bill's container scaling, not the plugin itself.

## Resource Requirements

> No evidence found of explicit resource request/limit configuration in this repository. Managed by the Kill Bill platform deployment configuration in `gkb-deploy`.
