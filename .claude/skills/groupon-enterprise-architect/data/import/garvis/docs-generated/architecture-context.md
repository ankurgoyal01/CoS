---
service: "garvis"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumJarvisWebApp", "continuumJarvisBot", "continuumJarvisWorker", "continuumJarvisPostgres", "continuumJarvisRedis"]
---

# Architecture Context

## System Context

Garvis (Jarvis) is a service within the `continuumSystem` (Continuum Platform). It sits at the intersection of Change Management tooling and the Groupon engineering operations workflow. Engineers and on-call responders interact with Garvis exclusively through Google Chat spaces and direct messages. Garvis connects outward to Google Cloud Pub/Sub (message ingestion), JIRA (ticket management), PagerDuty (on-call and incident alerting), GitHub (repository queries), Google Workspace APIs (Drive, Docs, Calendar, Chat), and ProdCAT/Service Health for operational readiness data. All persistent state is stored in a dedicated PostgreSQL instance, with Redis serving as both a cache and the RQ job queue backend.

## Containers

| Container | ID | Type | Technology | Description |
|-----------|----|------|-----------|-------------|
| Jarvis Web App | `continuumJarvisWebApp` | Application / Web | Python / Django 6.0 | Django web server providing the operator admin UI, RQ monitoring dashboard, healthcheck, and webhook ingress endpoints |
| Jarvis Bot | `continuumJarvisBot` | Application / Bot | Python | Pub/Sub-driven bot runtime; subscribes to Google Chat events, routes commands, and calls Google Chat API and JIRA |
| Jarvis Worker | `continuumJarvisWorker` | Application / Worker | Python / RQ 2.6.1 | RQ worker pool and scheduler; executes background jobs queued by the bot and web app |
| Jarvis Postgres | `continuumJarvisPostgres` | Database | PostgreSQL | Primary relational database for all persistent Garvis state |
| Jarvis Redis | `continuumJarvisRedis` | Cache / Queue | Redis 7.1.0 | Caching layer and RQ job queue backend shared by all three application containers |

## Components by Container

### Jarvis Web App (`continuumJarvisWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Controllers (`webHttpControllers`) | Django URL routing and request handling for all inbound HTTP traffic including webhook endpoints | Django |
| Admin UI (`webAdminUi`) | Administrative web interface for operators to view and manage Jarvis state | Django Templates |
| RQ Dashboard (`webRqDashboard`) | Exposes django-rq monitoring endpoints for inspecting job queues and worker status | django-rq |

### Jarvis Bot (`continuumJarvisBot`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Pub/Sub Subscriber (`botPubSubSubscriber`) | Consumes Google Chat events from the configured Pub/Sub subscription | Google Pub/Sub |
| Command Router (`botCommandRouter`) | Parses incoming chat messages and routes commands to the appropriate plugin handler | Python |
| Plugin Handlers (`botPluginHandlers`) | Executes plugin business logic for each supported command (change approval, incident, on-call, etc.) | Python |
| Google Chat Client (`botChatClient`) | Calls Google Chat API to send messages, create spaces, and manage memberships | Google Chat API |

### Jarvis Worker (`continuumJarvisWorker`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RQ Worker (`workerRqWorker`) | Dequeues and executes background jobs from Redis RQ queues | RQ |
| RQ Scheduler (`workerScheduler`) | Schedules recurring and delayed jobs; enqueues them at configured intervals | RQ Scheduler |
| Plugin Jobs (`workerPluginJobs`) | Concrete job implementations invoked by bot command handlers and web flows | Python |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumJarvisWebApp` | `continuumJarvisPostgres` | Reads and writes application state via Django ORM | PostgreSQL |
| `continuumJarvisWebApp` | `continuumJarvisRedis` | Uses Redis for caching and enqueuing RQ jobs | Redis |
| `continuumJarvisBot` | `continuumJarvisRedis` | Uses RQ job queue and Pub/Sub coordination via Redis | Redis |
| `continuumJarvisBot` | `googlePubSub` | Subscribes to Google Chat events (stub — external dependency) | Google Pub/Sub |
| `continuumJarvisBot` | `googleChatApi` | Sends messages and manages Chat spaces (stub — external dependency) | HTTPS / REST |
| `continuumJarvisBot` | `jiraApi` | Creates and updates incident tickets (stub — external dependency) | HTTPS / REST |
| `continuumJarvisWorker` | `continuumJarvisRedis` | Dequeues jobs and manages scheduled job state | Redis |
| `continuumJarvisWorker` | `continuumJarvisPostgres` | Reads and writes job result and application state | PostgreSQL |
| `continuumJarvisWorker` | `googleChatApi` | Sends async notifications (stub — external dependency) | HTTPS / REST |
| `continuumJarvisWorker` | `jiraApi` | Creates and updates incidents from background jobs (stub — external dependency) | HTTPS / REST |

## Architecture Diagram References

- Component view (Web App): `jarvisWebAppComponents`
- Component view (Bot): `jarvisBotComponents`
- Component view (Worker): `jarvisWorkerComponents`
