---
service: "smockin"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["smockinApp", "smockinDb"]
---

# Architecture Context

## System Context

sMockin is a container within the `continuumSystem` (Continuum Platform). It is a standalone developer tooling service accessed directly by engineers and QA automation over HTTP. It does not sit in any consumer-facing request path. The service exposes two ports: port 8000 serves the admin UI and admin REST API, and port 8001 serves the live mock server that clients under test call. When proxy mode is active, `smockinApp` optionally forwards unmatched requests to an external downstream API (`downstreamApi`), though that target is not currently part of the federated Continuum model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Smockin Application | `smockinApp` | Application | Java / Spring Boot | 2.3.4.RELEASE | Spring Boot web application that serves the admin UI and hosts the mock server APIs. |
| Smockin Database | `smockinDb` | Database | PostgreSQL / H2 | — | Stores users, projects, mocks, configuration, and state for the mock server. |

## Components by Container

### Smockin Application (`smockinApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Admin REST API | Controllers for user, project, mock, and configuration management | Spring MVC |
| Mock Server Engine | Executes mock server lifecycle and request handling | Java (Spark) |
| HTTP Proxy Service | Forwards requests to downstream systems when required | Java (Apache HttpClient) |
| Authentication Service | Handles login, token validation, and user auth rules | Java (java-jwt) |
| Rule Engine | Evaluates rule conditions, ordering, and response templates | Java |
| Persistence Layer | JPA/Hibernate DAOs for core entities and migrations | Hibernate/JPA |
| WebSocket/SSE Gateway | Streams live logging and server events | Spring WebSocket/SSE |
| Web UI Assets | Static AngularJS UI served to browsers | HTML/JS/CSS (AngularJS) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `adminApi` | `smockin_authService` | Authenticates requests | direct |
| `adminApi` | `mockServerEngine` | Manages mocks and server operations | direct |
| `adminApi` | `httpProxyService` | Configures proxy behaviour | direct |
| `adminApi` | `smockin_persistenceLayer` | Reads/writes configuration and mocks | direct |
| `mockServerEngine` | `ruleEngine` | Evaluates matching rules and response logic | direct |
| `mockServerEngine` | `smockin_persistenceLayer` | Loads mock definitions and state | direct |
| `httpProxyService` | `mockServerEngine` | Checks for mock responses | direct |
| `webSocketGateway` | `mockServerEngine` | Streams live logging and messages | direct |
| `uiAssets` | `adminApi` | Calls admin APIs | REST / HTTP |
| `smockinApp` | `smockinDb` | Reads/writes users, mocks, configuration, and state | JDBC |

## Architecture Diagram References

- System context: `contexts-smockin`
- Container: `containers-smockin`
- Component: `components-smockinAppComponents`
