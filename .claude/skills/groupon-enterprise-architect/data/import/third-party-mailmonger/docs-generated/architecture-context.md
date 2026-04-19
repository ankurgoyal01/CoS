---
service: "third-party-mailmonger"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumThirdPartyMailmongerService"
  containers: ["continuumThirdPartyMailmongerService"]
---

# Architecture Context

## System Context

Third Party Mailmonger sits within the Continuum platform as a privacy and compliance layer between Groupon consumers and third-party deal partners. During order checkout, the Third-Party Inventory Service (TPIS/Spaceman) calls Mailmonger to obtain a masked email address for the consumer, which is used in all subsequent partner communication. When a partner sends an email to the masked consumer address, SparkPost intercepts it via relay webhook and forwards it to Mailmonger for filtering and re-delivery to the real consumer address. The reverse path (consumer replying to a masked partner address) is handled symmetrically.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Third Party Mailmonger | `continuumThirdPartyMailmongerService` | Service | Java / JTier | 0.2.x | Intercepts, filters, masks, and sends partner emails; logs email content and delivery status |

## Components by Container

### Third Party Mailmonger (`continuumThirdPartyMailmongerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| API Resources (`thirdPartyMailmonger_apiResources`) | Exposes all REST endpoints and SparkPost webhook receivers | Dropwizard / JAX-RS |
| MessageBus Consumer (`thirdPartyMailmonger_messageBusConsumer`) | Consumes `MailmongerEmailMessage` events from MessageBus; triggers email processing pipeline | JTier MessageBus / ActiveMQ Artemis |
| Scheduler Jobs (`thirdPartyMailmonger_schedulerJobs`) | Runs Quartz jobs for retrying queued emails and scheduled send operations | Quartz |
| Users Service Poller (`usersServicePoller`) | Periodic polling task that refreshes user/partner data from users-service | Dropwizard Managed Task |
| Email Services (`emailServices`) | Core logic: filtering, transformation, saving, and sending of emails | Java |
| Email DAOs (`emailDaos`) | JDBI data access for all email-related database tables | JDBI3 |
| Users Service Client (`thirdPartyMailmonger_userServiceClient`) | Retrofit-based HTTP client for users-service API | Retrofit |
| MTA Client (`mtaClient`) | SMTP client for direct MTA email delivery | Jakarta Mail |
| SparkPost Client (`sparkpostClient`) | HTTP client wrapping SparkPost SDK for API-based email sending | SparkPost SDK 0.21 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumThirdPartyMailmongerService` | `continuumUsersService` | Fetches user and partner metadata (email addresses, IDs) | HTTP (Retrofit) |
| `continuumThirdPartyMailmongerService` | `messageBus` | Consumes mailmonger email processing messages | Mbus (ActiveMQ Artemis) |
| `continuumThirdPartyMailmongerService` | `daasPostgres` | Stores and retrieves email content, masked emails, and partner data | JDBC / PostgreSQL |
| `continuumThirdPartyMailmongerService` | `sparkpost` | Sends outbound emails via SparkPost API; receives relay webhook callbacks | HTTPS |
| `continuumThirdPartyMailmongerService` | `mta` | Delivers emails directly via SMTP as fallback carrier | SMTP (Jakarta Mail) |
| `thirdPartyMailmonger_apiResources` | `emailServices` | Handles REST and webhook requests | Direct |
| `thirdPartyMailmonger_messageBusConsumer` | `emailServices` | Processes message bus email events | Direct |
| `thirdPartyMailmonger_schedulerJobs` | `emailServices` | Triggers scheduled processing and retries | Direct |
| `emailServices` | `emailDaos` | Reads and writes email data | Direct |
| `emailServices` | `thirdPartyMailmonger_userServiceClient` | Looks up user and partner metadata | Direct |
| `emailServices` | `sparkpostClient` | Sends email via SparkPost | Direct |
| `emailServices` | `mtaClient` | Sends email via MTA | Direct |

## Architecture Diagram References

- System context: `contexts-third-party-mailmonger`
- Container: `containers-third-party-mailmonger`
- Component: `components-third-party-mailmonger-service`
