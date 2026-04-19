---
service: "transporter-itier"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

Transporter I-Tier does not publish or consume asynchronous events. The service is a synchronous request/response web application. All communication with its backend dependency (transporter-jtier) occurs via synchronous HTTP calls using the `gofer` client. Log shipping to Kafka is performed by infrastructure-layer Filebeat and Logstash sidecars and is not application-level event publishing.

## Published Events

> No evidence found in codebase.

This service does not publish async events.

## Consumed Events

> No evidence found in codebase.

This service does not consume async events.

## Dead Letter Queues

> No evidence found in codebase.

This service does not use dead letter queues.
