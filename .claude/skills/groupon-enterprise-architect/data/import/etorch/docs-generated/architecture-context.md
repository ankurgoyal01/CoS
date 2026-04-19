---
service: "etorch"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumEtorchApp, continuumEtorchWorker]
---

# Architecture Context

## System Context

eTorch is a service within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It occupies the merchant-facing extranet layer of the Getaways domain, sitting between hotel operators and a set of internal Continuum services (Deal Management API, Accounting Service) and external Getaways services (Inventory, Content, LARC, Channel Manager Integrator, Notification Service, MX Merchant API, Rocketman). Hotel operators and channel manager integrations call the eTorch API directly; the service then orchestrates reads and writes across downstream systems on their behalf.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| eTorch App | `continuumEtorchApp` | API service | Java / JAX-RS / Jersey / Jetty | Synchronous HTTP API handling all merchant-facing extranet requests |
| eTorch Worker | `continuumEtorchWorker` | Background worker | Java / Quartz | Scheduled background jobs for inventory sync, low inventory reporting, and maintenance tasks |

## Components by Container

### eTorch App (`continuumEtorchApp`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| Extranet Controllers | `etorchAppControllers` | Receives and validates inbound HTTP requests; routes to orchestration services | Java / JAX-RS |
| Orchestration Services | `etorchAppOrchestration` | Coordinates business workflows, applies validations, and assembles responses | Java |
| Backend Service Clients | `etorchAppClients` | Issues HTTP calls to downstream services (Inventory, Content, LARC, Synxis, Deal Management, Accounting, etc.) | Java / Apache HttpComponents |

### eTorch Worker (`continuumEtorchWorker`)

| Component | ID | Responsibility | Technology |
|-----------|----|---------------|-----------|
| Job Scheduler | `etorchWorkerScheduler` | Schedules and triggers periodic background jobs | Java / Quartz |
| Job Handlers | `etorchWorkerJobs` | Implements inventory sync, low inventory reporting, and maintenance job logic | Java |
| Backend Service Clients | `etorchWorkerClients` | Issues HTTP calls to downstream services used by background jobs | Java / Apache HttpComponents |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumEtorchApp` | `continuumDealManagementApi` | Updates deal management data | REST |
| `continuumEtorchApp` | `continuumAccountingService` | Reads accounting data | REST |
| `continuumEtorchApp` | Getaways Inventory | Reads and writes inventory data | REST |
| `continuumEtorchApp` | Getaways Content | Reads content and hotel metadata | REST |
| `continuumEtorchApp` | LARC | Reads approved rates and discounts | REST |
| `continuumEtorchApp` | Channel Manager Integrator (Synxis) | Syncs channel manager mappings | REST |
| `continuumEtorchApp` | Rocketman | Sends commercial notifications | REST |
| `continuumEtorchApp` | MX Merchant API | Reads merchant information | REST |
| `continuumEtorchApp` | Notification Service | Sends notification emails | REST |
| `continuumEtorchWorker` | Getaways Inventory | Runs inventory maintenance jobs | REST |
| `continuumEtorchWorker` | Getaways Content | Runs content sync jobs | REST |
| `continuumEtorchWorker` | `continuumAccountingService` | Generates accounting reports | REST |
| `continuumEtorchWorker` | Notification Service | Sends batch notifications | REST |
| `etorchAppControllers` | `etorchAppOrchestration` | Routes requests to orchestration | Direct |
| `etorchAppOrchestration` | `etorchAppClients` | Calls external services via clients | Direct |
| `etorchWorkerScheduler` | `etorchWorkerJobs` | Triggers scheduled job handlers | Direct |
| `etorchWorkerJobs` | `etorchWorkerClients` | Calls external services via clients | Direct |

## Architecture Diagram References

- Component (eTorch App): `etorchAppComponents`
- Component (eTorch Worker): `etorchWorkerComponents`
