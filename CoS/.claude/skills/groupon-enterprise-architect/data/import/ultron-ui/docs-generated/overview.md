---
service: "ultron-ui"
title: Overview
generated: "2026-03-02T00:00:00Z"
type: overview
domain: "Data & D Platform — ingestion job orchestration"
platform: "Continuum"
team: "dnd-ingestion"
status: active
tech_stack:
  language: "Java"
  language_version: "8"
  framework: "Play Framework"
  framework_version: "2.4.8"
  runtime: "openjdk"
  runtime_version: "8"
  build_tool: "SBT"
  package_manager: "SBT/Ivy"
---

# Ultron UI Overview

## Purpose

Ultron UI is a web-based operator console for managing data integration jobs within the Groupon Data & D Platform. It provides a browser-accessible interface through which data engineers and operators can create and monitor jobs, inspect dependency graphs, manage job groups, track execution instances, and view performance trends. The service is stateless: it holds no persistent state of its own and delegates all business logic and data access to the Ultron API backend.

## Scope

### In scope

- Rendering the AngularJS single-page application for job orchestration operators
- Exposing HTTP endpoints that proxy operator actions to `continuumUltronApi`
- LDAP-authenticated access control for all routes
- Displaying job dependency graphs and lineage for data resources
- Presenting job execution history, instance status, and performance trend data
- Group-level organisation of jobs (create, read, update, delete groups)

### Out of scope

- Business logic for job scheduling and execution (owned by `continuumUltronApi`)
- Persistent storage of job definitions, instances, or lineage (owned by `continuumUltronApi`)
- Event-driven or asynchronous job triggering
- Data pipeline processing or transformation

## Domain Context

- **Business domain**: Data & D Platform — ingestion job orchestration
- **Platform**: Continuum
- **Upstream consumers**: Internal data engineers and platform operators (browser-based access)
- **Downstream dependencies**: `continuumUltronApi` (sole backend, HTTP/JSON)

## Stakeholders

| Role | Description |
|------|-------------|
| Data Engineer | Primary end-user; creates and monitors data integration jobs |
| Platform Operator | Manages job groups, instances, and resource lineage |
| dnd-ingestion Team | Owns and maintains the service |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Java | 8 | Dockerfile (`openjdk:8`) |
| Framework | Play Framework | 2.4.8 | `build.sbt` |
| Frontend framework | AngularJS | — | `app/assets/` |
| UI library | Bootstrap | 3.2.0 | `app/assets/` |
| Runtime | openjdk | 8 | Dockerfile |
| Build tool | SBT | 0.13.18 | `project/build.properties` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| Play Framework | 2.4.8 | http-framework | HTTP routing, controllers, template rendering |
| AngularJS | — | ui-framework | Browser-side SPA logic, data binding |
| Bootstrap | 3.2.0 | ui-framework | Responsive layout and UI components |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See the dependency manifest for a full list.
