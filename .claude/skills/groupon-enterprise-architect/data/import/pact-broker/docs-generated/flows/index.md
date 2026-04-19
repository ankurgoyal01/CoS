---
service: "pact-broker"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Pact Broker.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Contract Publishing](contract-publishing.md) | synchronous | Consumer CI pushes a new pact version | Consumer service publishes a pact contract file to the broker; broker persists it and triggers webhooks |
| [Verification Result Recording](verification-result-recording.md) | synchronous | Provider CI posts a verification result | Provider service records pass/fail verification results against a pact version |
| [Deployment Safety Check (can-i-deploy)](can-i-deploy.md) | synchronous | CI pipeline queries before deploying | CI pipeline asks the broker whether a given pacticipant version is safe to deploy against its dependencies |
| [Webhook Dispatch](webhook-dispatch.md) | asynchronous | Internal pact event (publish or verify) | Broker dispatches outbound HTTP webhook callbacks to GitHub Enterprise or GitHub.com to trigger CI pipeline actions |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

- **Contract Publishing** and **Verification Result Recording** are initiated by external consumer/provider CI pipelines. These flows span this service and any Groupon service that participates in contract testing.
- **Webhook Dispatch** crosses the boundary into `githubEnterprise` and `githubDotCom` to notify CI systems.
- Refer to the central architecture dynamic views for cross-service context: `dynamic-pact-broker`.
