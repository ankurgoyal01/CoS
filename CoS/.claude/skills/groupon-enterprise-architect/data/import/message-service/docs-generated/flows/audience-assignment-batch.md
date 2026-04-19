---
service: "message-service"
title: "Audience Assignment Batch"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "audience-assignment-batch"
flow_type: batch
trigger: "Dispatched by messagingKafkaConsumers after receiving ScheduledAudienceRefreshed event"
participants:
  - "messagingAudienceImportJobs"
  - "messagingIntegrationClients"
  - "messagingPersistenceAdapters"
  - "continuumAudienceManagementService"
  - "continuumMessagingBigtable"
  - "continuumMessagingCassandra"
architecture_ref: "dynamic-audience-assignment-batch"
---

# Audience Assignment Batch

## Summary

The Audience Assignment Batch flow rebuilds the user-campaign assignment store for a given audience. Akka actor jobs (`messagingAudienceImportJobs`) download audience export files from GCP Storage or HDFS (sourced via AMS), parse the member lists, and perform bulk writes of user-campaign assignment records into Bigtable (primary) or Cassandra (legacy). This batch process is the mechanism by which message targeting stays synchronized with audience membership changes.

## Trigger

- **Type**: event (dispatched programmatically)
- **Source**: `messagingKafkaConsumers` delivers a `ScheduledAudienceRefreshed` event to `messagingAudienceImportJobs` after consuming it from Kafka
- **Frequency**: Per audience refresh event; scheduled cadence driven by upstream audience pipeline

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Audience Import Jobs | Akka actors that orchestrate the import and assignment write process | `messagingAudienceImportJobs` |
| Integration Clients | Calls AMS to fetch export metadata; downloads export files from storage | `messagingIntegrationClients` |
| AMS | Provides audience export metadata (file location, format, audience attributes) | `continuumAudienceManagementService` |
| GCP Storage / HDFS | Storage layer holding the audience export files | — |
| Persistence Adapters | Writes assignment records to Bigtable or Cassandra | `messagingPersistenceAdapters` |
| Messaging Bigtable | Primary write target for user-campaign assignments (cloud) | `continuumMessagingBigtable` |
| Messaging Cassandra | Legacy write target for user-campaign assignments | `continuumMessagingCassandra` |

## Steps

1. **Receive dispatch from Kafka consumer**: `messagingKafkaConsumers` delivers the audience ID from the `ScheduledAudienceRefreshed` event to an `messagingAudienceImportJobs` Akka actor.
   - From: `messagingKafkaConsumers`
   - To: `messagingAudienceImportJobs`
   - Protocol: Direct (in-process, actor message)

2. **Fetch export metadata from AMS**: Integration Clients queries AMS to obtain the location and format of the audience export file for the given audience ID.
   - From: `messagingAudienceImportJobs` -> `messagingIntegrationClients`
   - To: `continuumAudienceManagementService`
   - Protocol: REST

3. **Download audience export file**: Integration Clients retrieves the export file from GCP Storage or HDFS using the path returned by AMS.
   - From: `messagingIntegrationClients`
   - To: GCP Storage / HDFS
   - Protocol: GCP Storage SDK / HDFS client

4. **Parse audience member list**: Audience Import Jobs parses the downloaded file to extract the list of user IDs (and any per-user attributes) belonging to the audience.
   - From: `messagingAudienceImportJobs`
   - To: (in-process parsing)
   - Protocol: Direct

5. **Resolve campaigns for this audience**: Audience Import Jobs retrieves the list of active campaigns associated with this audience ID.
   - From: `messagingAudienceImportJobs` -> `messagingPersistenceAdapters`
   - To: `continuumMessagingMySql`
   - Protocol: JDBC

6. **Bulk write assignment records**: Persistence Adapters performs bulk upserts of user-campaign assignment rows into the selected datastore (Bigtable for cloud environments, Cassandra for legacy environments).
   - From: `messagingPersistenceAdapters`
   - To: `continuumMessagingBigtable` or `continuumMessagingCassandra`
   - Protocol: GCP Bigtable API / CQL

7. **Job completes**: The Akka actor signals completion; the `ScheduledAudienceRefreshed` event is acknowledged on the Kafka consumer.
   - From: `messagingAudienceImportJobs`
   - To: `messagingKafkaConsumers`
   - Protocol: Direct (actor reply)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| AMS unavailable | Integration client exception; actor fails | Akka supervisor may retry; stale assignments remain until next successful run |
| Export file not found in GCP Storage / HDFS | Download exception; actor fails | Assignment not updated; retry on next `ScheduledAudienceRefreshed` event |
| Bigtable write failure | Persistence adapter exception; actor fails | Partial assignments may be written; retry required |
| Cassandra write failure (legacy) | Persistence adapter exception | Same as Bigtable failure path |
| Actor failure (uncaught exception) | Akka supervisor restarts the actor per supervision strategy | Event may be reprocessed; idempotent bulk-replace behavior limits data corruption |

## Sequence Diagram

```
messagingKafkaConsumers -> messagingAudienceImportJobs: dispatch(audienceId)
messagingAudienceImportJobs -> messagingIntegrationClients: getExportMetadata(audienceId)
messagingIntegrationClients -> continuumAudienceManagementService: GET /audience/:id/export
continuumAudienceManagementService --> messagingIntegrationClients: exportFilePath
messagingIntegrationClients -> GCPStorage: downloadFile(exportFilePath)
GCPStorage --> messagingIntegrationClients: audienceExportFile
messagingAudienceImportJobs -> messagingPersistenceAdapters: loadCampaignsForAudience(audienceId)
messagingPersistenceAdapters -> continuumMessagingMySql: SELECT campaigns WHERE audienceId=X
continuumMessagingMySql --> messagingPersistenceAdapters: campaign list
messagingAudienceImportJobs -> messagingPersistenceAdapters: bulkWriteAssignments(users, campaigns)
messagingPersistenceAdapters -> continuumMessagingBigtable: UPSERT assignment rows
continuumMessagingBigtable --> messagingPersistenceAdapters: OK
messagingAudienceImportJobs --> messagingKafkaConsumers: job complete
```

## Related

- Architecture dynamic view: `dynamic-audience-assignment-batch`
- Related flows: [Scheduled Audience Refresh](scheduled-audience-refresh.md), [Message Delivery — getmessages](message-delivery-getmessages.md)
- Events consumed: see [Events](../events.md)
