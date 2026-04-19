---
service: "pact-broker"
title: "Contract Publishing"
generated: "2026-03-03"
type: flow
flow_name: "contract-publishing"
flow_type: synchronous
trigger: "Consumer CI pipeline publishes a new pact version"
participants:
  - "continuumPactBrokerHttpApi"
  - "continuumPactBrokerPersistence"
  - "continuumPactBrokerWebhookDispatcher"
  - "continuumPactBrokerPostgres"
  - "githubEnterprise"
  - "githubDotCom"
architecture_ref: "dynamic-pact-broker"
---

# Contract Publishing

## Summary

When a consumer service completes its test suite and generates a pact file, its CI pipeline publishes the contract to the Pact Broker. The broker persists the contract document, registers the consumer version, and triggers outbound webhook callbacks to notify provider CI pipelines that a new pact is available for verification. This flow is the entry point for all consumer-driven contract testing in Groupon.

## Trigger

- **Type**: api-call
- **Source**: Consumer service CI pipeline (e.g., a GitHub Actions or Jenkins job running after consumer tests pass)
- **Frequency**: On-demand (every consumer CI build that produces a new pact)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Consumer CI Pipeline | Initiates the publish by sending the pact JSON | External caller |
| HTTP API | Receives and validates the PUT request; coordinates persistence and webhook dispatch | `continuumPactBrokerHttpApi` |
| Persistence Adapter | Persists the pact document and version record to PostgreSQL | `continuumPactBrokerPersistence` |
| Pact Broker Postgres DB | Stores pacticipant, version, and pact content | `continuumPactBrokerPostgres` |
| Webhook Dispatcher | Dispatches outbound webhook callbacks after the pact is stored | `continuumPactBrokerWebhookDispatcher` |
| GitHub Enterprise | Receives webhook callback to trigger provider verification CI | `githubEnterprise` |
| GitHub.com | Receives webhook callback to trigger provider verification CI (public repos) | `githubDotCom` |

## Steps

1. **Receive publish request**: Consumer CI pipeline sends `PUT /pacts/provider/{provider}/consumer/{consumer}/version/{consumerVersion}` with the pact JSON body and basic-auth credentials.
   - From: Consumer CI Pipeline
   - To: `continuumPactBrokerHttpApi`
   - Protocol: REST (HTTPS on port 9292)

2. **Authenticate request**: HTTP API validates basic-auth credentials against `PACT_BROKER_BASIC_AUTH_USERNAME` / `PACT_BROKER_BASIC_AUTH_PASSWORD`.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerHttpApi` (in-process)
   - Protocol: Direct

3. **Persist contract**: HTTP API instructs Persistence Adapter to upsert the pacticipant records, consumer version, and pact document (keyed by SHA).
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerPersistence`
   - Protocol: Direct (in-process)

4. **Write to database**: Persistence Adapter writes pacticipant, version, and pact content rows to PostgreSQL.
   - From: `continuumPactBrokerPersistence`
   - To: `continuumPactBrokerPostgres`
   - Protocol: SQL (PostgreSQL)

5. **Return HTTP 201**: HTTP API returns `201 Created` (or `200 OK` for an existing pact) to the consumer CI pipeline.
   - From: `continuumPactBrokerHttpApi`
   - To: Consumer CI Pipeline
   - Protocol: REST (HTTPS)

6. **Trigger webhook dispatch**: HTTP API notifies the Webhook Dispatcher that a new pact has been published.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerWebhookDispatcher`
   - Protocol: Direct (in-process)

7. **Load webhook configuration**: Webhook Dispatcher reads configured webhooks for the consumer/provider pair from PostgreSQL.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `continuumPactBrokerPersistence` -> `continuumPactBrokerPostgres`
   - Protocol: Direct / SQL

8. **Dispatch callbacks**: Webhook Dispatcher sends outbound HTTP POST requests to allowed webhook targets.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `githubEnterprise` and/or `githubDotCom`
   - Protocol: HTTPS/webhook

9. **Record webhook execution**: Webhook Dispatcher writes the delivery outcome (success/failure) to the `triggered_webhooks` table.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `continuumPactBrokerPostgres`
   - Protocol: SQL (PostgreSQL)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid credentials (401) | HTTP API rejects request immediately | Consumer CI pipeline receives 401; publish fails |
| Database write failure | Persistence Adapter propagates exception; HTTP API returns 5xx | Consumer CI pipeline retries; no partial state stored |
| Webhook target not in allow-list | Webhook Dispatcher rejects configuration; callback not sent | Webhook silently skipped; contract is still stored |
| Webhook delivery failure (network) | Webhook Dispatcher records failure in `triggered_webhooks`; retries per pact-broker defaults | Contract is stored; CI notification may be delayed |

## Sequence Diagram

```
ConsumerCI -> PactBrokerHttpApi: PUT /pacts/provider/{p}/consumer/{c}/version/{v}
PactBrokerHttpApi -> PactBrokerPersistence: upsert pacticipant, version, pact
PactBrokerPersistence -> PostgreSQL: INSERT/UPDATE pacts, versions, pacticipants
PostgreSQL --> PactBrokerPersistence: OK
PactBrokerPersistence --> PactBrokerHttpApi: OK
PactBrokerHttpApi --> ConsumerCI: 201 Created
PactBrokerHttpApi -> WebhookDispatcher: notify "pact published"
WebhookDispatcher -> PostgreSQL: SELECT webhooks WHERE consumer/provider match
PostgreSQL --> WebhookDispatcher: webhook configs
WebhookDispatcher -> GitHubEnterprise: POST webhook callback
GitHubEnterprise --> WebhookDispatcher: 2xx OK
WebhookDispatcher -> PostgreSQL: INSERT triggered_webhooks (status=success)
```

## Related

- Architecture dynamic view: `dynamic-pact-broker`
- Related flows: [Verification Result Recording](verification-result-recording.md), [Webhook Dispatch](webhook-dispatch.md), [Deployment Safety Check](can-i-deploy.md)
