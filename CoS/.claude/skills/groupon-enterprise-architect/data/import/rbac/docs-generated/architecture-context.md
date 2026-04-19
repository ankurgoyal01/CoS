---
service: "rbac"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumRbacService", "continuumRbacPostgres"]
---

# Architecture Context

## System Context

The RBAC service is a member of the `continuumSystem` (Continuum Platform). It acts as the central authority for internal role-based access control across Groupon's services and internal tooling. Internal consumers call the RBAC REST API to assign roles, check permissions, and manage role request workflows. The service integrates with the `messageBus` (Groupon MBus) to receive Salesforce user-profile events and translate them into RBAC role assignments, with `continuumUsersService` to resolve user identities, and with Mailman to dispatch email notifications for role request state transitions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| RBAC Service | `continuumRbacService` | Service | Spring Boot | 3.2.5 | Spring Boot service providing RBAC APIs, role request workflows, and Salesforce sync via MBus |
| RBAC Postgres | `continuumRbacPostgres` | Database | PostgreSQL | — | Stores roles, permissions, user roles, role requests, and audit logs |

## Components by Container

### RBAC Service (`continuumRbacService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Controllers | REST controllers for all RBAC endpoints (roles, permissions, categories, scope types, user-roles, role requests, role ownership, audit logs, Salesforce profile, health check) | Spring MVC |
| RBAC Services | Business logic for roles, permissions, role requests, ownership, and authorization checks | Spring Service |
| RBAC Repositories | Data access for all RBAC entities, audit logs, and user-role mappings | Spring Data JPA |
| Salesforce Profile Processor | Maps Salesforce profile IDs to configured RBAC roles and assigns them to resolved user accounts | Spring Service |
| Users Service Client | HTTP client for resolving or creating user accounts by email in the Users Service | WebClient (Reactive) |
| Email Service | Sends role request notification emails (submitted, approved, rejected) via Mailman | WebClient (Reactive) |
| MBus Listeners | Consumes Salesforce user create and update events from MBus topic subscriptions | MBus Listener (STOMP) |
| MBus Message Processor | Parses incoming MBus messages (JSON or string payloads) and dispatches them to the Salesforce Profile Processor | Spring Service |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumRbacService` | `continuumRbacPostgres` | Reads and writes all RBAC data | JDBC |
| `continuumRbacService` | `continuumUsersService` | Looks up or creates user accounts by email during Salesforce sync | HTTPS |
| `continuumRbacService` | `messageBus` | Consumes Salesforce user create and update events | MBus / STOMP |
| `continuumRbacService` | `mailman` | Sends role request notification emails (submitted / approved / rejected) | HTTPS |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-rbacService`
