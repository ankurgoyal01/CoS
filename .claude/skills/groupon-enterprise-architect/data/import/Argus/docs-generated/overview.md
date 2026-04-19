---
service: "argus"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Observability / Monitoring Operations"
platform: "Continuum"
team: "Platform Engineering"
status: active
tech_stack:
  language: "Groovy"
  language_version: "2.3.11"
  framework: "Gradle"
  framework_version: "5.0"
  runtime: "Java"
  runtime_version: "1.8"
  build_tool: "Gradle 5.0 (gradle-wrapper)"
  package_manager: "Gradle / Maven Central"
---

# Argus Overview

## Purpose

Argus is a Gradle-based CLI tool suite that automates the lifecycle management of Wavefront monitoring artifacts — alerts and dashboards — across Groupon's multi-region infrastructure. It reads declarative YAML alert definitions from source control, renders Wavefront query expressions via a template engine, then creates or updates the corresponding alerts and dashboards in Wavefront using its REST API. Argus ensures that production monitoring configuration is version-controlled, consistently applied, and auditable.

## Scope

### In scope

- Declarative management of Wavefront alert definitions via YAML
- Template rendering of Wavefront alert conditions and display expressions using `SimpleTemplateEngine`
- Create-or-update synchronization of Wavefront alerts via `POST /api/v2/alert` and `PUT /api/v2/alert/:id`
- Wavefront dashboard payload construction and synchronization via `POST /api/dashboard`
- Alert summary reporting — querying firing frequency per alert for operator review
- Multi-region alert deployment: SNC1, SAC1, DUB1, EU-WEST-1, US-WEST-1, US-WEST-2, EMEA staging, and miscellaneous environments
- Monitoring coverage for internal services: `api-lazlo`, `api-lazlo` (SOX variant), `api-proxy`, `deckard`, `client-id`, `api-torii`, `regulatory-consent-log`

### Out of scope

- Runtime hosting (Argus is a batch CLI job, not a long-running service)
- Collection or emission of metrics (metrics are produced by monitored services)
- Wavefront account or user management
- Dashboard visualization design (templates define structure; content driven by live Wavefront metrics)
- Alerting notification routing beyond Wavefront webhook targets

## Domain Context

- **Business domain**: Observability / Monitoring Operations
- **Platform**: Continuum
- **Upstream consumers**: Jenkins CI pipeline (`Jenkinsfile`) triggers Argus jobs post-merge on `master` branch; human operators may also invoke Gradle tasks directly
- **Downstream dependencies**: Wavefront SaaS (`https://groupon.wavefront.com`) — all reads and writes go exclusively to the Wavefront REST API

## Stakeholders

| Role | Description |
|------|-------------|
| Platform / SRE Engineers | Define and maintain alert YAML definitions per service and region |
| Service Owners | Responsible for the alert definitions of their respective services under `src/main/resources/alerts/` |
| On-call Operators | Consumers of the alerts and dashboards that Argus provisions |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Groovy | 2.3.11 | `build.gradle` — `compile 'org.codehaus.groovy:groovy-all:2.3.11'` |
| Runtime | Java | 1.8 | `.tool-versions` — `java 1.8`; `build.gradle` — `sourceCompatibility = 1.8` |
| Build tool | Gradle | 5.0 | `gradle/wrapper/gradle-wrapper.properties` — `gradle-5.0-all.zip` |
| Container base image | OpenJDK 11 / Maven | 2020-12-04 | `.ci/Dockerfile` — `docker.groupondev.com/jtier/dev-java11-maven:2020-12-04-277a463` |
| Package manager | Maven Central / JCenter | — | `build.gradle` — `repositories { mavenCentral(); jcenter() }` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `org.codehaus.groovy:groovy-all` | 2.3.11 | language | Core Groovy runtime; enables Groovy scripts, `SimpleTemplateEngine`, `CliBuilder`, `FileType` |
| `org.codehaus.groovy.modules.http-builder:http-builder` | 0.7.1 | http-client | HTTP client (`HTTPBuilder`) used to call the Wavefront REST API for alert and dashboard CRUD |
| `org.yaml:snakeyaml` | 1.15 | serialization | Parses YAML alert definition files into Groovy maps for processing |
| `commons-cli:commons-cli` | 1.3.1 | cli | Parses CLI arguments for `alerts-builder.groovy`, `wf-graph-builder.groovy`, and `summary-report-builder.groovy` |
| `commons-lang:commons-lang` | 2.6 | utility | Apache Commons utility methods used alongside core Groovy |
| `log4j:log4j` | 1.2.17 | logging | Log4j logging backend for application output |
| `org.slf4j:slf4j-log4j12` | 1.7.18 | logging | SLF4J bridge routing to Log4j |
| `junit:junit` | 4.11 | testing | Unit testing framework |
