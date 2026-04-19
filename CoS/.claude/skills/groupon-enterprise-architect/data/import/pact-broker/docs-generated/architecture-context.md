---
service: "pact-broker"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumPactBrokerApp, continuumPactBrokerPostgres]
---

# Architecture Context

## System Context

Pact Broker is a container within the `continuumSystem` (Continuum Platform). It acts as a shared infrastructure service consumed by all Groupon service teams that participate in consumer-driven contract testing. Consumer services publish pact files to it; provider services post verification results. It sits on GCP (us-central1, staging) and sends outbound webhook notifications to GitHub Enterprise and GitHub.com to trigger CI pipeline gates.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Pact Broker App | `continuumPactBrokerApp` | Application | Ruby/Pact Broker | 2.135.0-pactbroker2.117.1 | Containerized Pact Broker service deployed on GCP/Kubernetes. Exposes HTTP API on port 9292 and processes contract publishing/verification workflows. |
| Pact Broker Postgres DB | `continuumPactBrokerPostgres` | Database | PostgreSQL | — | PostgreSQL database backing Pact Broker state (configured via `PACT_BROKER_DATABASE_*`). |

## Components by Container

### Pact Broker App (`continuumPactBrokerApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API (`continuumPactBrokerHttpApi`) | Serves Pact Broker API and UI endpoints for provider/consumer contract interactions | Rack/Sinatra API |
| Webhook Dispatcher (`continuumPactBrokerWebhookDispatcher`) | Executes configured webhooks and outbound callbacks to allowed hosts | Pact Broker Webhooks |
| Persistence Adapter (`continuumPactBrokerPersistence`) | Reads and writes broker domain data via PostgreSQL connection settings | ActiveRecord/SQL |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumPactBrokerApp` | `continuumPactBrokerPostgres` | Reads/writes contract and verification data | SQL (PostgreSQL) |
| `continuumPactBrokerApp` | `githubEnterprise` | Sends webhooks/integration callbacks to whitelisted internal host | HTTPS/webhook |
| `continuumPactBrokerApp` | `githubDotCom` | Sends webhooks/integration callbacks to whitelisted public host | HTTPS/webhook |
| `continuumPactBrokerHttpApi` | `continuumPactBrokerPersistence` | Reads/writes pacticipant, pact, version, and verification data | Direct (in-process) |
| `continuumPactBrokerWebhookDispatcher` | `continuumPactBrokerPersistence` | Loads webhook configuration and execution state | Direct (in-process) |
| `continuumPactBrokerHttpApi` | `continuumPactBrokerWebhookDispatcher` | Triggers webhook delivery after pact events | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-pact-broker`
- Container: `containers-pact-broker`
- Component: `components-pact-broker-app`
