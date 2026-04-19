---
service: "lead-gen"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

LeadGen Service does not currently publish or consume events via an async messaging system (such as Kafka or the Groupon Message Bus). All orchestration is handled synchronously through n8n workflow triggers calling the LeadGen Service REST API, and all external integrations use request/response REST or API calls.

> This service does not publish or consume async events. All coordination between workflows and the service is performed via direct HTTP calls from n8n to the LeadGen Service API.

## Published Events

No async events are published by this service.

## Consumed Events

No async events are consumed by this service.

## Dead Letter Queues

Not applicable -- no async messaging is used.

## Future Considerations

If the lead pipeline scales or needs decoupled processing, consider introducing:
- Event-driven enrichment via a message queue (e.g., Kafka topic for enrichment requests)
- Outreach status change events for downstream analytics
- CRM sync completion events for sales workflow triggers
