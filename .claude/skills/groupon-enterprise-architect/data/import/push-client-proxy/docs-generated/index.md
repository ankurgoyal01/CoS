---
service: "push-client-proxy"
title: "push-client-proxy Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumPushClientProxyService", "continuumPushClientProxyPostgresMainDb", "continuumPushClientProxyPostgresExclusionsDb", "continuumPushClientProxyMySqlUsersDb", "continuumPushClientProxyRedisPrimary", "continuumPushClientProxyRedisIncentive"]
tech_stack:
  language: "Java 17"
  framework: "Spring Boot 3.5.4"
  runtime: "eclipse-temurin 17-jre-jammy"
---

# push-client-proxy Documentation

Spring Boot proxy service that brokers outbound email delivery and audience membership operations on behalf of external clients, sitting between Bloomreach and Groupon's internal messaging infrastructure.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Endpoints, contracts, protocols |
| [Events](events.md) | Async messages published and consumed |
| [Data Stores](data-stores.md) | Databases, caches, storage |
| [Integrations](integrations.md) | External and internal dependencies |
| [Configuration](configuration.md) | Environment, flags, secrets |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Infrastructure and environments |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | Java 17 |
| Framework | Spring Boot 3.5.4 |
| Runtime | eclipse-temurin 17-jre-jammy |
| Build tool | Maven (mvnw) |
| Platform | Continuum |
| Domain | Email delivery / Audience management |
| Team | Subscription Engineering |
