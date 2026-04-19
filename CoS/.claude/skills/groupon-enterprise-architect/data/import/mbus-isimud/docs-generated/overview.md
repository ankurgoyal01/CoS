---
service: "mbus-isimud"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Message Bus / Infrastructure"
platform: "Continuum"
team: "Global Message Bus"
status: active
tech_stack:
  language: "Java"
  language_version: "17"
  framework: "Dropwizard"
  framework_version: "JTier 5.14.1"
  runtime: "JVM"
  runtime_version: "17"
  build_tool: "Maven"
  package_manager: "Maven"
---

# mbus-isimud (Message Bus Validation Service) Overview

## Purpose

mbus-isimud is a message broker validation service that generates and executes randomized test workloads against message broker systems. It models a messaging topology — a graph of destinations (queues and topics), producers, and consumers, each configured with statistical data generators — to drive controlled traffic through any configured broker. The service was built to verify that new broker implementations can be adopted transparently, without requiring changes to existing mbus client applications or libraries.

## Scope

### In scope

- Defining and storing named messaging topologies (producer/consumer graphs with statistical parameters)
- Generating randomized message workloads from topology definitions
- Executing workloads against configured brokers (Apache Artemis, RabbitMQ via STOMP, RabbitMQ via AMQP)
- Intercepting and proxying STOMP traffic to forward it to new broker targets (STOMP proxy layer)
- Tracking execution history, job state, and per-channel delivery metrics
- Exposing a REST API to enumerate topologies, trigger executions, and retrieve results
- Generating statistical summaries (mean, min, max, p50, p95, p99) of message delivery times and sizes

### Out of scope

- Production message routing or business event publishing (this is a testing utility, not a production bus)
- Long-running consumer applications or business event processing
- Broker administration, provisioning, or cluster management
- Client library distribution

## Domain Context

- **Business domain**: Message Bus / Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Engineers and automated tests that invoke the REST API to validate broker behavior
- **Downstream dependencies**: Apache Artemis brokers (via STOMP), RabbitMQ brokers (via STOMP and AMQP), PostgreSQL (execution history)

## Stakeholders

| Role | Description |
|------|-------------|
| Global Message Bus team | Owns and operates the service; uses it to validate broker migrations |
| Platform engineers | Execute topology tests to performance-test candidate brokers |
| SRE | Monitors service health via PagerDuty (PGG3KB5) and Wavefront dashboards |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 17 | `pom.xml` `project.build.targetJdk=17`, `Dockerfile` `prod-java17-jtier:3` |
| Framework | Dropwizard (JTier) | JTier parent 5.14.1 | `pom.xml` parent `jtier-service-pom:5.14.1` |
| Runtime | JVM | 17 | `.ci/Dockerfile` `dev-java17-maven:2023-12-19`, `.envrc` |
| Build tool | Maven | JTier-managed | `pom.xml`, `.mvn/maven.config` |
| Package manager | Maven | | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `jtier-messagebus-client` | JTier 5.14.1 | message-client | Core mbus client library for connecting to Artemis/RabbitMQ |
| `jtier-messagebus-dropwizard` | JTier 5.14.1 | message-client | Dropwizard integration for mbus |
| `jtier-jdbi3` | JTier 5.14.1 | db-client | JDBI3 integration for JTier services |
| `jtier-daas-postgres` | JTier 5.14.1 | db-client | Managed PostgreSQL connection pooling (DaaS) |
| `jtier-migrations` | JTier 5.14.1 | db-client | Flyway-based PostgreSQL schema migrations |
| `jdbi3-bom` | 3.34.0 | orm | SQL object mapping for PostgreSQL |
| `jdbi3-jackson2` | 3.34.0 | orm | JSONB column mapping via Jackson |
| `jdbi3-stringtemplate4` | 3.34.0 | orm | Dynamic SQL templating |
| `amqp-client` (RabbitMQ) | 5.13.1 | message-client | Native AMQP connection to RabbitMQ |
| `caffeine` | 3.0.3 | state-management | In-memory caching |
| `commons-math3` | 3.6.1 | validation | Statistical distributions (normal, uniform, constant) for data generation |
| `t-digest` | 3.3 | metrics | Percentile estimation for message delivery statistics |
| `swagger-codegen-maven-plugin` | 3.0.25 | validation | Generates server stubs and models from `openapi3.yml` |
| `wiremock` | JTier-managed | testing | HTTP mock server for integration tests |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
