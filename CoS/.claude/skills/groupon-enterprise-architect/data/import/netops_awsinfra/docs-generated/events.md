---
service: "netops_awsinfra"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

`netops_awsinfra` is an infrastructure-as-code repository and does not publish or consume async events via message brokers such as Kafka, RabbitMQ, SQS, or SNS. All state changes are driven by Terraform/Terragrunt apply operations initiated by engineers or CI.

The only event-like mechanism used is AWS CloudWatch metrics — Transit Gateway and Direct Connect telemetry is published to CloudWatch by AWS natively, and CloudWatch dashboards (`TransitGateway` and `DirectConnect`) are provisioned by the `continuumTransitGatewayDashboardModule` and `continuumDirectConnectDashboardModule` to visualize this data. This is observability instrumentation, not application-level event publishing.

## Published Events

> Not applicable — this service does not publish async events.

## Consumed Events

> Not applicable — this service does not consume async events.

## Dead Letter Queues

> Not applicable — no message queue infrastructure is used by this service.
