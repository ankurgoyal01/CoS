---
service: "smockin"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Developer Tooling / QA Infrastructure"
platform: "Continuum"
team: "3PIP-CBE"
status: active
tech_stack:
  language: "Java"
  language_version: "11"
  framework: "Spring Boot"
  framework_version: "2.3.4.RELEASE"
  runtime: "OpenJDK JRE"
  runtime_version: "11.0.9"
  build_tool: "Maven"
  package_manager: "Maven"
---

# sMockin Overview

## Purpose

sMockin is an API mocking and simulation platform used by development and QA teams to dynamically stub HTTP, WebSocket, and FTP endpoints. It operates as a self-contained web application that hosts both an admin UI and a live mock server, enabling teams to define, manage, and serve mock API responses without writing code. The service is deployed centrally within the Groupon Continuum platform so that multiple teams can collaborate on shared mock definitions.

## Scope

### In scope

- Defining and serving dynamic HTTP REST mock endpoints at runtime
- Stateful REST mocking that caches and manages JSON state across requests (GET, POST, PUT, PATCH, DELETE)
- Proxy mode: forwarding HTTP requests to downstream systems when no mock is matched (and vice versa)
- WebSocket mock endpoint management and live message pushing
- FTP server simulation via Apache FtpServer
- Import of API definitions from RAML and OpenAPI (Swagger) specification files
- Import and export of mock definition archives (ZIP)
- Multi-user management with JWT-based authentication and password reset flows
- Project-based organisation of mock endpoints
- Key/value data store for dynamic response variable substitution
- Traffic logging streamed to the browser via Server-Sent Events (SSE)
- Admin UI served as static AngularJS assets

### Out of scope

- Production traffic routing or API gateway functions
- Schema validation or contract testing (mocks are authored manually or imported)
- Kafka/event-bus stubbing — only HTTP, WebSocket, and FTP protocols are simulated
- Permanent data persistence of captured live traffic

## Domain Context

- **Business domain**: Developer Tooling / QA Infrastructure
- **Platform**: Continuum
- **Upstream consumers**: Development teams, QA engineers, and CI pipelines within Groupon that need stubbed HTTP dependencies
- **Downstream dependencies**: PostgreSQL (production/staging data store); optional downstream API servers when proxy mode is enabled

## Stakeholders

| Role | Description |
|------|-------------|
| QA Engineers | Define and manage mock endpoints for automated test suites |
| Backend Developers | Stub unavailable or in-development downstream services |
| Platform Team (3PIP-CBE) | Owns deployment, maintenance, and cloud migration |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 11 | `Dockerfile` (`openjdk:11.0.9-jre`) |
| Framework | Spring Boot | 2.3.4.RELEASE | `pom.xml` (`spring-boot-starter-parent`) |
| Runtime | OpenJDK JRE | 11.0.9 | `Dockerfile` |
| Build tool | Maven | 3 | `pom.xml`, `Jenkinsfile` |
| Package manager | Maven | — | `pom.xml` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| spark-core | 2.9.1 | http-framework | Embedded HTTP server that hosts the mock server engine on port 8001 |
| spring-boot-starter-jetty | 2.3.4 | http-framework | Jetty-backed embedded web server for the admin API on port 8000 |
| spring-boot-starter-data-jpa | 2.3.4 | orm | JPA/Hibernate ORM for all persistence operations |
| spring-boot-starter-websocket | 2.3.4 | http-framework | WebSocket support for mock WebSocket endpoints and SSE traffic logging |
| spring-boot-starter-activemq | 2.3.4 | message-client | Embedded Apache ActiveMQ broker for JMS queue mocking |
| activemq-broker | 2.3.4 | message-client | In-process ActiveMQ broker embedded alongside the application |
| h2 | 1.4.194 | db-client | H2 embedded database used for local/development mode |
| postgresql | (runtime) | db-client | PostgreSQL JDBC driver for production and staging data stores |
| HikariCP | 2.6.1 | db-client | JDBC connection pooling |
| ftpserver-core | 1.1.1 | http-framework | Apache FtpServer for simulating FTP endpoints |
| raml-parser-2 | 1.0.25 | serialization | Parses RAML API definition files for mock import |
| openapi-generator-maven-plugin | 4.2.2 | serialization | Parses OpenAPI/Swagger specification files for mock import |
| java-jwt | 3.4.0 | auth | JWT token generation and validation for admin API authentication |
| jasypt | 1.9.2 | auth | Encryption of sensitive configuration values |
| httpclient / fluent-hc | 4.5.3 | http-framework | Apache HTTP client used for proxy forwarding to downstream systems |
| commons-io | 2.6 | serialization | File I/O utilities for import/export archive handling |
