---
service: "dynamic-routing"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumDynamicRoutingWebApp", "continuumDynamicRoutingMongoDb"]
---

# Architecture Context

## System Context

The dynamic-routing service is a container within the `continuumSystem` (Continuum Platform). It bridges JMS brokers that make up Groupon's Global Message Bus (GMB), enabling operators to create runtime-configurable message routes between brokers in different datacenters (snc1, dub1) and between different broker generations (HornetQ, Artemis). It is consumed by operations/SRE personnel through its admin UI, and its REST API allows programmatic broker and status interrogation. It depends on MongoDB for route persistence and on JMS brokers (via Jolokia/JMX) for destination discovery and actual message transport.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Dynamic Routing Web App | `continuumDynamicRoutingWebApp` | WebApp | Java, Spring, JSF, Apache Camel, Tomcat | 3.12.x | Core application that manages, persists, and executes dynamic routes between JMS endpoints |
| Dynamic Routing MongoDB | `continuumDynamicRoutingMongoDb` | Database | MongoDB | — | Stores dynamic route definitions and operational running state |

## Components by Container

### Dynamic Routing Web App (`continuumDynamicRoutingWebApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Admin UI | JSF managed beans and pages for operator route administration (create, start, stop, delete routes) | JSF (RichFaces 4.3.7) |
| REST API | Exposes `GET /status` and `GET|PUT /brokers/{brokerId}` for tooling and health checks | Spring MVC |
| Dynamic Routes Manager | Orchestrates route lifecycle: loads routes on startup, starts/stops/adds/removes Camel contexts per route | Spring, Apache Camel |
| Dynamic Route Repository | Persists and retrieves `DynamicRoute` documents from MongoDB | Spring Data MongoDB |
| Broker Discovery & JMX | Discovers broker acceptors and JMS destinations (queues/topics) via Jolokia HTTP-JMX API | Jolokia 1.3.3, JMX |
| Camel Route Builder | Constructs a `RouteBuilder` from a stored `DynamicRoute` definition, wiring source → filters → transformers → destination | Apache Camel 2.17.7 |
| Message Transformers | Applies header copying, dynamic routing headers, chunk/tracing headers, and optional body transformation | Apache Camel processors |
| Backend Service Client | Issues HTTP GET calls to backend service (BES) hosts for entity lookups used by transformers | Apache HttpClient |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDynamicRoutingWebApp` | `continuumDynamicRoutingMongoDb` | Reads and writes route definitions and running state | MongoDB wire protocol |
| `continuumDynamicRoutingWebApp` | MessageBus Brokers (HornetQ/Artemis) | Connects to source and destination brokers; discovers destinations via JMX | JMS (HornetQ Netty / Artemis), Jolokia HTTP |
| `continuumDynamicRoutingWebApp` | Backend Services | Fetches backend entities for message enrichment in transformers | HTTP |
| Admin Operator | `continuumDynamicRoutingWebApp` | Manages dynamic routes via the JSF admin UI or REST API | HTTPS |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumDynamicRoutingWebApp`
