---
service: "proximity-notification-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The Proximity Notification Service does not publish or consume application-level async events directly. All notification delivery is synchronous: the service makes real-time HTTP calls to the Rocketman push service during geofence request processing. Log data is forwarded to a Kafka-backed ELK pipeline via a Logstash sidecar container, but this is an infrastructure-level concern (log shipping) rather than domain event messaging.

## Published Events

> No evidence found in codebase of domain-level events published to a message bus or topic.

## Consumed Events

> No evidence found in codebase of domain-level events consumed from a message bus or topic.

## Dead Letter Queues

> Not applicable — no event consumers are present.

## Log Stream (Infrastructure)

While not a domain event system, the service writes structured logs to two log files that are shipped to Kafka via a Logstash sidecar:

| Log File | Kafka Topic Feed | Content |
|----------|-----------------|---------|
| `mobile_proximity_locations.log` | `mobile_proximity_locations` index in ELK | Geofence request and notification send records |
| `finch.log` | `tracky` index in ELK | Finch A/B experiment and metric events |

Log shipping is configured per-environment in `.meta/deployment/cloud/components/app/*.yml` via Logstash ConfigMaps. Kafka endpoints differ by environment:
- Staging (AWS): `kafka-grpn-producer.grpn-dse-stable.us-west-2.aws.groupondev.com:9094`
- Production US (AWS): `kafka-grpn-producer.grpn-dse-prod.us-west-2.aws.groupondev.com:9094`
- Production EMEA (GCP): `kafka-grpn-kafka-bootstrap.kafka-production.svc.cluster.local:9093`
