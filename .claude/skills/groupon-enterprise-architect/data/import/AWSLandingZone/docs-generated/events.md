---
service: "aws-landing-zone"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

AWS Landing Zone does not publish or consume async events via a message broker (no Kafka topics, SQS queues, or SNS topics owned by this service). Infrastructure changes are triggered synchronously by the Jenkins pipeline on GitHub merge events and by manual pipeline dispatch.

However, the service interacts with AWS event infrastructure in the following ways:
- Cloud Custodian policies can be deployed as AWS Lambda functions that react to CloudTrail events (e.g., `RunInstances`) — these are AWS-native events within each target account, not a message bus owned by the Landing Zone.
- CloudTrail is enabled in every account with a multi-region trail named `GRPNCloudTrail`, writing to a per-account S3 bucket (`{account_id}-grpn-cloudtrail-logs`) and to the CloudWatch log group `GRPNCloudTrailLogs` (180-day retention).

## Published Events

> No evidence found in codebase. This service does not publish async events to a message bus.

## Consumed Events

> No evidence found in codebase. This service does not consume async events from a message bus.

Cloud Custodian policies that operate in Lambda mode consume CloudTrail events within the target AWS account. The relevant CloudTrail event types are:
- `RunInstances` — triggers instance tagging enforcement policies
- IAM API calls — trigger IAM drift detection policies

These are AWS-native CloudWatch/CloudTrail subscriptions configured per policy, not a centrally managed message bus integration.

## Dead Letter Queues

> No evidence found in codebase.
