---
service: "ams"
title: "Sourced Audience Calculation"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "sourced-audience-calculation"
flow_type: asynchronous
trigger: "Schedule trigger or API call to initiate audience computation"
participants:
  - "ams_audienceOrchestration"
  - "ams_jobLaunchers"
  - "ams_integrationClients"
  - "ams_persistenceLayer"
  - "continuumAudienceManagementDatabase"
  - "livyGateway"
architecture_ref: "dynamic-ams-audience-calculation"
---

# Sourced Audience Calculation

## Summary

This flow computes audience membership for a sourced audience by submitting a Spark job to the Livy Gateway. AMS constructs the job specification from persisted audience and criteria definitions, tracks execution state in MySQL, and polls YARN for job completion. On success, the resulting audience data is used as the input to the published audience publishing flow.

## Trigger

- **Type**: schedule or api-call
- **Source**: Audience Schedule Execution flow (scheduled trigger) or direct API invocation requesting audience recalculation
- **Frequency**: Per schedule definition; typically hourly or daily depending on audience configuration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Orchestration | Coordinates computation lifecycle and state transitions | `ams_audienceOrchestration` |
| Job Launchers | Constructs and submits Spark job specification | `ams_jobLaunchers` |
| Integration Clients | Calls Livy Gateway REST API to submit job | `ams_integrationClients` |
| Persistence Layer | Loads audience/criteria context; updates execution state | `ams_persistenceLayer` |
| Audience Management Database | Provides audience definitions and stores execution records | `continuumAudienceManagementDatabase` |
| Livy Gateway | Receives job submission and manages Spark execution | `livyGateway` |

## Steps

1. **Load audience computation context**: Audience Orchestration instructs Persistence Layer to fetch the audience definition, criteria, and scheduling context.
   - From: `ams_audienceOrchestration`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

2. **Read audience and criteria from database**: Persistence Layer retrieves audience definition and resolved criteria from MySQL.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

3. **Transition audience to computing state**: Persistence Layer updates audience lifecycle state to "computing" and records execution start.
   - From: `ams_persistenceLayer`
   - To: `continuumAudienceManagementDatabase`
   - Protocol: JPA/JDBC

4. **Construct Spark job specification**: Job Launchers builds the Spark job payload from the audience definition and criteria, including input data references and output configuration.
   - From: `ams_jobLaunchers`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

5. **Submit Spark job to Livy Gateway**: Integration Clients POSTs the job specification to the Livy Gateway REST endpoint.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

6. **Persist job reference**: Integration Clients updates execution state with the Livy job ID in MySQL via Persistence Layer.
   - From: `ams_integrationClients`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

7. **Poll job status from YARN**: Job Launchers periodically polls YARN via Integration Clients to check Spark job completion status.
   - From: `ams_integrationClients`
   - To: `livyGateway`
   - Protocol: REST/HTTP

8. **Update execution state on completion**: On job success, Integration Clients updates the audience execution state to "computed" in MySQL.
   - From: `ams_integrationClients`
   - To: `ams_persistenceLayer`
   - Protocol: In-process

9. **Trigger published audience flow**: Audience Orchestration transitions the audience to the publishing phase, handing off to the Published Audience Publishing flow.
   - From: `ams_audienceOrchestration`
   - To: `ams_jobLaunchers`
   - Protocol: In-process

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Livy Gateway unreachable | Job submission fails; exception logged | Audience remains in pending state; retried on next schedule trigger |
| Spark job fails in YARN | Job failure status detected on poll | Audience state set to "failed"; error recorded in audit log; retry policy applied |
| Job polling timeout | Maximum poll attempts exceeded | Audience state set to "timed-out"; alert surfaced |
| Database update failure during state transition | Exception propagated | Inconsistent execution state; manual reconciliation may be required |

## Sequence Diagram

```
ams_audienceOrchestration -> ams_persistenceLayer: load audience context
ams_persistenceLayer -> continuumAudienceManagementDatabase: SELECT audience + criteria
continuumAudienceManagementDatabase --> ams_persistenceLayer: audience data
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE state = computing
ams_persistenceLayer --> ams_audienceOrchestration: context loaded
ams_audienceOrchestration -> ams_jobLaunchers: initiate Spark job
ams_jobLaunchers -> ams_integrationClients: submit job
ams_integrationClients -> livyGateway: POST /batches (job spec)
livyGateway --> ams_integrationClients: job ID
ams_integrationClients -> ams_persistenceLayer: store job ID
ams_integrationClients -> livyGateway: GET /batches/{id} (poll status)
livyGateway --> ams_integrationClients: status = success
ams_integrationClients -> ams_persistenceLayer: UPDATE state = computed
ams_persistenceLayer -> continuumAudienceManagementDatabase: UPDATE execution record
ams_audienceOrchestration -> ams_jobLaunchers: trigger publishing phase
```

## Related

- Architecture dynamic view: `dynamic-ams-audience-calculation`
- Related flows: [Audience Schedule Execution](audience-schedule-execution.md), [Published Audience Publishing](published-audience-publishing.md), [Batch Optimization](batch-optimization.md)
