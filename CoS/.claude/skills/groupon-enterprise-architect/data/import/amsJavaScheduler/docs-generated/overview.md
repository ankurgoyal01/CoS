---
service: "amsJavaScheduler"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Audience Management (CRM)"
platform: "Continuum"
team: "audience-eng@groupon.com"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "cron4j"
  framework_version: "2.2.3"
  runtime: "JVM"
  runtime_version: ""
  build_tool: "Maven"
  package_manager: "Maven"
---

# AMS Java Scheduler Overview

## Purpose

AMS Java Scheduler is a cron-driven batch scheduler service within the Continuum Audience Management System (AMS) platform. It loads schedule definition files at startup, binds cron expressions to specific action classes, and dispatches audience materialization and data-delivery jobs against the AMS REST API on a nightly basis. The service provides the temporal orchestration layer for Scheduled Audience Definitions (SADs), ensuring audience segments are materialized, integrity-checked, and federated to downstream systems (EDW) at predictable intervals across NA and EMEA regions.

## Scope

### In scope

- Loading cron schedule files and mapping expressions to runnable action classes via `cron4j`
- Dispatching SAD (Scheduled Audience Definition) materialization jobs by calling AMS REST APIs to search SADs and create Scheduled Audience Instances (SAIs)
- Running Users Batch SAD optimization jobs via AMS batch APIs
- Executing SAD integrity checks to detect stale SADs and reset their next-materialized timestamps
- Orchestrating EDW (Enterprise Data Warehouse) feedback push jobs over SSH
- Checking YARN queue capacity before launching new-flow jobs to avoid overload
- Sending operational alerting emails for anomalies (e.g., unverified SADs)
- Operating independently per region/realm (NA and EMEA) via separate schedule files and `CLASS_TO_RUN` launcher classes

### Out of scope

- Defining or managing audience segment logic (owned by `continuumAudienceManagementService`)
- Storing audience data or SAI results (owned by AMS service and its databases)
- Web-facing APIs or user-facing interfaces
- Real-time event streaming or reactive messaging
- EDW warehouse schema management (owned by the Teradata / EDW team)

## Domain Context

- **Business domain**: Audience Management (CRM)
- **Platform**: Continuum
- **Upstream consumers**: Kubernetes CronJob scheduler (triggers the container on schedule); no human callers at runtime
- **Downstream dependencies**: `continuumAudienceManagementService` (AMS REST API), YARN ResourceManager (capacity checks), EDW Feedback Host (SSH), SMTP relay (alerting emails)

## Stakeholders

| Role | Description |
|------|-------------|
| Audience Engineering | Service owners; responsible for schedule changes, deployments, and incident response (`audience-eng@groupon.com`) |
| CRM / AMS Platform Team | Consumers of SAD materialization output via the AMS service |
| PagerDuty On-Call | Receives alerts via `audience_service@groupon.pagerduty.com` for process-down events |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | `pom.xml` — `maven-compiler-plugin` source/target 8 |
| Scheduler Framework | cron4j | 2.2.3 | `pom.xml` — `net.sf.cron4j:cron4j:2.2.3` |
| Build tool | Maven | — | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |
| Containerization | Docker | — | `src/main/docker/Dockerfile`, `pom.xml` dockerfile-maven-plugin |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `net.sf.cron4j:cron4j` | 2.2.3 | scheduling | Core cron scheduling engine; parses cron expressions and invokes action tasks |
| `AudienceManagementWorkFlowAPI` | 4.6.6 | http-client | Groupon-internal AMS workflow API client for SAD/SAI operations |
| `com.groupon.audiencemanagement:amsQueueProxy` | 1.10 | http-client | Internal AMS queue proxy client |
| `com.sun.jersey:jersey-client` | 1.8 | http-client | HTTP client for REST calls to AMS endpoints |
| `com.squareup.okhttp3:okhttp` | 4.9.1 | http-client | Alternative HTTP client for outbound REST calls |
| `com.groupon.common:app-config` | 1.5 | config | Application configuration loading from YAML/properties files |
| `com.arpnetworking.metrics:metrics-client` | 0.2.2.GRPN.3 | metrics | Metrics emission to Groupon monitoring infrastructure |
| `log4j:apache-log4j-extras` | 1.1 | logging | Log4j extended appenders for file-based logging |
| `com.jcraft:jsch` | 0.1.52 | ssh | SSH client for EDW feedback push over remote command execution |
| `joda-time:joda-time` | 2.3 | serialization | Date/time calculations for schedule and SAD timing logic |
| `org.codehaus.jackson:jackson-mapper-asl` | 1.9.13 | serialization | JSON serialization/deserialization for AMS API payloads |
| `org.apache.commons:commons-email` | 1.4 | alerting | Email sending for operational alert notifications |
| `junit:junit` | 4.8.2 | testing | Unit test framework |
| `org.easymock:easymock` | 3.3.1 | testing | Mock framework for unit tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
