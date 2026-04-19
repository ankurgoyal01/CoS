---
service: "dynamic-routing"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Messaging Infrastructure"
platform: "Continuum"
team: "GMB (Global Message Bus)"
status: active
tech_stack:
  language: "Java"
  language_version: "1.8"
  framework: "Spring"
  framework_version: "4.2.6.RELEASE"
  runtime: "Tomcat"
  runtime_version: "7+"
  build_tool: "Maven"
  package_manager: "Maven"
---

# Message Bus Dynamic Routing Overview

## Purpose

The dynamic-routing service (artifact `jms-dynamic-routing`, service alias `mbus-camel`) is a Java web application that enables the creation and management of runtime-configurable message routes between JMS endpoints — queues and topics — across Groupon's Global Message Bus brokers. It exists to allow operators to connect, bridge, and transform message flows between different brokers and datacenters without code changes or service restarts. Route definitions are persisted in MongoDB, and Apache Camel contexts execute each route in-process.

## Scope

### In scope
- Creating, starting, stopping, and deleting dynamic Camel routes between JMS endpoints
- Supporting multiple endpoint types: JMS queues, JMS topics (durable and non-durable), REST ingestion, file sink, and null (discard) sink
- Managing connections to HornetQ (legacy) and Apache Artemis 2.x brokers via Jolokia/JMX
- Discovering broker destinations (queues and topics) via Jolokia JMX API
- Applying per-route filter chains and message transformers
- Providing a JSF-based admin UI for operator route management
- Persisting route definitions and running state in MongoDB
- Exposing a REST API for status and broker information
- Supporting cross-datacenter (snc1, dub1) and cross-colo message bridging

### Out of scope
- Broker provisioning and broker lifecycle management
- Producer/consumer application development
- Message schema definition and evolution
- Deal or order business logic
- High-volume analytics pipelines

## Domain Context

- **Business domain**: Messaging Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Operations/SRE teams using the admin UI or REST API; automated tooling calling `PUT /brokers/{brokerId}`
- **Downstream dependencies**: JMS brokers (HornetQ, Apache Artemis) via Jolokia/JMX; MongoDB for route persistence; backend services (HTTP) for optional entity enrichment in message transformers

## Stakeholders

| Role | Description |
|------|-------------|
| GMB Team (messagebus-team@groupon.com) | Service owner; responsible for development and deployment |
| SRE / Operations | Uses the admin UI and runbooks to manage routes during failover or migration events |
| Platform Consumers | Indirectly depend on active dynamic routes for cross-broker message delivery |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 1.8 | `pom.xml` `<target.jdk>1.8</target.jdk>` |
| Framework | Spring | 4.2.6.RELEASE | `pom.xml` `<spring.version>` |
| Message routing | Apache Camel | 2.17.7 | `pom.xml` `<camel.version>` |
| Web framework | Spring MVC + JSF (RichFaces) | 4.2.6 / 4.3.7.Final | `pom.xml` |
| Runtime | Tomcat (WAR) | 7+ | `pom.xml` Tomcat7 Maven plugin |
| Build tool | Maven | 3.x | `pom.xml` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `camel-core` | 2.17.7 | message-client | DSL and runtime for dynamic Camel routes |
| `camel-jms` | 2.17.7 | message-client | Camel JMS component used by each route |
| `camel-sjms` | 2.17.7 | message-client | Simple JMS component variant for Camel |
| `camel-mbus` | 1.4.0 | message-client | Groupon MessageBus Camel integration |
| `mbus-client` | 1.5.0 | message-client | Groupon MessageBus client library |
| `hornetq-jms-client` | 2.4.1.Final.Patched | message-client | HornetQ JMS connectivity for legacy brokers |
| `artemis-jms-client` | 2.6.4 | message-client | Apache ActiveMQ Artemis 2.x JMS connectivity |
| `jolokia-client-java` | 1.3.3 | metrics | JMX-over-HTTP client for broker discovery |
| `spring-data-mongodb` | (Spring IO Platform) | db-client | MongoDB repository and mapping |
| `mongo-java-driver` | (Spring IO Platform) | db-client | MongoDB wire-protocol driver |
| `spring-security-web` | (Spring IO Platform) | auth | HTTP Basic / form login for admin UI |
| `logback-steno` | 1.9.3 | logging | Structured Steno JSON logging |
| `richfaces-components-ui` | 4.3.7.Final | ui-framework | JSF component library for admin UI |
| `jackson-databind` | 2.6.5 | serialization | JSON serialization for REST API |
| `guava` | 13.0.1 | validation | Utilities (ImmutableMap, Preconditions) |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `pom.xml` for a full list.
