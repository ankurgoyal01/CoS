---
service: "bynder-integration-service"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: [messagebus, jtier-messagebus-client]
---

# Events

## Overview

The bynder-integration-service is a full participant in the Continuum message bus for both publishing and consuming. It publishes update notifications when images or taxonomy data are synchronized, and it consumes inbound messages from Bynder, IAM, and the Taxonomy pipeline. Message processing is handled by the `bisMessageProcessors` component, which updates the local MySQL database and propagates changes to the Image Service.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| (message bus) | `BynderImageUpdated` | Bynder image successfully synced to local DB and Image Service | image_id, bynder_asset_id, sync_status, updated_at |
| (message bus) | `IAMImageUpdated` | IAM image successfully synced to local DB and Image Service | image_id, iam_asset_id, sync_status, updated_at |
| (message bus) | `TaxonomyUpdated` | Taxonomy metadata successfully synced from Taxonomy Service | taxonomy_version, updated_at |

### BynderImageUpdated Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Trigger**: `bisScheduledJobs` or `bisApiResources` (manual pull) completes processing of a Bynder asset
- **Payload**: image identifier, Bynder asset ID, sync status, timestamp
- **Consumers**: Downstream services tracking image availability (tracked in central architecture model)
- **Guarantees**: at-least-once

### IAMImageUpdated Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Trigger**: `bisScheduledJobs` or `bisApiResources` (manual IAM pull) completes processing of an IAM asset
- **Payload**: image identifier, IAM asset ID, sync status, timestamp
- **Consumers**: Downstream services tracking image availability (tracked in central architecture model)
- **Guarantees**: at-least-once

### TaxonomyUpdated Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Trigger**: `/taxonomy/update` endpoint or scheduled taxonomy sync job completes
- **Payload**: taxonomy version, update timestamp
- **Consumers**: Downstream services consuming taxonomy hierarchy (tracked in central architecture model)
- **Guarantees**: at-least-once

## Consumed Events

| Topic / Queue | Event Type | Handler | Side Effects |
|---------------|-----------|---------|-------------|
| (message bus) | `BynderMessage` | `bisMessageProcessors` | Updates local image DB; propagates to Image Service |
| (message bus) | `IAMMessage` | `bisMessageProcessors` | Updates local image DB; propagates to Image Service |
| (message bus) | `TaxonomyMessage` | `bisMessageProcessors` | Updates local taxonomy tables |

### BynderMessage Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Handler**: `bisMessageProcessors` — receives Bynder asset change notifications and updates the local MySQL image records accordingly, then syncs to Image Service
- **Idempotency**: No evidence found in codebase.
- **Error handling**: No evidence found in codebase.
- **Processing order**: unordered

### IAMMessage Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Handler**: `bisMessageProcessors` — receives IAM asset change notifications and updates the local MySQL image records accordingly, then syncs to Image Service
- **Idempotency**: No evidence found in codebase.
- **Error handling**: No evidence found in codebase.
- **Processing order**: unordered

### TaxonomyMessage Detail

- **Topic**: message bus (exact topic name not discoverable from inventory)
- **Handler**: `bisMessageProcessors` — receives taxonomy change notifications and updates local taxonomy/metaproperty tables
- **Idempotency**: No evidence found in codebase.
- **Error handling**: No evidence found in codebase.
- **Processing order**: unordered

## Dead Letter Queues

> No evidence found in codebase.
