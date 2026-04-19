---
service: "message-service"
title: "Bigtable Scaling"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "bigtable-scaling"
flow_type: synchronous
trigger: "Operator calls POST /api/bigtable/scale to adjust Bigtable node capacity"
participants:
  - "messagingApiControllers"
  - "messagingCampaignOrchestration"
  - "messagingIntegrationClients"
  - "continuumMessagingBigtable"
architecture_ref: "dynamic-bigtable-scaling"
---

# Bigtable Scaling

## Summary

The Bigtable Scaling flow is an operational control plane action. An operator (or an automated process) sends a `POST /api/bigtable/scale` request to adjust the read and/or write node count for `continuumMessagingBigtable`. The service translates this into a GCP Bigtable administrative API call to resize the cluster. This flow is used proactively before large audience import jobs or reactively when throughput degradation is detected.

## Trigger

- **Type**: api-call
- **Source**: Operations engineer or automated scaling script calling `POST /api/bigtable/scale`
- **Frequency**: On demand (before large batch jobs, during peak periods, or in response to alerts)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Operator / Automation | Initiates the scaling request | — |
| API Controllers | Receives and validates the scale request | `messagingApiControllers` |
| Campaign Orchestration | Routes the scaling command to the appropriate integration client | `messagingCampaignOrchestration` |
| Integration Clients | Calls the GCP Bigtable admin API to apply the scaling change | `messagingIntegrationClients` |
| Messaging Bigtable | GCP Bigtable instance whose capacity is being adjusted | `continuumMessagingBigtable` |

## Steps

1. **Receive scaling request**: Operator or automation sends `POST /api/bigtable/scale` with target node count parameters (e.g., desired read nodes, desired write nodes, or cluster size).
   - From: Operator / Automation
   - To: `messagingApiControllers`
   - Protocol: REST / HTTP

2. **Validate scaling parameters**: API Controllers validates the requested parameters (node counts within allowed range, valid cluster identifier).
   - From: `messagingApiControllers`
   - To: `messagingCampaignOrchestration`
   - Protocol: Direct (in-process)

3. **Issue Bigtable resize request**: Integration Clients calls the GCP Bigtable admin API to update the cluster node count to the requested value.
   - From: `messagingCampaignOrchestration` -> `messagingIntegrationClients`
   - To: `continuumMessagingBigtable` (GCP Bigtable admin API)
   - Protocol: GCP Bigtable admin API

4. **Confirm scaling initiated**: GCP Bigtable acknowledges the request; node scaling begins asynchronously within GCP (actual capacity change is not instantaneous).
   - From: `continuumMessagingBigtable` (GCP API)
   - To: `messagingIntegrationClients`
   - Protocol: GCP API response

5. **Return response to caller**: API Controllers returns confirmation that the scaling request was accepted.
   - From: `messagingApiControllers`
   - To: Operator / Automation
   - Protocol: REST / HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid node count (below minimum or above maximum) | API Controllers returns 400 Bad Request | Scaling not applied |
| GCP Bigtable admin API error (permissions, quota) | Integration client propagates exception | Scaling fails; error response returned to caller; Bigtable remains at current capacity |
| GCP API timeout | Integration client timeout exception | Scaling request status unknown; operator should verify in GCP console |

## Sequence Diagram

```
Operator -> messagingApiControllers: POST /api/bigtable/scale { nodeCount: N }
messagingApiControllers -> messagingCampaignOrchestration: scaleBigtable(nodeCount)
messagingCampaignOrchestration -> messagingIntegrationClients: resizeBigtableCluster(nodeCount)
messagingIntegrationClients -> continuumMessagingBigtable: GCP Admin API: UpdateCluster(nodeCount)
continuumMessagingBigtable --> messagingIntegrationClients: 200 OK (scaling initiated)
messagingIntegrationClients --> messagingCampaignOrchestration: scaling accepted
messagingCampaignOrchestration --> messagingApiControllers: OK
messagingApiControllers --> Operator: 200 OK { status: "scaling initiated" }
```

## Related

- Architecture dynamic view: `dynamic-bigtable-scaling`
- Related flows: [Audience Assignment Batch](audience-assignment-batch.md), [Message Delivery — getmessages](message-delivery-getmessages.md)
- Data stores: see [Data Stores](../data-stores.md)
- Runbook: see [Runbook — Bigtable Throughput Degradation](../runbook.md)
