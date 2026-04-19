---
service: "releasegen"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Releasegen does not publish or consume events via a message broker (no Kafka, RabbitMQ, SQS, or similar). All inter-system communication is performed via synchronous REST API calls. The service uses an internal polling worker (`JiraDeploymentSource`) that periodically queries the JIRA REST API for unprocessed RE-project release tickets and then calls the Deploybot REST API to retrieve deployment records. This polling loop is functionally similar to event consumption but is implemented as scheduled polling rather than message-driven consumption.

## Published Events

> No evidence found in codebase. Releasegen does not publish to any message bus or event stream.

## Consumed Events

> No evidence found in codebase. Releasegen does not subscribe to any message bus or event stream. Deployment triggers are sourced via periodic JIRA polling and direct REST API calls rather than async events.

## Dead Letter Queues

> Not applicable. No message broker is used.
