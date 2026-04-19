---
service: "webbus"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumWebbusService"]
---

# Architecture Context

## System Context

Webbus is a container within the `continuumSystem` (Continuum Platform) — Groupon's core commerce engine. It sits at the boundary between Salesforce (an external CRM system) and the internal Groupon Message Bus. Salesforce sends HTTP POST requests carrying batches of CRM change events; Webbus validates each message and publishes it to the appropriate JMS topic on the Message Bus. No other external callers are authorised.

The service is public-facing in the sense that its external VIP (`webbus.groupon.com`) is network-accessible, but the external endpoint is IP-whitelisted to accept requests only from Salesforce. Downstream consumers of the published topics are internal Groupon services that subscribe to `jms.topic.salesforce.*` topics on the Message Bus.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Webbus Service | `continuumWebbusService` | API Service | Ruby, Grape | 1.9.3 | Public REST service that validates inbound Salesforce payloads and publishes them to Message Bus topics. |

## Components by Container

### Webbus Service (`continuumWebbusService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP API (Grape) (`webbusHttpApi`) | Exposes `POST /v2/messages`, mounts status and health endpoints, routes requests through validators to publisher | Grape API |
| Client Validator (`clientIdValidator`) | Validates the `client_id` query parameter against an environment-specific allowlist loaded from `config/clients.yml`; returns 404 on failure to obfuscate client enumeration | Grape Validator |
| Message Validator (`messageValidator`) | Validates each message in the batch: ensures `topic` and `body` are non-empty strings | Grape Validator |
| Message Publisher (`webbus_messagePublisher`) | Calls `Messagebus::Client#publish` per validated message over STOMP; collects failures and returns them to the caller for redelivery | Ruby Service |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `salesForce` | `continuumWebbusService` | POST /v2/messages (batch publish requests) | REST over HTTPS |
| `continuumWebbusService` | `messageBus` | Publishes whitelisted topic events via STOMP | STOMP over TCP port 61613 |
| `webbusHttpApi` | `clientIdValidator` | Validates client_id against allowlist | In-process Grape validation |
| `webbusHttpApi` | `messageValidator` | Validates message schema and topic payloads | In-process Grape validation |
| `webbusHttpApi` | `webbus_messagePublisher` | Publishes accepted messages to Message Bus | In-process method call |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-webbus-service`
- Dynamic flow: `dynamic-salesforce-to-message-bus-publish-flow`
