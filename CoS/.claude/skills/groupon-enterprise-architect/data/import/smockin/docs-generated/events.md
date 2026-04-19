---
service: "smockin"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["activemq"]
---

# Events

## Overview

sMockin embeds an Apache ActiveMQ broker (`spring-boot-starter-activemq`, `activemq-broker`) to provide JMS queue simulation as part of its mock server capabilities. The broker runs in-process alongside the Spring Boot application. This allows development and QA teams to define mocked JMS queue endpoints that other services can publish to or consume from during testing. sMockin itself does not publish or consume business domain events externally — the ActiveMQ broker is a simulation facility, not a production messaging integration.

## Published Events

> No evidence found in codebase. sMockin does not publish events to external brokers. The embedded ActiveMQ instance serves as a simulation target for other services under test.

## Consumed Events

> No evidence found in codebase. sMockin does not consume events from external message systems. Inbound JMS messages are captured by the mock server engine as simulated traffic.

## Dead Letter Queues

> No evidence found in codebase. The embedded ActiveMQ broker is used for simulation only; production DLQ configuration is not present.

## Notes on Embedded ActiveMQ

- The embedded ActiveMQ broker is started as part of the `smockinApp` container lifecycle.
- JMS queue mock definitions are stored in `smockinDb` alongside HTTP mock definitions.
- Traffic from JMS producers hitting the embedded broker during testing is logged and visible in the admin UI via the SSE-based traffic log.
- The broker is not connected to any external ActiveMQ or message bus infrastructure.
