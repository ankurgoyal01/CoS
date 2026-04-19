---
service: "email_campaign_management"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. CampaignManagement operates exclusively over synchronous REST (HTTPS/JSON). All integrations with downstream services — including Rocketman for delivery and RTAMS for audience resolution — are performed via synchronous HTTP calls at request time. No Kafka, RabbitMQ, SQS, or internal message bus consumers or producers were identified in the inventory.

## Published Events

> Not applicable. No async event publishing found.

## Consumed Events

> Not applicable. No async event consumption found.

## Dead Letter Queues

> Not applicable. No message queues or dead letter queues configured.
