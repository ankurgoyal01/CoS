---
service: "rbac"
title: "RBAC Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumRbacService", "continuumRbacPostgres"]
tech_stack:
  language: "Java 21"
  framework: "Spring Boot 3.2.5"
  runtime: "JVM 21"
---

# RBAC Documentation

Role-based access control service for Groupon's internal services, providing role and permission management, user-role assignment, role request workflows, audit logging, and Salesforce identity synchronization via MBus.

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
| Language | Java 21 |
| Framework | Spring Boot 3.2.5 |
| Runtime | JVM 21 (Eclipse Temurin) |
| Build tool | Maven (mvnw wrapper) |
| Platform | Continuum |
| Domain | Identity / Access Control |
| Team | Merchant Experience (MX) |
