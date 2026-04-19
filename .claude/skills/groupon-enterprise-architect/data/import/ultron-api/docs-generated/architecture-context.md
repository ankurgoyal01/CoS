---
service: "ultron-api"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumUltronApi, continuumUltronDatabase, continuumQuartzSchedulerDb]
---

# Architecture Context

## System Context

ultron-api is a set of containers within the `continuumSystem` (Continuum Platform). It serves as a centralized job orchestration platform: job runner clients call its HTTP API to register job runs and watermarks, while the internal Quartz scheduler triggers timed watchdog checks and dispatches alert emails via SMTP. The service persists all metadata to a dedicated relational database (`continuumUltronDatabase`) and uses a separate relational database (`continuumQuartzSchedulerDb`) to persist Quartz scheduler state. The SMTP email service dependency is currently stub-only in the federated model.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Ultron API | `continuumUltronApi` | Service / Web Application | Scala / Play Framework | — | Play Framework service providing job state APIs, UI, scheduling, and metadata management |
| Ultron Database | `continuumUltronDatabase` | Relational Database | Relational Database | — | Stores jobs, instances, resources, groups, permissions, and watchdog metadata |
| Quartz Scheduler DB | `continuumQuartzSchedulerDb` | Relational Database | Relational Database | — | Persists Quartz scheduler triggers and state |

## Components by Container

### Ultron API (`continuumUltronApi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| App Controller | Healthcheck and evolution endpoints | Play Controller |
| Job Controller | CRUD and query APIs for job metadata | Play Controller |
| Job Instance Controller | Job instance lifecycle APIs and queries | Play Controller |
| Group/User Controller | User, group, role, and membership APIs | Play Controller |
| Resource Controller | Resource registration and queries | Play Controller |
| Resource Type Controller | Resource type APIs | Play Controller |
| Resource Location Controller | Resource location APIs | Play Controller |
| Team Controller | Team CRUD APIs | Play Controller |
| Other Controller | Status, watchdog, dependency, and helper APIs | Play Controller |
| Data Dictionary Controller | Lineage and dictionary endpoints | Play Controller |
| Scheduler | Quartz-backed scheduling and watchdog jobs | Quartz |
| Email Manager | Composes and sends watchdog alert emails | SMTP |
| Resource Lineage | Builds lineage graphs for resources | Scala |
| Repository Layer | Slick repositories and table mappings | Slick |
| Web Views | HTML templates for the Ultron UI | Play Templates |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumUltronApi` | `continuumUltronDatabase` | Reads/writes Ultron metadata | JDBC/Slick |
| `continuumUltronApi` | `continuumQuartzSchedulerDb` | Persists Quartz scheduler state | JDBC |
| `continuumUltronApi` | `smtpEmailService_2d1e` | Sends alert emails (stub only) | SMTP |
| `appController` | `repositoryLayer` | Reads evolution and metadata status | Slick |
| `jobController` | `repositoryLayer` | Reads/writes job metadata | Slick |
| `jobInstanceController` | `repositoryLayer` | Manages job instance lifecycle | Slick |
| `groupUserController` | `repositoryLayer` | Manages users, groups, and permissions | Slick |
| `resourceController` | `repositoryLayer` | Manages resources | Slick |
| `resourceTypeController` | `repositoryLayer` | Manages resource types | Slick |
| `resourceLocationController` | `repositoryLayer` | Manages resource locations | Slick |
| `teamController` | `repositoryLayer` | Manages teams | Slick |
| `otherController` | `repositoryLayer` | Reads status, watchdog, and dependency data | Slick |
| `dataDictionaryController` | `resourceLineage` | Builds resource lineage views | Internal |
| `resourceLineage` | `repositoryLayer` | Loads resource and dependency data | Slick |
| `scheduler` | `repositoryLayer` | Schedules and updates watchdog data | Slick |
| `scheduler` | `emailManager` | Triggers watchdog alert email dispatch | Internal |
| All controllers | `webViews` | Renders HTML views for the Ultron UI | Play Templates |

> `smtpEmailService_2d1e` and `jobRunnerClients_4c7b` are stub-only in the federated model.

## Architecture Diagram References

- System context: `contexts-continuumUltron`
- Container: `containers-continuumUltron`
- Component: `ultronApiComponents` (view defined in `views/components/ultronApi.dsl`)
