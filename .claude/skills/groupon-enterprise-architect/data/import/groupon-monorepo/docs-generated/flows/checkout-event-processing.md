---
service: "groupon-monorepo"
title: "Checkout Event Processing"
generated: "2026-03-03"
type: flow
flow_name: "checkout-event-processing"
flow_type: event-driven
trigger: "Kafka message from Continuum Janus pipeline"
participants:
  - "encoreTs"
  - "messageBus"
architecture_ref: "dynamic-checkout-event-processing"
---

# Checkout Event Processing

## Summary

This flow processes checkout events from the legacy Continuum platform's Janus analytics pipeline. Events are consumed from an external Kafka cluster by the Encore Kafka bridge service, published to an internal Encore Pub/Sub topic, and then processed by the checkout-events service which persists them to a PostgreSQL database for analytics and downstream use.

## Trigger

- **Type**: event
- **Source**: Kafka message produced by Continuum Janus tier-3 pipeline
- **Frequency**: Continuous, high-volume (per checkout event)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kafka Bridge Service | Consumes Kafka messages and republishes to Encore Pub/Sub | `encoreTs` (_core_system/kafka) |
| Checkout Events Service | Processes and persists checkout events | `encoreTs` (_tribe_core/checkout-events) |
| Janus Service | Janus analytics event correlation | `encoreTs` (_tribe_core/janus) |

## Steps

1. **Consume Kafka Message**: Kafka bridge service reads message from external Janus tier-3 Kafka topic
   - From: External Kafka cluster
   - To: `encoreTs` (kafka service)
   - Protocol: Kafka (kafkajs)

2. **Publish to Internal Topic**: Bridge service publishes deserialized event to Encore Pub/Sub
   - From: `encoreTs` (kafka service)
   - To: Pub/Sub topic `kafka-janus-tier3`
   - Protocol: Encore Pub/Sub

3. **Process Checkout Event**: Checkout events service subscribes and processes the event
   - From: Pub/Sub topic `kafka-janus-tier3`
   - To: `encoreTs` (checkout-events service)
   - Protocol: Encore Pub/Sub subscription

4. **Correlate with Janus**: Janus service correlates event with tier-3 analytics data
   - From: Pub/Sub topic `janus-tier3`
   - To: `encoreTs` (janus service)
   - Protocol: Encore Pub/Sub subscription

5. **Persist Event**: Checkout event data written to database
   - From: `encoreTs` (checkout-events service)
   - To: `checkoutDb` PostgreSQL database
   - Protocol: SQL (Drizzle ORM)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Kafka connection lost | Automatic reconnection with offset tracking | No data loss; resumes from last committed offset |
| Deserialization error | Log error; skip malformed message | Individual message dropped; processing continues |
| Database write failure | Encore Pub/Sub retry with backoff | Event retried until successful or max retries |
| Topic subscription failure | Service restart by Encore Cloud | Automatic recovery on service restart |

## Sequence Diagram

```
Continuum Janus -> Kafka Cluster: Produce checkout event
Kafka Bridge Service -> Kafka Cluster: Consume message (kafkajs)
Kafka Bridge Service -> PubSub: Publish kafka-janus-tier3
Checkout Events Service -> PubSub: Subscribe kafka-janus-tier3
Checkout Events Service -> Checkout DB: INSERT event record
Janus Service -> PubSub: Subscribe janus-tier3
Janus Service -> Janus: Process tier-3 analytics
```

## Related

- Architecture dynamic view: `dynamic-checkout-event-processing`
- Related flows: [Deal Creation and Publishing](deal-creation-publishing.md)
