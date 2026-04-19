---
service: "ams"
title: "Published Audience Publishing"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "published-audience-publishing"
flow_type: asynchronous
trigger: "Sourced audience Spark job completion"
participants:
  - "ams_audienceOrchestration"
  - "ams_jobLaunchers"
  - "ams_integrationClients"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
  - "kafkaBroker"
  - "cassandraCluster"
architecture_ref: "dynamic-ams-audience-calculation"
---

# Published Audience Publishing

## Summary

This flow transitions a successfully computed sourced audience into a published state and notifies downstream consumers. AMS writes the published audience record to Cassandra, updates the audience lifecycle state in MySQL, and publishes an `audience_ams_pa_create` event to the Kafka topic. This makes the computed audience available to ads targeting systems and CRM pipelines.

## Trigger

- **Type**: event (internal, following sourced audience Spark job success)
- **Source**: Sourced Audience Calculation flow — handoff from `ams_audienceOrchestration` after job completion
- **Frequency**: Per sourced audience computation cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Orchestration | Coordinates publish lifecycle and state transitions | `ams_audienceOrchestration` |
| Job Launchers | Orchestrates publish job submission to Livy | `ams_jobLaunchers` |
| Integration Clients | Writes to Cassandra and publishes to Kafka | `ams_integrationClients` |
| Persistence Layer | Updates published audience state in MySQL | `ams_persistenceLayer` |
| Audience Management Database | Stores published audience metadata and state | `continuumAudienceManagementDatabase` |
| Kafka Broker | Receives `audience_ams_pa_create` event | `kafkaBroker` |
| Cassandra Cluster | Stores published audience records for downstream reads | `cassandraCluster` |

## Steps

1. **Receive publish handoff**: Audience Orchestration receives the computed audience result from the Sourced Audience Calculation flow and initiates the publish sequence.
   - From: `ams_audienceOrchestration`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

2. **Submit publish Spark job to Livy**: Job Launchers constructs the publish job specification and submits it via Integration Clients to Livy Gateway to materialize the audience into Cassandra.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

3. **Spark job writes to Cassandra**: The Spark job (orchestrated via Livy) writes the computed audience member records and metadata to `cassandraCluster`.
   - From: `livyGateway` (Spark executor)
   - To: `cassandraCluster`
   - Protocol: Cassandra driver

4. **Poll publish job completion**: Integration Clients polls Livy/YARN until the publish job completes successfully.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

5. **Update audience state to published**: Integration Clients updates the audience lifecycle state in MySQL to "published" via the Persistence Layer.
   - From: `ams_integrationClients`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

6. **Write published state to database**: Persistence Layer executes UPDATE against `continuumAudienceManagementDatabase` and records the publish event in the audit log.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

7. **Publish Kafka event**: Integration Clients produces an `audience_ams_pa_create` message to the Kafka broker, carrying audience ID and publish metadata.
   - From: `ams_integrationClients`
   - To: `kafkaBroker`
   - Protocol: Kafka producer

8. **Event delivered to consumers**: Kafka broker delivers the event to subscribed consumers (ads targeting systems, CRM pipelines).
   - From: `kafkaBroker`
   - To: downstream consumers
   - Protocol: Kafka consumer

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Cassandra write failure (Spark job) | Spark job fails; detected on status poll | Audience remains in "computed" state; publish retried |
| Livy Gateway unreachable for publish job | Submission fails; exception logged | Publish deferred; retry on next schedule or manual trigger |
| Kafka publish failure | Exception on producer send | `audience_ams_pa_create` not delivered; downstream systems not notified; no DLQ evidence found |
| MySQL state update failure | Exception propagated | Audience state inconsistency; may be reconciled on next health check cycle |

## Sequence Diagram

```
ams_audienceOrchestration -> ams_jobLaunchers: initiate publish
ams_jobLaunchers -> ams_integrationClients: submit publish job
ams_integrationClients -> livyGateway: POST /batches (publish job spec)
livyGateway --> ams_integrationClients: publish job ID
livyGateway -> cassandraCluster: write audience member records (Spark)
ams_integrationClients -> livyGateway: GET /batches/{id} (poll)
livyGateway --> ams_integrationClients: status = success
ams_integrationClients -> ams_persistenceLayer: update state = published
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE + audit log
ams_integrationClients -> kafkaBroker: produce audience_ams_pa_create
kafkaBroker --> downstream consumers: deliver event
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Sourced Audience Calculation](sourced-audience-calculation.md), [Audience Export Orchestration](audience-export-orchestration.md)
