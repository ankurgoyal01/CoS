---
service: "consumer-data"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumConsumerDataService, continuumConsumerDataMessagebusConsumer, continuumConsumerDataMysql]
---

# Architecture Context

## System Context

Consumer Data Service 2.0 sits within the Continuum platform as the authoritative data store and API for consumer profiles. It is called synchronously by checkout and order services requiring consumer details, and it participates asynchronously in the Continuum MessageBus fabric by publishing profile change events and consuming account lifecycle events originating from the Users Service and GDPR workflows.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Consumer Data Service API | `continuumConsumerDataService` | API service | Ruby (Rack / Sinatra) | 2.1.0 | Handles HTTP requests for consumer profiles, locations, and preferences; publishes change events |
| Consumer Data MessageBus Consumer | `continuumConsumerDataMessagebusConsumer` | Async worker | Ruby (MessageBus consumer) | — | Consumes inbound MessageBus events (GDPR erasure, account creation) and mutates consumer data accordingly |
| Consumer Data MySQL | `continuumConsumerDataMysql` | Database | MySQL | 5.6 | Primary relational data store for all consumer entity tables |

## Components by Container

### Consumer Data Service API (`continuumConsumerDataService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Consumer API router | Routes `/v1/consumers/:id` GET/PUT requests | Sinatra |
| Location API router | Routes `/v1/locations` GET/POST/PUT/DELETE requests | Sinatra |
| Preference API router | Routes `/v1/preferences` GET/POST/PUT/DELETE requests | Sinatra |
| Health/heartbeat router | Serves `GET /status` and `GET /heartbeat` | Sinatra |
| ActiveRecord models | ORM layer for consumers, locations, preferences | ActiveRecord 6.1.3.2 |
| MessageBus publisher | Publishes consumer and location change events to JMS topics | messagebus 0.3.7 |
| GeoDetails client | Calls bhoomi for geographic enrichment of locations | typhoeus 1.4.0 |

### Consumer Data MessageBus Consumer (`continuumConsumerDataMessagebusConsumer`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| GDPR erasure handler | Processes `jms.topic.gdpr.account.v1.erased` and soft-deletes/anonymises consumer records | messagebus 0.3.7 |
| Account creation handler | Processes `jms.topic.users.account.v1.created` and provisions initial consumer record | messagebus 0.3.7 |
| Erasure completion publisher | Publishes `jms.queue.gdpr.account.v1.erased.complete` after successful erasure | messagebus 0.3.7 |

> No component-level DSL definitions have been captured in the architecture model yet.

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumConsumerDataService` | `continuumConsumerDataMysql` | Reads and writes consumer profiles, locations, preferences | ActiveRecord / MySQL |
| `continuumConsumerDataMessagebusConsumer` | `continuumConsumerDataMysql` | Reads and writes consumer profiles during event processing | ActiveRecord / MySQL |
| `continuumConsumerDataService` | bhoomi | Fetches GeoDetails for location enrichment | HTTP (typhoeus) |
| `continuumConsumerDataService` | pwa | Reads legacy consumer data | HTTP |
| `continuumConsumerDataService` | bhuvan | Reads external consumer data | HTTP |
| `continuumConsumerDataMessagebusConsumer` | MessageBus | Consumes inbound account lifecycle events | MessageBus |

## Architecture Diagram References

- System context: `contexts-consumer-data`
- Container: `containers-consumer-data`
- Component: `components-consumer-data`
