---
service: "aws-backups"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: ["sns"]
---

# Events

## Overview

aws-backups does not publish or consume application-level async events (no Kafka, RabbitMQ, or internal message bus). The service configures AWS SNS topics on each backup vault so that the AWS Backup service can deliver vault lifecycle notifications to the `<backup-notifications-DL>` distribution list. These SNS notifications are AWS-managed events triggered by the AWS Backup service itself (not by this Terraform code at runtime).

## Published Events

> Not applicable. This service does not publish events at runtime. It provisions the SNS infrastructure that AWS Backup uses to emit notifications.

## AWS Backup Vault Notifications (AWS-managed)

The following vault lifecycle event types are configured via `aws_backup_vault_notifications` resources. In production, only a subset of events is enabled to reduce noise. Notifications are sent to per-vault SNS topics which deliver email to `<backup-notifications-DL>`.

| Event Type | Trigger | Severity | Configured In |
|------------|---------|----------|---------------|
| `BACKUP_JOB_FAILED` | A scheduled backup job fails | Error | Production vaults (GDS and Deadbolt) |
| `BACKUP_JOB_EXPIRED` | A backup job expires before completing | Error | Production vaults (GDS and Deadbolt) |
| `RESTORE_JOB_STARTED` | A restore job is initiated | Info | Production vaults |
| `RESTORE_JOB_SUCCESSFUL` | A restore job completes successfully | Info | Production vaults |
| `RESTORE_JOB_FAILED` | A restore job fails | Error | Production vaults |
| `COPY_JOB_FAILED` | A cross-account or cross-region copy job fails | Error | Production vaults |

### Vault Notification Detail

- **SNS delivery target**: `<backup-notifications-DL>` (email subscription)
- **Vaults with notifications**: GDS source vault (`gds-monthly-2y`), GDS target vault (`gds-monthly-2y-copytarget`), Deadbolt source vault (`deadbolt-weekly-1y` in `grpn-security-prod`), Deadbolt target vault (`deadbolt-weekly-1y` in `grpn-backup-prod`)
- **Non-production**: Notifications may include additional event types for completeness
- **Full event list**: See [AWS Backup Vault Notifications API reference](https://docs.aws.amazon.com/aws-backup/latest/devguide/API_GetBackupVaultNotifications.html#API_GetBackupVaultNotifications_ResponseSyntax)

## Consumed Events

> Not applicable. This service does not subscribe to or consume any async events.

## Dead Letter Queues

> Not applicable. No DLQs are configured. AWS Backup job retries are governed by the backup schedule — a failed job is re-run at the next scheduled backup window.
