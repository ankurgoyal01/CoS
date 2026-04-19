---
service: "webbus"
title: Overview
generated: "2026-03-03"
type: overview
domain: "Salesforce Integration"
platform: "Continuum"
team: "Salesforce"
status: active
tech_stack:
  language: "Ruby"
  language_version: "1.9.3-p484"
  framework: "Grape"
  framework_version: "0.6.0"
  runtime: "Thin"
  runtime_version: "1.5.1"
  build_tool: "Bundler"
  package_manager: "Bundler"
---

# Webbus Overview

## Purpose

Webbus is a public-facing RESTful gateway that receives bulk message payloads from Salesforce and publishes them onto the Groupon Message Bus (STOMP-based). It acts as the sole authorised bridge between Salesforce's CRM event stream and Groupon's internal eventing infrastructure, validating each inbound payload before forwarding it to the appropriate JMS topic.

The service exists to decouple Salesforce from the internal message bus protocol: Salesforce can POST over plain HTTP while downstream consumers receive well-formed JMS topic messages without any knowledge of the Salesforce origin.

## Scope

### In scope

- Authenticating callers via an environment-specific API key (`client_id`) allowlist loaded from `config/clients.yml`
- Validating individual message payloads (non-empty `topic` and `body` fields)
- Enforcing a whitelist of permitted JMS destination topics configured in `config/messagebus.yml`
- Publishing validated messages to the Message Bus in bulk, returning any failures to the caller for redelivery
- Exposing health (`/grpn/healthcheck`), heartbeat (`/heartbeat.txt`), and status (`/status`) endpoints for load-balancer and service-portal integration

### Out of scope

- Message routing or transformation beyond topic whitelisting
- Consuming messages from the Message Bus
- Persisting messages — the service is fully stateless and owns no database
- Business logic associated with the CRM entities in the messages (accounts, opportunities, options, contacts, etc.)
- Salesforce-side message creation or queuing

## Domain Context

- **Business domain**: Salesforce Integration
- **Platform**: Continuum
- **Upstream consumers**: Salesforce (primary and only external caller via the IP-whitelisted `webbus.groupon.com` VIP)
- **Downstream dependencies**: Groupon Message Bus (STOMP/JMS over port 61613)

## Stakeholders

| Role | Description |
|------|-------------|
| Service Owner | Salesforce Integration team (`sfint-dev@groupon.com`), owner: `dbertelkamp` |
| On-call | `sfint-dev-alerts@groupon.com`; PagerDuty service P07G73H; Slack: `salesforce-integration` |
| Consumers | Salesforce.com (sends POST requests to publish CRM change events) |
| Downstream | Internal Groupon services that subscribe to `jms.topic.salesforce.*` topics on the Message Bus |

## Tech Stack

### Core

| Layer | Technology | Version | Evidence |
|-------|-----------|---------|----------|
| Language | Ruby | 1.9.3-p484 | `.ruby-version` |
| Framework | Grape | 0.6.0 | `Gemfile.lock` |
| Runtime | Thin | 1.5.1 | `Gemfile.lock`, `config/thin.yml` |
| Build tool | Bundler | — | `Gemfile` |
| Package manager | Bundler | — | `Gemfile` |
| Container base | Ruby 1.9.3 (Docker) | — | `.ci/Dockerfile` |

### Key Libraries

| Library | Version | Category | Purpose |
|---------|---------|----------|---------|
| `grape` | 0.6.0 | http-framework | REST API definition, routing, parameter coercion, and Grape validators |
| `messagebus` | 0.2.10 | message-client | STOMP-based Groupon Message Bus client for publishing to JMS topics |
| `thin` | 1.5.1 | runtime | Single-threaded Rack-compatible HTTP server; runs on port 9393 |
| `rack` | 1.5.2 | http-framework | Underlying Rack application interface and middleware stack |
| `virtus` | 0.5.5 | serialization | Attribute coercion and type mapping for the `Message` model |
| `rack-request-id` | 0.0.3 | logging | Propagates `X-Request-Id` across all log entries |
| `activesupport` | 4.0.0 | validation | Core Ruby extensions used by Grape and other dependencies |
| `thrift` | 0.9.0 | message-client | Thrift transport layer required by the `messagebus` gem |
| `rspec` | 2.14.1 | testing | Unit and integration test framework |
| `webmock` | 1.13.0 | testing | HTTP stubbing for test isolation |
| `rake` | 10.1.0 | scheduling | Task runner for utility scripts |

> Only the most important libraries are listed here — the ones that define how the service works. Transitive and trivial dependencies are omitted. See `Gemfile.lock` for the full list.
