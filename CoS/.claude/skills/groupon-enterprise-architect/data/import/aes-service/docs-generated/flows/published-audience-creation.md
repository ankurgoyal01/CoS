---
service: "aes-service"
title: "Published Audience Creation"
generated: "2026-03-03"
type: flow
flow_name: "published-audience-creation"
flow_type: synchronous
trigger: "POST /api/v1/publishedAudiences REST call"
participants:
  - "aesApiResources"
  - "aesDataAccessLayer"
  - "aesIntegrationClients"
  - "continuumAudienceExportPostgres"
  - "continuumCIAService"
architecture_ref: "components-continuumAudienceExportService"
---

# Published Audience Creation

## Summary

Published audiences are one-time (non-recurring) audience exports in contrast to scheduled audiences. When a caller invokes `POST /api/v1/publishedAudiences`, AES creates a published audience record in Postgres, optionally contacts CIA for segment details, and queues the audience for an immediate or near-term export run to the configured ad-network targets. The `scheduleType` is set to `PUBLISHED` rather than `SCHEDULED`.

## Trigger

- **Type**: api-call
- **Source**: Internal automation or Display Wizard UI calling `POST /api/v1/publishedAudiences`
- **Frequency**: On demand

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| API Resources | Receives and validates the published audience creation request | `aesApiResources` |
| Integration Clients | Retrieves audience segment details from CIA | `aesIntegrationClients` |
| Data Access Layer | Persists the published audience record | `aesDataAccessLayer` |
| AES Postgres | Stores the published audience metadata row | `continuumAudienceExportPostgres` |
| CIA | Provides published audience segment details and Hive table reference | `continuumCIAService` |

## Steps

1. **Receive creation request**: API receives `POST /api/v1/publishedAudiences` with `AudienceRequestPublished` body (name, ciaId, targets, country, criteriaId, attributes).
   - From: Caller
   - To: `aesApiResources`
   - Protocol: HTTPS/REST

2. **Fetch published audience details from CIA**: Calls CIA to retrieve the `PublishedAudienceDetails` — segment state, Hive table name, record counts.
   - From: `aesIntegrationClients`
   - To: `continuumCIAService`
   - Protocol: HTTPS/REST

3. **Persist published audience record**: Inserts into `aes_service.aes_metadata` with `scheduleType=PUBLISHED`, initial `jobStatus`, and target list.
   - From: `aesDataAccessLayer`
   - To: `continuumAudienceExportPostgres`
   - Protocol: JDBC

4. **Return audience record**: Responds with the created `AESAudience` object.
   - From: `aesApiResources`
   - To: Caller
   - Protocol: HTTPS/REST

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| CIA API failure | Error returned; audience not created | Logged as "Create Published Audience Failed in AES"; retry manually |
| Postgres insert failure | Error returned | Manual DB insert required (see Runbook) |

## Sequence Diagram

```
Caller -> aesApiResources: POST /api/v1/publishedAudiences {name, ciaId, targets, ...}
aesApiResources -> aesIntegrationClients: Fetch published audience segment from CIA
aesIntegrationClients -> continuumCIAService: GET published audience details
continuumCIAService --> aesIntegrationClients: PublishedAudienceDetails (hiveTable, state, ...)
aesIntegrationClients -> aesDataAccessLayer: Persist published audience record
aesDataAccessLayer -> continuumAudienceExportPostgres: INSERT aes_metadata row (scheduleType=PUBLISHED)
aesApiResources --> Caller: 200 AESAudience {id, scheduleType=PUBLISHED, ...}
```

## Related

- Related flows: [Scheduled Audience Export](scheduled-audience-export.md), [Scheduled Audience Creation](scheduled-audience-creation.md)
- API reference: [API Surface](../api-surface.md)
