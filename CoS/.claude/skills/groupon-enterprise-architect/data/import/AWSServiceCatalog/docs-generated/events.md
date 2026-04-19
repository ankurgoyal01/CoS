---
service: "aws-service-catalog"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via any message bus (Kafka, RabbitMQ, SQS, SNS topics as a consumer, etc.). AWSServiceCatalog is a pure Infrastructure-as-Code configuration repository. All state changes are driven by CloudFormation stack create/update operations performed manually or via the Jenkins pipeline. There are no event-driven flows in this codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
