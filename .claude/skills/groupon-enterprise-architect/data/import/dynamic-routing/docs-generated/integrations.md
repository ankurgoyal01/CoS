---
service: "dynamic-routing"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 1
---

# Integrations

## Overview

The dynamic-routing service integrates with three categories of external dependencies: JMS brokers (HornetQ and Artemis) for actual message transport, Jolokia HTTP-JMX endpoints on those brokers for destination discovery and acceptor introspection, and backend services (BES) for optional entity enrichment in message transformers. Internally, it depends on MongoDB (owned) for route persistence. The service is consumed by operations personnel through its UI and by tooling through its REST API.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| HornetQ Brokers | JMS (HornetQ Netty/NIO) | Source and destination for legacy-platform dynamic routes | Yes | `messageBusBrokers_9f42` (stub) |
| Apache Artemis 2.x Brokers | JMS (Artemis JMS client) | Source and destination for Artemis-based dynamic routes | Yes | `messageBusBrokers_9f42` (stub) |
| Jolokia HTTP endpoint on brokers | HTTP (Jolokia REST) | Broker acceptor discovery; JMS destination (queue/topic) enumeration for admin UI | Yes | `messageBusBrokers_9f42` (stub) |
| Backend Services (BES) | HTTP GET | Entity lookups for transformer message enrichment (HKG and LUP data centers) | No | `backendServices_54b1` (stub) |

### HornetQ Brokers Detail

- **Protocol**: JMS over HornetQ Netty connector (NIO mode); `TransportConfiguration` built with `host`, `port`, `USE_NIO=true`
- **Connection factory**: `HornetQConnectionFactory` with HA, infinite reconnect attempts, 500ms initial retry interval, 2x multiplier, 5s maximum retry interval
- **Caching**: Destination-side connections wrapped in `CachingConnectionFactory` (producer cache, 100 sessions; no consumer caching; no reconnect on exception)
- **Auth**: Broker credentials not configured in application properties; uses broker-default credentials
- **Failure mode**: Camel context fails to start; route is marked `running=false` and persisted to MongoDB; Camel retries connection per reconnect policy
- **Circuit breaker**: No — uses HornetQ HA reconnect semantics

### Apache Artemis 2.x Brokers Detail

- **Protocol**: JMS via `artemis-jms-client` 2.6.4; Stomp acceptor used for mbus-client type, `artemis` acceptor for jms-client type
- **Discovery**: Jolokia queries `org.apache.activemq.artemis:broker="0.0.0.0"` MBean for version and acceptors
- **Failure mode**: Route start fails; marked as not running in MongoDB
- **Circuit breaker**: No

### Jolokia HTTP Endpoint on Brokers Detail

- **Protocol**: HTTP via `jolokia-client-java` 1.3.3 (`J4pClient`)
- **Base URL**: `http://<brokerHost>:<jolokiaPort>/jolokia` (port defaults to 8161; configurable per broker in `brokerInfo.properties`)
- **Auth**: Optional `jolokiaUser` / `jolokiaPassword` per broker entry
- **Purpose**: Discovers all queues and topics for the admin UI destination picker; reads acceptor configurations to determine connection type (INTERNATIONAL vs MBUS_VIP vs MBUS_HOST)
- **Supported broker types**: HornetQ (`JolokiaArtemis12ManagementClient` — detects `hornetq` in factory class name), Artemis 2.x (`JolokiaArtemis25ManagementClient` — detects version starting with `"2."`)
- **Failure mode**: Route creation fails with runtime exception if broker is unreachable; admin UI destination list is empty

### Backend Services (BES) Detail

- **Protocol**: HTTP GET to `http://<besHost>/bs/<type>/<identifier>?key=<token>`
- **Data centers**: HKG (`hkgBesSrcHost`, `hkgBesAccessToken`) and LUP (`lupBesSrcHost`, `lupBesAccessToken`)
- **Auth**: API key passed as `key` query parameter
- **Purpose**: Transformer enrichment — retrieves entity data by type and ID to augment outgoing messages
- **Retry**: 3 attempts on connection error (implemented in `BackendServiceUtil`)
- **Failure mode**: Throws `BSConnectionException` if all retries fail; transformer propagates exception
- **Circuit breaker**: No

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| MongoDB (Dynamic Routing DB) | MongoDB wire protocol | Route definition persistence and state management | `continuumDynamicRoutingMongoDb` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| SRE / Operations engineers | HTTPS (browser) | Administer dynamic routes via JSF admin UI |
| Automated tooling / scripts | REST (HTTP) | Query broker status (`GET /brokers`); register brokers (`PUT /brokers/{brokerId}`); check service health (`GET /status`) |

> Upstream consumers of active dynamic routes (i.e., downstream JMS consumers of the destination endpoints) are tracked in the central architecture model and in individual service registrations.

## Dependency Health

- **JMS Brokers**: HornetQ client configured with infinite reconnect attempts. Artemis client uses Artemis HA semantics. If a broker is unavailable at route startup, the route is disabled (`running=false`) in MongoDB.
- **Jolokia**: No retry or circuit breaker; failures result in empty destination lists in the UI or failed route additions.
- **MongoDB**: Spring Data MongoDB uses standard driver connection pooling. No circuit breaker configured; startup route loading continues page-by-page and records null-count failures rather than aborting entirely.
- **Backend Services**: 3-attempt retry implemented in `BackendServiceUtil`; no circuit breaker.
