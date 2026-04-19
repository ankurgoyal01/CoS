---
service: "webbus"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 3
---

# Flows

Process and flow documentation for Webbus.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Salesforce to Message Bus Publish](salesforce-to-message-bus-publish.md) | synchronous | HTTP POST from Salesforce to `POST /v2/messages/` | Core flow: Salesforce POSTs a batch of CRM change events; Webbus validates and publishes each to the Message Bus; failures are returned for redelivery |
| [Client Authentication](client-authentication.md) | synchronous | Every inbound request carrying a `client_id` query parameter | Webbus validates the `client_id` against the environment-specific allowlist before allowing any message publication |
| [Message Validation and Topic Whitelisting](message-validation-and-topic-whitelisting.md) | synchronous | Each message within an authenticated POST request | Webbus validates individual message structure and enforces the permitted topic whitelist before publishing |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 0 |

## Cross-Service Flows

The Salesforce-to-Message-Bus publish flow spans two systems: Salesforce (external caller) and the Groupon Message Bus (internal infrastructure). This flow is documented in the architecture dynamic view `dynamic-salesforce-to-message-bus-publish-flow` in the `continuumSystem` workspace.

- Architecture dynamic view: `dynamic-salesforce-to-message-bus-publish-flow`
- Related architecture context: [Architecture Context](../architecture-context.md)
