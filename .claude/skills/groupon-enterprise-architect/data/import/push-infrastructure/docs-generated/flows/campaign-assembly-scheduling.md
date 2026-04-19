---
service: "push-infrastructure"
title: "Campaign Assembly and Scheduling"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "campaign-assembly-scheduling"
flow_type: scheduled
trigger: "HTTP POST to /schedule, or Quartz job trigger at configured campaign time"
participants:
  - "continuumPushInfrastructureService"
  - "externalTransactionalDatabase_3f1a"
  - "externalRedisCluster_5b2e"
architecture_ref: "dynamic-campaign-assembly-scheduling"
---

# Campaign Assembly and Scheduling

## Summary

The Campaign Assembly and Scheduling flow manages time-delayed and cron-based bulk message delivery. Upstream campaign services submit a campaign schedule via the `/schedule` REST endpoint; Push Infrastructure persists the schedule to the transactional database and registers a Quartz job. At the scheduled trigger time, Quartz fires the job, which assembles the per-user message queue entries and distributes them into Redis delivery queues for processing by the queue processor workers.

## Trigger

- **Type**: api-call (schedule registration) followed by schedule (Quartz job execution)
- **Source**: Upstream campaign orchestration service (registration); Quartz scheduler (execution)
- **Frequency**: Per campaign schedule; may be one-shot or recurring (cron)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign orchestration service | Submits campaign schedule via REST | — |
| Push Infrastructure Service | Receives schedule request, registers Quartz job, assembles and enqueues messages at trigger time | `continuumPushInfrastructureService` |
| Transactional Database | Persists campaign schedule metadata and Quartz job state | `externalTransactionalDatabase_3f1a` |
| Redis Cluster | Receives batch of per-user delivery queue entries at campaign fire time | `externalRedisCluster_5b2e` |

## Steps

### Phase 1 — Schedule Registration (synchronous)

1. **Receive schedule request**: Campaign service submits HTTP POST to `/schedule` with campaign metadata (campaignId, templateId, audience parameters, target channels, scheduled time or cron expression)
   - From: `campaign orchestration service`
   - To: `continuumPushInfrastructureService`
   - Protocol: REST / HTTP

2. **Persist campaign record**: Writes campaign schedule record to transactional database with status `SCHEDULED`
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

3. **Register Quartz job**: Creates and schedules a Quartz trigger for the campaign's target send time (simple trigger for one-shot, cron trigger for recurring)
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (Quartz scheduler — internal)
   - Protocol: internal (Quartz 2.2.1 API)

4. **Return schedule confirmation**: Returns HTTP 200/202 with scheduleId to the campaign service
   - From: `continuumPushInfrastructureService`
   - To: `campaign orchestration service`
   - Protocol: REST / HTTP

### Phase 2 — Campaign Execution (scheduled / async)

5. **Quartz fires campaign job**: At the scheduled time, Quartz fires the registered trigger and invokes the campaign job handler
   - From: `continuumPushInfrastructureService` (Quartz scheduler)
   - To: `continuumPushInfrastructureService` (campaign job handler)
   - Protocol: internal

6. **Retrieve campaign record**: Reads campaign metadata (templateId, audience, channels) from transactional database
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

7. **Assemble per-user message jobs**: For each user in the campaign audience, assembles a message job with userId, channel, templateId, and data context
   - From: `continuumPushInfrastructureService`
   - To: `continuumPushInfrastructureService` (internal)
   - Protocol: internal

8. **Bulk-enqueue to Redis delivery queues**: Pushes all assembled message jobs to Redis per-channel delivery queues
   - From: `continuumPushInfrastructureService`
   - To: `externalRedisCluster_5b2e`
   - Protocol: Redis (jedis)

9. **Update campaign status**: Updates campaign record in transactional database to status `ENQUEUED` or `IN_PROGRESS`
   - From: `continuumPushInfrastructureService`
   - To: `externalTransactionalDatabase_3f1a`
   - Protocol: JDBC (MyBatis)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid schedule request (missing fields) | Return HTTP 400 | Campaign not scheduled; caller must fix and resubmit |
| Database write failure during registration | Return HTTP 500 | Campaign not registered; caller should retry |
| Quartz job registration failure | Log error; campaign record remains in `SCHEDULED` state without Quartz trigger | Campaign will not fire; requires investigation |
| Campaign execution failure (partial audience) | Log per-user errors; record in error store | Failed users available for retry via `/errors/retry` |
| Redis bulk-enqueue failure | Log error; update campaign status to `ERROR` | Requires manual investigation and retry |

## Sequence Diagram

```
CampaignService -> continuumPushInfrastructureService: POST /schedule {campaignId, templateId, audience, channel, scheduleTime}
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: INSERT campaign record (status=SCHEDULED)
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: campaign record created
continuumPushInfrastructureService -> continuumPushInfrastructureService: Quartz.scheduleJob(trigger at scheduleTime)
continuumPushInfrastructureService --> CampaignService: HTTP 202 Accepted {scheduleId}

[... at scheduled time ...]

continuumPushInfrastructureService -> continuumPushInfrastructureService: Quartz fires campaign job
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: SELECT campaign metadata by campaignId
externalTransactionalDatabase_3f1a --> continuumPushInfrastructureService: campaign record
continuumPushInfrastructureService -> continuumPushInfrastructureService: Assemble per-user message jobs
continuumPushInfrastructureService -> externalRedisCluster_5b2e: RPUSH delivery_queue:{channel} [{messageJob}...] (batch)
externalRedisCluster_5b2e --> continuumPushInfrastructureService: queue entries added
continuumPushInfrastructureService -> externalTransactionalDatabase_3f1a: UPDATE campaign (status=ENQUEUED)
```

## Related

- Architecture dynamic view: `dynamic-campaign-assembly-scheduling`
- Related flows: [Message Processing and Delivery](message-processing-delivery.md), [Message Enqueue](message-enqueue.md), [Campaign Stats Aggregation](campaign-stats-aggregation.md)
