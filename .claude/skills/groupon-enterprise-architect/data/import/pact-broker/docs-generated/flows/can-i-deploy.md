---
service: "pact-broker"
title: "Deployment Safety Check (can-i-deploy)"
generated: "2026-03-03"
type: flow
flow_name: "can-i-deploy"
flow_type: synchronous
trigger: "CI pipeline queries before deploying a service version to an environment"
participants:
  - "continuumPactBrokerHttpApi"
  - "continuumPactBrokerPersistence"
  - "continuumPactBrokerPostgres"
architecture_ref: "dynamic-pact-broker"
---

# Deployment Safety Check (can-i-deploy)

## Summary

Before a service version is deployed to production (or another environment), its CI pipeline queries the Pact Broker `can-i-deploy` endpoint. The broker evaluates all pact contracts for that service version — checking whether all relevant provider verifications have passed — and returns a safe/unsafe verdict. This is the primary deployment gate in Groupon's contract-testing workflow, preventing incompatible service versions from being deployed together.

## Trigger

- **Type**: api-call
- **Source**: CI/CD pipeline (Jenkins, GitHub Actions, or Deploybot pre-deploy gate)
- **Frequency**: On-demand (every deployment pipeline run before promoting a version)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| CI/CD Pipeline | Queries `can-i-deploy` before promoting a deployment | External caller |
| HTTP API | Receives the query, evaluates compatibility, returns verdict | `continuumPactBrokerHttpApi` |
| Persistence Adapter | Queries verification results, pacts, and version metadata | `continuumPactBrokerPersistence` |
| Pact Broker Postgres DB | Source of truth for all pact and verification data | `continuumPactBrokerPostgres` |

## Steps

1. **Query can-i-deploy**: CI pipeline sends `GET /can-i-deploy?pacticipant={name}&version={version}&to={environment}` (or equivalent query params).
   - From: CI/CD Pipeline
   - To: `continuumPactBrokerHttpApi`
   - Protocol: REST (HTTPS on port 9292)

2. **Resolve pact relationships**: HTTP API identifies all pact contracts relevant to the queried pacticipant version (both as consumer and as provider).
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerPersistence`
   - Protocol: Direct (in-process)

3. **Query verification results**: Persistence Adapter retrieves the latest verification results for each relevant pact version from PostgreSQL.
   - From: `continuumPactBrokerPersistence`
   - To: `continuumPactBrokerPostgres`
   - Protocol: SQL (PostgreSQL — join across `pacts`, `versions`, `verification_results`)

4. **Evaluate compatibility**: HTTP API computes the overall verdict: safe if all relevant pacts have passing verifications, unsafe otherwise.
   - From: `continuumPactBrokerHttpApi`
   - To: `continuumPactBrokerHttpApi` (in-process)
   - Protocol: Direct

5. **Return verdict**: HTTP API responds with a JSON body containing `{ "summary": { "deployable": true/false }, "matrix": [...] }`.
   - From: `continuumPactBrokerHttpApi`
   - To: CI/CD Pipeline
   - Protocol: REST (HTTPS)

6. **Gate deployment**: CI pipeline proceeds with the deployment if `deployable: true`; halts with an error if `deployable: false`.
   - From: CI/CD Pipeline
   - To: CI/CD Pipeline (local decision)
   - Protocol: N/A

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Pacticipant or version not found | HTTP API returns a result indicating `deployable: false` with explanation | Deployment halted; team investigates missing pact |
| No verification results exist | Verdict is `deployable: false` (unverified pacts are not safe) | Deployment halted until provider verifies |
| Database query failure | HTTP API returns 5xx | CI pipeline receives error; deployment is typically halted by pipeline policy |
| Public read enabled | No auth required for `can-i-deploy` query | Any caller can check deployment safety without credentials |

## Sequence Diagram

```
CICD -> PactBrokerHttpApi: GET /can-i-deploy?pacticipant=X&version=1.2.3
PactBrokerHttpApi -> PactBrokerPersistence: resolve pacts for pacticipant version
PactBrokerPersistence -> PostgreSQL: SELECT pacts, verification_results WHERE ...
PostgreSQL --> PactBrokerPersistence: pact + verification data
PactBrokerPersistence --> PactBrokerHttpApi: matrix data
PactBrokerHttpApi -> PactBrokerHttpApi: compute deployable verdict
PactBrokerHttpApi --> CICD: 200 OK { deployable: true/false, matrix: [...] }
CICD -> CICD: proceed or halt deployment based on verdict
```

## Related

- Architecture dynamic view: `dynamic-pact-broker`
- Related flows: [Contract Publishing](contract-publishing.md), [Verification Result Recording](verification-result-recording.md)
