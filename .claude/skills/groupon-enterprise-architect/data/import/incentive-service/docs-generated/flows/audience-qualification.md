---
service: "incentive-service"
title: "Audience Qualification"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "audience-qualification"
flow_type: batch
trigger: "API call — POST /audience/qualify"
participants:
  - "continuumIncentiveService"
  - "incentiveApi"
  - "incentiveBackgroundJobs"
  - "incentiveDataAccess"
  - "incentiveMessaging"
  - "continuumIncentivePostgres"
  - "continuumIncentiveCassandra"
  - "extBigtableInstance_0f21"
  - "messageBus"
  - "continuumKafkaBroker"
architecture_ref: "dynamic-incentive-request-flow"
---

# Audience Qualification

## Summary

The audience qualification flow evaluates each user in a campaign's target population against the campaign's eligibility rules, producing a set of qualified users. The process is triggered via the API, executed asynchronously by an Akka actor job (active in `batch` mode), and completes by writing qualification results to Cassandra and publishing an `audience.qualified` event to Kafka. This enables downstream systems like the Messaging Service to activate campaign delivery to the qualified audience.

## Trigger

- **Type**: api-call
- **Source**: Campaign management system or internal batch orchestrator
- **Frequency**: Per campaign qualification run; triggered on-demand or by campaign lifecycle events

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Campaign Orchestrator | Initiates qualification for a specific campaign | — |
| Incentive Service (API) | Receives qualification request and enqueues the Akka job | `incentiveApi` |
| Background Jobs | Akka actor that executes the audience qualification sweep | `incentiveBackgroundJobs` |
| Incentive Data Access | Reads audience rules from PostgreSQL; reads user membership from Bigtable; writes results to Cassandra | `incentiveDataAccess` |
| Incentive Messaging | Publishes `audience.qualified` event to Kafka on sweep completion | `incentiveMessaging` |
| Incentive PostgreSQL | Holds audience rules and campaign configuration | `continuumIncentivePostgres` |
| Incentive Cassandra / Keyspaces | Receives bulk-written qualification results | `continuumIncentiveCassandra` |
| Google Cloud Bigtable | Provides high-throughput user audience membership data | `extBigtableInstance_0f21` (stub) |
| Message Bus | Delivers `user.population_update` events that feed into qualification data | `messageBus` |
| Kafka Broker | Receives `audience.qualified` event when sweep completes | `continuumKafkaBroker` |

## Steps

1. **Receive qualification request**: Campaign orchestrator calls `POST /audience/qualify` with campaign ID and qualification parameters.
   - From: Campaign Orchestrator
   - To: `incentiveApi`
   - Protocol: REST/HTTP

2. **Enqueue Akka qualification job**: `incentiveApi` submits the qualification job to the `incentiveBackgroundJobs` Akka actor and returns a job reference with status `accepted`.
   - From: `incentiveApi`
   - To: `incentiveBackgroundJobs`
   - Protocol: in-process (Akka message)

3. **Load audience rules**: The Akka actor reads the campaign's audience targeting rules and eligibility criteria from PostgreSQL.
   - From: `incentiveBackgroundJobs`
   - To: `continuumIncentivePostgres`
   - Protocol: JDBC/PostgreSQL

4. **Fetch user population data from Bigtable**: The actor reads bulk user audience membership data from Google Cloud Bigtable for the campaign's target segment.
   - From: `incentiveBackgroundJobs` (via `incentiveDataAccess`)
   - To: `extBigtableInstance_0f21`
   - Protocol: Bigtable SDK

5. **Incorporate user population updates**: `incentiveDataAccess` applies any pending `user.population_update` events from MBus to ensure the membership data reflects the latest user state.
   - From: `incentiveBackgroundJobs`
   - To: `messageBus` (event data, previously consumed)
   - Protocol: in-process (previously consumed MBus events)

6. **Run qualification algorithm per user**: The Akka actor evaluates each user against the audience rules, tagging each as qualified or disqualified. The feature flag `incentive.newQualificationEngine` controls which algorithm version runs.
   - From: `incentiveBackgroundJobs`
   - To: internal
   - Protocol: in-process

7. **Write qualification results to Cassandra**: Qualification outcomes are bulk-written to `continuumIncentiveCassandra` (or `continuumIncentiveKeyspaces` in cloud), keyed by campaign ID and user ID.
   - From: `incentiveBackgroundJobs` (via `incentiveDataAccess`)
   - To: `continuumIncentiveCassandra`
   - Protocol: Cassandra CQL

8. **Publish `audience.qualified` event**: `incentiveMessaging` publishes an `audience.qualified` event to Kafka containing the campaign ID, qualified user count, and sweep timestamp.
   - From: `incentiveMessaging`
   - To: `continuumKafkaBroker`
   - Protocol: Kafka

9. **Poll qualification status** (optional): Caller may poll `GET /audience/:campaignId/status` to check sweep progress before the completion event is received.
   - From: Campaign Orchestrator
   - To: `incentiveApi`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Bigtable read failure | Retry with backoff; fall back to MBus-derived population data if available | Partial qualification sweep; may miss users not in fallback data |
| Cassandra write failure | Retry writes; job retains in-progress state | Qualification results may be incomplete until writes succeed |
| Akka actor job failure | Actor restarts per supervision strategy; job status reflects failure | Caller must resubmit via `POST /audience/qualify` |
| Kafka publish failure | Retry publish; `audience.qualified` event eventually delivered | Downstream activation delayed |
| `incentive.newQualificationEngine` flag off | Falls back to legacy qualification algorithm | Different qualification results; no operational failure |

## Sequence Diagram

```
CampaignOrchestrator -> incentiveApi: POST /audience/qualify { campaignId: C }
incentiveApi -> incentiveBackgroundJobs: enqueue QualificationJob(C)
incentiveApi --> CampaignOrchestrator: 202 Accepted { jobId: J }
incentiveBackgroundJobs -> continuumIncentivePostgres: SELECT audience_rules WHERE campaign_id = C
continuumIncentivePostgres --> incentiveBackgroundJobs: audience rules
incentiveBackgroundJobs -> extBigtableInstance_0f21: read user membership for segment
extBigtableInstance_0f21 --> incentiveBackgroundJobs: user membership data
incentiveBackgroundJobs -> incentiveBackgroundJobs: run qualification algorithm for each user
incentiveBackgroundJobs -> continuumIncentiveCassandra: BATCH INSERT qualification_results for campaign C
continuumIncentiveCassandra --> incentiveBackgroundJobs: OK
incentiveBackgroundJobs -> incentiveMessaging: notify sweep complete
incentiveMessaging -> continuumKafkaBroker: publish audience.qualified { campaignId: C, qualifiedCount: N }
CampaignOrchestrator -> incentiveApi: GET /audience/C/status
incentiveApi --> CampaignOrchestrator: { status: "complete", qualifiedCount: N }
```

## Related

- Architecture dynamic view: `dynamic-incentive-request-flow`
- Related flows: [Campaign Approval Workflow](campaign-approval-workflow.md), [Incentive Redemption](incentive-redemption.md)
