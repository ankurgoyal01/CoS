---
service: "contract-data-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [mbus]
---

# Events

## Overview

Contract Data Service declares a dependency on `jtier-messagebus-client` in `pom.xml`, indicating the service framework is capable of message bus integration. However, no active topic publications or event consumption handlers were found in the codebase. The service operates primarily as a synchronous REST API. All state changes (contract writes, party upserts, term inserts) are request-driven with synchronous HTTP responses.

## Published Events

> No evidence found in codebase. No event publishing logic was identified in the service source. The `jtier-messagebus-client` dependency is declared but no producers are implemented.

## Consumed Events

> No evidence found in codebase. No message bus consumers or event handlers were identified. All inbound operations are driven by direct HTTP API calls.

## Dead Letter Queues

> Not applicable. No async messaging consumers are implemented.
