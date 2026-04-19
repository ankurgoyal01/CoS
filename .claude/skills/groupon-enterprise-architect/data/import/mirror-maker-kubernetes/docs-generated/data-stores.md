---
service: "mirror-maker-kubernetes"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. MirrorMaker Kubernetes operates purely as a streaming conduit: it reads from Kafka source topics and writes to Kafka destination topics. All state (topic offsets, consumer group positions) is managed by the Kafka brokers themselves under the consumer group ID assigned to each deployment instance.

## Stores

> Not applicable. This service is stateless and does not own any data stores.

Kafka consumer group offsets are committed to the source Kafka broker under the consumer group IDs of the pattern `mirror_maker-<env>-<component>` (e.g., `mirror_maker-production-k8s-msk-janus-mirrors`). These are managed by the Kafka infrastructure, not by this service.

## Caches

> Not applicable. No caches are used.

## Data Flows

Records flow in a single direction per pod: from the `SOURCE` broker endpoint through the MirrorMaker consumer, then immediately out through the MirrorMaker producer to the `DESTINATION` broker endpoint. There is no intermediate persistence, buffering store, or transformation store. The only state maintained in-process is the in-flight producer batch buffer (controlled by `BATCH_SIZE` and `LINGER_MS` env vars).
