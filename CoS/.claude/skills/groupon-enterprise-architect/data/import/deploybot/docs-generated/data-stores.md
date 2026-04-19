---
service: "deploybot"
title: Data Stores
generated: "2026-03-02T00:00:00Z"
type: data-stores
stores:
  - id: "externalDeploybotDatabase_43aa"
    type: "mysql"
    purpose: "Deployment state, audit logs, Jira ticket tracking, configs, notifications"
  - id: "externalS3Bucket_4b6c"
    type: "s3"
    purpose: "Archived deployment logs"
---

# Data Stores

## Overview

deploybot uses two persistent stores. MySQL is the primary operational database, holding all deployment state, audit records, Jira logbook references, per-repo configuration, and notification history. AWS S3 is used exclusively for archiving deployment log output after a deployment finalizes. There are no caches or additional storage tiers.

## Stores

### Deployment MySQL Database (`externalDeploybotDatabase_43aa`)

| Property | Value |
|----------|-------|
| Type | mysql |
| Architecture ref | `externalDeploybotDatabase_43aa` |
| Purpose | Deployment state machine, audit trail, SOX logbook references, per-project configs, notification records |
| Ownership | owned |
| Migrations path | > No evidence found in codebase for explicit migration path |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `deploy_requests` | Tracks each deployment request lifecycle | deployment key, project, org, environment, status, deployer, commit SHA, created_at, updated_at |
| `validation_states` | Records results of each validation gate per deployment | deployment key, validation type, status, message, timestamp |
| `audit_logs` | SOX-compliant audit records for every deployment action | deployment key, actor, action, timestamp, metadata |
| `jira_tickets` | Tracks Jira SOX logbook ticket references per deployment | deployment key, jira ticket ID, created_at, closed_at |
| `configs` | Stores cached or resolved `.deploy_bot.yml` configurations per repo | org, project, branch, config blob, version |
| `notifications` | Records Slack and other notification history per deployment | deployment key, channel, type, status, sent_at |

#### Access Patterns

- **Read**: Query deployment history by org/project (`GET /v1/deployments/{org}/{project}`); look up current deployment state during orchestration; fetch configs during validation
- **Write**: Insert new deployment request on webhook or API trigger; update deployment state at each lifecycle transition; insert audit log entries at every action; record Jira ticket IDs and notification outcomes
- **Indexes**: > No evidence found in codebase for specific index definitions

### Deployment Log Archive (`externalS3Bucket_4b6c`)

| Property | Value |
|----------|-------|
| Type | s3 |
| Architecture ref | `externalS3Bucket_4b6c` |
| Purpose | Long-term archival of deployment log output for audit and post-mortem review |
| Ownership | external (AWS-managed) |
| Migrations path | > Not applicable |

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| Log objects | Full stdout/stderr output of each deployment run | S3 key based on deployment key, upload timestamp |

#### Access Patterns

- **Read**: `deploybotLogImporter` utility retrieves archived logs; log URLs referenced in Jira tickets and Slack notifications
- **Write**: `deploybotNotifier` (finalization phase) uploads raw deployment log to S3 after deployment completes
- **Indexes**: > Not applicable (S3 key-based access)

## Caches

> No evidence found in codebase for a dedicated cache layer. No Redis or Memcached usage detected.

## Data Flows

1. Deployment request arrives (webhook or API) — `deploybotApi` writes initial record to MySQL (`deploy_requests`)
2. `deploybotOrchestrator` updates MySQL state at each lifecycle transition (queued → validating → executing → finalizing → complete/failed)
3. `deploybotAudit` appends to MySQL `audit_logs` at every action
4. `deploybotNotifier` records Jira ticket IDs back to MySQL (`jira_tickets`) after creation
5. At finalization, `deploybotNotifier` uploads full log to S3 (`externalS3Bucket_4b6c`) and stores the S3 URL in MySQL or Jira ticket
