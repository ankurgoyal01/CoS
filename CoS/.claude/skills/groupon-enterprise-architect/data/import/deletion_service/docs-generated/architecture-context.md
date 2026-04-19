---
service: "deletion_service"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumDeletionServiceApp, continuumDeletionServiceDb]
---

# Architecture Context

## System Context

The Deletion Service sits within the `continuumSystem` as a GDPR compliance component in the Goods and Display platform. It acts as the central coordinator for the right-to-be-forgotten workflow: it receives account erasure events from the MBUS topic `jms.topic.gdpr.account.v1.erased`, fans out erasure tasks to each registered downstream service, executes those tasks via direct database access or outbound HTTP, and publishes per-task completion events to the MBUS queue `jms.queue.gdpr.account.v1.erased.complete`. Admin users interact with the service via a restricted REST API. The service is deployed in both NA (GCP us-central1) and EMEA (AWS eu-west-1) regions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Deletion Service | `continuumDeletionServiceApp` | Service | Java / Dropwizard | 1.0.x | GDPR Right to Forget service for Goods and Display. Hosts the REST API, MBUS consumer, Quartz scheduler, and all integration logic. |
| Deletion Service DB | `continuumDeletionServiceDb` | Database | PostgreSQL | (DaaS-managed) | Stores erase requests, per-service erasure state, status tracking, and SMS consent send IDs. |

## Components by Container

### Deletion Service (`continuumDeletionServiceApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Customer Resource | Exposes the admin HTTP API for submitting and querying erasure requests | Dropwizard Resource (JAX-RS) |
| Erase Message Worker | Subscribes to the GDPR erase topic and creates erasure request records on receipt of a message | MessageProcessor (JTier MBUS) |
| Create Customer Service | Creates the top-level erase request and per-service erase records in the database | Service |
| Retrieve Customer Service | Fetches erase request status and per-service completion state for a given customer ID | Service |
| Retrieve Failed Request Service | Queries for failed erase requests; used for metrics and alerting | Service |
| Erase Request Action | Orchestrates the per-request erasure workflow: loads pending services, invokes integrations, marks completion | Orchestrator |
| Message Publisher | Writes completion events to the MBUS erase-complete queue via JTier MessageWriter | Message Writer |
| Orders Integration | Anonymises fulfillment line item data in the Orders MySQL database | Integration |
| SMS Consent Integration | Triggers SMS consent deletion by calling the Rocketman API with an Attentive email request | Integration |
| Commerce Interface Integration | Erases Commerce Interface data via the CI PostgreSQL database (currently disabled) | Integration |
| Smart Routing Integration | Erases Smart Routing data via the SRS MySQL database (currently disabled) | Integration |
| Goods Inventory Integration | Erases inventory data via the GIS PostgreSQL database (currently disabled) | Integration |
| Rocketman Client | Retrofit HTTP client that POSTs to `/transactional/sendmessage` on the Rocketman transactional API | Retrofit Client |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumDeletionServiceApp` | `continuumDeletionServiceDb` | Reads and writes erase requests and per-service status | JDBC / PostgreSQL |
| MBUS `jms.topic.gdpr.account.v1.erased` | `continuumDeletionServiceApp` | Delivers account erase events (EraseMessage) | MBUS (JMS topic) |
| MBUS `jms.topic.scs.subscription.erasure` | `continuumDeletionServiceApp` | Delivers SMS consent erasure events | MBUS (JMS topic) |
| `continuumDeletionServiceApp` | `jms.queue.gdpr.account.v1.erased.complete` | Publishes per-service and per-request completion events | MBUS (JMS queue) |
| `continuumDeletionServiceApp` | Orders MySQL | Reads fulfillment IDs and anonymises fulfillment data | JDBC / MySQL |
| `continuumDeletionServiceApp` | Rocketman Transactional API `/transactional/sendmessage` | Sends Attentive SMS consent deletion email | REST / HTTP |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-deletion-createCustomerService-components`
- Dynamic view: `dynamic-erase-request-flow`
