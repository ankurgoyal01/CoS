---
service: "ams"
title: "Audience Export Orchestration"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "audience-export-orchestration"
flow_type: asynchronous
trigger: "API call (POST /export/*) or published audience job completion"
participants:
  - "ams_apiResources"
  - "ams_audienceOrchestration"
  - "ams_jobLaunchers"
  - "ams_integrationClients"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
  - "livyGateway"
  - "bigtableCluster"
  - "cassandraCluster"
architecture_ref: "dynamic-ams-audience-calculation"
---

# Audience Export Orchestration

## Summary

This flow orchestrates the export of computed audience data to downstream storage targets — Bigtable, Cassandra, and MySQL. It is triggered either via the export API for on-demand exports or automatically following published audience computation. AMS constructs an export job specification, submits it via Livy Gateway, monitors completion, and records the export result in the MySQL audit and export records.

## Trigger

- **Type**: api-call or event (internal)
- **Source**: Caller invoking `POST /export/*` for on-demand export, or Published Audience Publishing flow triggering automatic export
- **Frequency**: On-demand or per published audience computation cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives on-demand export request | `ams_apiResources` |
| Audience Orchestration | Coordinates export lifecycle and state | `ams_audienceOrchestration` |
| Job Launchers | Constructs and submits export Spark job | `ams_jobLaunchers` |
| Integration Clients | Calls Livy Gateway; reads from Bigtable/Cassandra | `ams_integrationClients` |
| Persistence Layer | Records export state and results in MySQL | `ams_persistenceLayer` |
| Audience Management Database | Stores export records and audit log | `continuumAudienceManagementDatabase` |
| Livy Gateway | Receives and executes the export Spark job | `livyGateway` |
| Bigtable Cluster | Receives exported audience attribute data | `bigtableCluster` |
| Cassandra Cluster | Receives exported published audience records | `cassandraCluster` |

## Steps

1. **Receive export trigger**: API Resources receives `POST /export/*` (on-demand) or Audience Orchestration receives internal handoff from Published Audience Publishing flow.
   - From: `caller` or internal flow
   - To: `ams_apiResources` or `ams_audienceOrchestration`
   - Protocol: REST/JSON or in-process

2. **Validate export request and load audience context**: Audience Orchestration validates the export specification and loads the target audience definition and current state from the Persistence Layer.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

3. **Read audience state from MySQL**: Persistence Layer fetches the audience definition and confirms the audience is in a publishable/computed state.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

4. **Create export record**: Persistence Layer creates an export record in MySQL with status "pending".
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

5. **Construct export job specification**: Job Launchers builds the Spark export job payload, specifying the audience data source, target stores (Bigtable, Cassandra), and export parameters.
   - From: `ams_jobLaunchers`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

6. **Submit export job to Livy Gateway**: Integration Clients POSTs the export job specification to Livy Gateway.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

7. **Spark job writes to Bigtable**: The Spark job writes audience attribute data to `bigtableCluster`.
   - From: `livyGateway` (Spark executor)
   - To: `bigtableCluster`
   - Protocol: Bigtable client (gRPC)

8. **Spark job writes to Cassandra**: The Spark job writes published audience membership records to `cassandraCluster`.
   - From: `livyGateway` (Spark executor)
   - To: `cassandraCluster`
   - Protocol: Cassandra driver

9. **Poll export job completion**: Integration Clients polls Livy/YARN until the export job completes.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

10. **Update export record to completed**: Persistence Layer updates the export record in MySQL to "completed" and writes the export completion audit log entry.
    - From: `ams_persistenceLayer`
    - To: `continuumAudienceManagementDatabase`
    - Protocol: JPA/JDBC

11. **Return export result (on-demand path)**: API Resources returns the export job ID and status to the original caller.
    - From: `ams_apiResources`
    - To: `caller`
    - Protocol: REST/JSON (HTTP 202 Accepted)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Audience not in exportable state | Validation fails at Audience Orchestration | HTTP 422 Unprocessable Entity or internal error |
| Livy Gateway unreachable | Job submission fails; exception logged | Export record remains "pending"; manual retry required |
| Spark export job fails | Failure detected on status poll | Export record set to "failed"; audit log updated |
| Bigtable write failure (Spark) | Spark job fails; propagated to AMS | Export retried on next trigger |
| Cassandra write failure (Spark) | Spark job fails; propagated to AMS | Export retried on next trigger |
| MySQL export record update fails | Exception logged | Export state inconsistency; may require manual reconciliation |

## Sequence Diagram

```
caller -> ams_apiResources: POST /export/* (export spec)
ams_apiResources -> ams_audienceOrchestration: validate and load context
ams_audienceOrchestration -> ams_persistenceLayer: load audience state
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT audience
continuumAudienceManagementDatabase --> ams_persistenceLayer: audience state
ams_persistenceLayer -> continuumAudienceManagementDatabase: INSERT export record (pending)
ams_audienceOrchestration -> ams_jobLaunchers: construct export job
ams_jobLaunchers -> ams_integrationClients: submit export job
ams_integrationClients -> livyGateway: POST /batches (export job spec)
livyGateway --> ams_integrationClients: export job ID
livyGateway -> bigtableCluster: write audience attributes (Spark)
livyGateway -> cassandraCluster: write audience records (Spark)
ams_integrationClients -> livyGateway: GET /batches/{id} (poll)
livyGateway --> ams_integrationClients: status = success
ams_integrationClients -> ams_persistenceLayer: UPDATE export = completed
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE + audit log
ams_apiResources --> caller: HTTP 202 (export job ID, status)
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Published Audience Publishing](published-audience-publishing.md), [Sourced Audience Calculation](sourced-audience-calculation.md)
