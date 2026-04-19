---
service: "cloudability"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. The Cloudability Provisioning CLI scripts write generated and patched Kubernetes manifest files to the `secrets/` git submodule (`CloudSRE/cloudability-secrets`). The Cloudability Metrics Agent does not maintain persistent local state; all collected metrics are streamed directly to Cloudability's SaaS ingestion endpoint.

## Stores

> Not applicable. All manifest outputs are stored in the `secrets/` git submodule (`git@github.groupondev.com:CloudSRE/cloudability-secrets.git`). This is version-controlled configuration storage, not a runtime data store.

## Caches

> Not applicable.

## Data Flows

- The Provisioning CLI writes patched manifests to `secrets/conveyor-<context>.yml` files in the secrets submodule.
- On merge to `main`, deploybot picks up the updated secrets submodule and applies the manifests to the target Kubernetes clusters.
- The Metrics Agent reads live cluster state from the Kubernetes API Server and writes metric samples to Cloudability's ingestion API. No data is persisted locally.
