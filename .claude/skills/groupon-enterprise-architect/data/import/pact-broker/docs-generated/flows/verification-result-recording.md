---
service: "pact-broker"
title: "Verification Result Recording"
generated: "2026-03-03"
type: flow
flow_name: "verification-result-recording"
flow_type: synchronous
trigger: "Provider CI pipeline posts verification results after running contract tests"
participants:
  - "continuumPactBrokerHttpApi"
  - "continuumPactBrokerPersistence"
  - "continuumPactBrokerWebhookDispatcher"
  - "continuumPactBrokerPostgres"
  - "githubEnterprise"
  - "githubDotCom"
architecture_ref: "dynamic-pact-broker"
---

# Verification Result Recording

## Summary

After a provider service runs its contract verification tests against a pact version, its CI pipeline posts the verification result (pass or fail) to Pact Broker. The broker persists the result, links it to the specific pact version and provider version, and triggers webhook callbacks to notify downstream consumers or CI systems of the verification outcome. This record is queried by the `can-i-deploy` check to gate deployments.

## Trigger

- **Type**: api-call
- **Source**: Provider service CI pipeline (running pact verification tests against fetched pact contracts)
- **Frequency**: On-demand (every provider CI build that verifies against stored pacts)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Provider CI Pipeline | Initiates the result post after running verification tests | External caller |
| HTTP API | Receives the POST request and coordinates persistence and webhook dispatch | `continuumPactBrokerHttpApi` |
| Persistence Adapter | Persists the verification result record to PostgreSQL | `continuumPactBrokerPersistence` |
| Pact Broker Postgres DB | Stores verification result linked to pact version and provider version | `continuumPactBrokerPostgres` |
| Webhook Dispatcher | Dispatches outbound callbacks after a verification result is recorded | `continuumPactBrokerWebhookDispatcher` |
| GitHub Enterprise | Receives webhook callback triggered by verification result | `githubEnterprise` |
| GitHub.com | Receives webhook callback triggered by verification result (public repos) | `githubDotCom` |

## Steps

1. **Fetch pact for verification**: Provider CI pipeline retrieves pact(s) to verify via `GET /pacts/provider/{provider}/latest` or a specific version endpoint.
   - From: Provider CI Pipeline
   - To: `continuumPactBrokerHttpApi`
   - Protocol: REST (HTTPS on port 9292)

2. **Run verification tests**: Provider CI runs its test suite against the retrieved pact contract (outside Pact Broker).
   - From: Provider CI Pipeline
   - To: Provider CI Pipeline (local process)
   - Protocol: N/A (local)

3. **Post verification result**: Provider CI sends `POST /pacts/provider/{provider}/consumer/{consumer}/pact-version/{pactVersion}/verification-results` with success flag and provider version.
   - From: Provider CI Pipeline
   - To: `continuumPactBrokerHttpApi`
   - Protocol: REST (HTTPS on port 9292)

4. **Authenticate request**: HTTP API validates basic-auth credentials.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerHttpApi` (in-process)
   - Protocol: Direct

5. **Persist verification result**: HTTP API instructs Persistence Adapter to write the verification result record linked to the pact version and provider version.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerPersistence`
   - Protocol: Direct (in-process)

6. **Write to database**: Persistence Adapter inserts a `verification_results` row into PostgreSQL.
   - From: `continuumPactBrokerPersistence`
   - To: `continuumPactBrokerPostgres`
   - Protocol: SQL (PostgreSQL)

7. **Return HTTP 201**: HTTP API responds to the provider CI pipeline with `201 Created`.
   - From: `continuumPactBrokerHttpApi`
   - To: Provider CI Pipeline
   - Protocol: REST (HTTPS)

8. **Trigger webhook dispatch**: HTTP API notifies the Webhook Dispatcher that a verification result has been recorded.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerWebhookDispatcher`
   - Protocol: Direct (in-process)

9. **Dispatch callbacks**: Webhook Dispatcher sends outbound callbacks to allowed targets.
   - From: `continuumPactBrokerWebhookDispatcher`
   - To: `githubEnterprise` and/or `githubDotCom`
   - Protocol: HTTPS/webhook

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pact version not found | HTTP API returns 404 | Provider CI pipeline receives 404; result not recorded |
| Invalid credentials (401) | HTTP API rejects request immediately | Provider CI pipeline receives 401; result not recorded |
| Database write failure | Persistence Adapter propagates exception; HTTP API returns 5xx | Provider CI pipeline retries; can-i-deploy remains unchanged |
| Webhook delivery failure | Webhook Dispatcher records failure; retries internally | Verification is stored; downstream notification may be delayed |

## Sequence Diagram

```
ProviderCI -> PactBrokerHttpApi: GET /pacts/provider/{p}/latest
PactBrokerHttpApi -> PactBrokerPersistence: query latest pacts for provider
PactBrokerPersistence -> PostgreSQL: SELECT pacts WHERE provider_id=...
PostgreSQL --> PactBrokerPersistence: pact documents
PactBrokerPersistence --> PactBrokerHttpApi: pact list
PactBrokerHttpApi --> ProviderCI: 200 OK + pact JSON
ProviderCI -> ProviderCI: run verification tests locally
ProviderCI -> PactBrokerHttpApi: POST /verification-results (success: true/false)
PactBrokerHttpApi -> PactBrokerPersistence: insert verification_result
PactBrokerPersistence -> PostgreSQL: INSERT verification_results
PostgreSQL --> PactBrokerPersistence: OK
PactBrokerPersistence --> PactBrokerHttpApi: OK
PactBrokerHttpApi --> ProviderCI: 201 Created
PactBrokerHttpApi -> WebhookDispatcher: notify "verification recorded"
WebhookDispatcher -> GitHubEnterprise: POST webhook callback
```

## Related

- Architecture dynamic view: `dynamic-pact-broker`
- Related flows: [Contract Publishing](contract-publishing.md), [Deployment Safety Check](can-i-deploy.md), [Webhook Dispatch](webhook-dispatch.md)
