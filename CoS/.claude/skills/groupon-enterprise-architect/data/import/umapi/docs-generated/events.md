---
service: "umapi"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [activemq-artemis]
---

# Events

## Overview

UMAPI interacts with the Continuum Message Bus (ActiveMQ Artemis) for asynchronous communication. The central architecture model defines a bidirectional relationship (`continuumUniversalMerchantApi -> messageBus "" "Async"`), indicating that UMAPI both publishes and consumes events. However, the specific topics, event types, and payload schemas are not enumerated in the architecture DSL.

## Published Events

> No evidence found in codebase. The relationship `continuumUniversalMerchantApi -> messageBus` confirms event publishing occurs, but specific topics and event types are not defined in the architecture model.

Likely published events (inferred from service purpose):
- Merchant profile created/updated events
- Merchant onboarding status change events
- Place/location data change events

## Consumed Events

> No evidence found in codebase. The bidirectional async relationship suggests event consumption, but specific subscriptions are not defined in the architecture model.

## Dead Letter Queues

> No evidence found in codebase.
