---
service: "okta"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

The Okta service does not use an asynchronous message bus (e.g., Kafka, RabbitMQ, or SQS) for its core workflows. Integration with Okta is synchronous: the `continuumOktaService` calls the Okta IdP OIDC and SCIM APIs directly and synchronously propagates results to `continuumUsersService`. SCIM provisioning events are delivered by Okta as inbound HTTP calls (webhook-style) rather than via a message queue.

## Published Events

> No evidence found in codebase. The service does not publish events to any message bus based on the available architecture DSL and service metadata.

## Consumed Events

> No evidence found in codebase. The service does not consume events from any message bus. SCIM provisioning updates are received as direct HTTP callbacks from the Okta IdP.

## Dead Letter Queues

> No evidence found in codebase. No message queue infrastructure is defined; dead-letter queues are not applicable.
