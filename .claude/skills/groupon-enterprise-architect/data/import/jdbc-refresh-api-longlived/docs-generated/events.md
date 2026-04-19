---
service: "jdbc-refresh-api-longlived"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [kafka]
---

# Events

## Overview

The `jdbc-refresh-api-longlived` infrastructure platform does not itself publish or consume async events as part of its primary JDBC/Refresh API flow. However, Kafka is listed as an external dependency in `.service.yml`, which indicates that pipeline workloads running on the provisioned Dataproc clusters may consume Kafka topics as part of their data processing jobs. The infrastructure layer (Terraform/Terragrunt) does not directly manage any Kafka topic configurations.

## Published Events

> No evidence found in codebase. The Terraform infrastructure modules do not define any Kafka producers, Google Pub/Sub topics, or other async event publications.

## Consumed Events

> No evidence found in codebase. The infrastructure provisioning layer does not consume async events. Pipeline jobs executing on the backend clusters may consume Kafka topics, but those are defined and managed by the consuming pipeline teams (`consumer-data-engineering`, `grpn-gcloud-data-pipelines`).

## Dead Letter Queues

> No evidence found in codebase. No DLQ configuration exists in this repository.

---

> This service's infrastructure layer does not directly publish or consume async events. The Kafka dependency declared in `.service.yml` is consumed by application workloads (data pipelines) that run on the Dataproc clusters provisioned by this repository.
