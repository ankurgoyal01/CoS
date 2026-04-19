---
service: "pact-broker"
title: "Webhook Dispatch"
generated: "2026-03-03"
type: flow
flow_name: "webhook-dispatch"
flow_type: asynchronous
trigger: "Internal pact lifecycle event (pact published or verification result recorded)"
participants:
  - "continuumPactBrokerWebhookDispatcher"
  - "continuumPactBrokerPersistence"
  - "continuumPactBrokerPostgres"
  - "githubEnterprise"
  - "githubDotCom"
architecture_ref: "dynamic-pact-broker"
---

# Webhook Dispatch

## Summary

Whenever a significant pact lifecycle event occurs (a new pact is published or a verification result is recorded), the Pact Broker internally triggers its Webhook Dispatcher component. The dispatcher loads matching webhook configurations from the database, constructs outbound HTTP POST requests, and delivers them to allow-listed hosts (`github.groupondev.com` and `github.com`). This mechanism drives CI pipeline automation — for example, automatically triggering provider verification builds when a consumer publishes a new pact.

## Trigger

- **Type**: event (internal pact lifecycle event)
- **Source**: `continuumPactBrokerHttpApi` after successfully persisting a pact or verification result
- **Frequency**: On-demand (triggered by every qualifying API write operation)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| HTTP API | Detects the lifecycle event and notifies the Webhook Dispatcher | `continuumPactBrokerHttpApi` |
| Webhook Dispatcher | Loads webhook configs, executes outbound HTTP callbacks, records results | `continuumPactBrokerWebhookDispatcher` |
| Persistence Adapter | Provides webhook configuration reads and execution state writes | `continuumPactBrokerPersistence` |
| Pact Broker Postgres DB | Stores webhook definitions and triggered webhook execution history | `continuumPactBrokerPostgres` |
| GitHub Enterprise | Receives outbound webhook POST callback for internal CI pipelines | `githubEnterprise` |
| GitHub.com | Receives outbound webhook POST callback for public CI pipelines | `githubDotCom` |

## Steps

1. **Lifecycle event detected**: HTTP API completes persisting a pact or verification result and signals the Webhook Dispatcher with the event type and relevant identifiers (consumer, provider, version).
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerWebhookDispatcher`
   - Protocol: Direct (in-process)

2. **Load webhook configurations**: Webhook Dispatcher queries Persistence Adapter for all webhooks configured for the consumer/provider pair and event type.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `continuumPactBrokerPersistence`
   - Protocol: Direct (in-process)

3. **Fetch from database**: Persistence Adapter retrieves matching webhook rows from PostgreSQL.
   - From: `continuumPactBrokerPersistence`
   - To: `continuumPactBrokerPostgres`
   - Protocol: SQL (PostgreSQL)

4. **Validate target host**: Webhook Dispatcher checks each webhook's target URL against the `PACT_BROKER_WEBHOOK_HOST_WHITELIST` (`github.groupondev.com github.com`). Webhooks targeting non-listed hosts are skipped.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `continuumPactBrokerWebhookDispatcher` (in-process)
   - Protocol: Direct

5. **Dispatch callback to GitHub Enterprise**: Webhook Dispatcher sends HTTP POST to `github.groupondev.com` with the event payload (pact URL, consumer/provider info, version).
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `githubEnterprise`
   - Protocol: HTTPS/webhook

6. **Dispatch callback to GitHub.com** (if configured): Webhook Dispatcher sends HTTP POST to `github.com` with the same or equivalent event payload.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `githubDotCom`
   - Protocol: HTTPS/webhook

7. **Record execution outcome**: Webhook Dispatcher writes a row to the `triggered_webhooks` table recording the delivery timestamp, target URL, HTTP response status, and success/failure state.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `continuumPactBrokerPersistence` -> `continuumPactBrokerPostgres`
   - Protocol: Direct / SQL

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Target host not in allow-list | Webhook skipped; not attempted | No callback sent; `triggered_webhooks` may record a skipped state |
| HTTP POST returns non-2xx | Delivery failure recorded in `triggered_webhooks`; upstream pact-broker retries per internal policy | CI pipeline does not receive notification on first attempt; retried automatically |
| Network timeout to GitHub | Recorded as failure; retried internally | Same as above |
| No webhooks configured for event | Dispatcher does nothing | No callbacks sent; pact/verification still stored successfully |
| PostgreSQL unavailable during webhook load | Dispatcher cannot load configs; dispatch skipped | No callbacks delivered; manual re-trigger via Pact Broker UI may be needed |

## Sequence Diagram

```
PactBrokerHttpApi -> WebhookDispatcher: notify("pact_published", consumer, provider, version)
WebhookDispatcher -> PactBrokerPersistence: load webhooks for consumer/provider/event
PactBrokerPersistence -> PostgreSQL: SELECT webhooks WHERE consumer=... AND event=...
PostgreSQL --> PactBrokerPersistence: [webhook_1, webhook_2]
PactBrokerPersistence --> WebhookDispatcher: webhook configs
WebhookDispatcher -> WebhookDispatcher: validate hosts against whitelist
WebhookDispatcher -> GitHubEnterprise: POST {pact_url, consumer, provider, version}
GitHubEnterprise --> WebhookDispatcher: 200 OK
WebhookDispatcher -> PostgreSQL: INSERT triggered_webhooks (status=success)
WebhookDispatcher -> GitHubDotCom: POST {pact_url, consumer, provider, version}
GitHubDotCom --> WebhookDispatcher: 200 OK
WebhookDispatcher -> PostgreSQL: INSERT triggered_webhooks (status=success)
```

## Related

- Architecture dynamic view: `dynamic-pact-broker`
- Related flows: [Contract Publishing](contract-publishing.md), [Verification Result Recording](verification-result-recording.md)
