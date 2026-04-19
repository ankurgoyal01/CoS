---
service: "third-party-mailmonger"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores:
  - id: "daasPostgres"
    type: "postgresql"
    purpose: "Primary store for masked emails, email content, partner emails, and delivery status"
---

# Data Stores

## Overview

Third Party Mailmonger owns a single PostgreSQL database accessed through Groupon's DaaS (Database-as-a-Service) platform. The database stores all state: masked email address mappings, inbound email content, email delivery status, partner email registrations, partner email domains, and Quartz scheduler state. The service uses JDBI3 for data access and JTier migrations for schema management. There is no external cache layer; in-process state is limited to the users-service polling task's data refresh buffer.

## Stores

### PostgreSQL via DaaS (`daasPostgres`)

| Property | Value |
|----------|-------|
| Type | postgresql |
| Architecture ref | `daasPostgres` |
| Purpose | Stores masked email mappings, email content, delivery status, partner emails, partner email domains, and Quartz scheduler state |
| Ownership | owned |
| Migrations path | Managed via `jtier-quartz-postgres-migrations` and JTier DaaS migration tooling |

#### Connection Details (Non-Secret)

| Environment | VIP Host | Database |
|-------------|----------|----------|
| Production (SNC1/SAC1) | `prod-third-pt-mm-rw-vip.us.daas.grpn` | `third_pt_mm_prod` |
| Production (DUB1/EU) | `gds-dub1-prod-third-party-mailmon-rw-vip.dub1` | `third_party_mail_prod` |
| Staging (SNC1) | `mailmonger-app-staging-vip.snc1` | (DaaS-managed) |

Pool configuration: Transaction pool size 50 (JTier default), Session pool size 2 (JTier default).

#### Key Entities

| Entity / Table | Purpose | Key Fields |
|----------------|---------|-----------|
| `masked_emails` | Maps consumer/partner pairs to unique masked email addresses | `id` (UUID), `email` (masked address), consumer ID, partner ID |
| `consumer_partner_emails` | Stores the consumer-partner relationship used for email routing | `id`, consumer UUID, partner UUID, associated masked email |
| `email_content` | Stores the full inbound email payload received via SparkPost relay | `id` (UUID / emailContentId), `sparkpost_id`, `status` (EmailStatus), `sent_count`, `created_at`, `sender_email_id` |
| `emails` | Queryable view/table of email metadata for the customer-support API | `id`, `consumer_id`, `partner_id`, `transaction_id`, `subject`, `html_body`, `text_body`, `sender_email`, `status`, `created_at` |
| `partner_emails` | Registered real email addresses for each partner | `partner_email_id` (UUID), `partner_id` (UUID), `email`, `created_at` |
| `partner_email_domains` | Allowed sending domains for each partner (used by UnauthorizedPartnerEmailFilter) | `id` (UUID), `name` (domain/regex), `partner_id` (UUID) |
| `sparkpost_raw_emails` | Raw SparkPost relay message payloads for debugging and reprocessing | `id`, raw relay JSON |
| Quartz tables | Quartz scheduler job and trigger state | Standard Quartz schema managed by `jtier-quartz-postgres-migrations` |

#### Access Patterns

- **Read**: `EmailContentDAO.getEmailContent(UUID)` — by email content ID during message bus processing; `MaskedEmailDAO.getMaskedEmailObjectById(UUID)` — sender lookup during filter evaluation; `EmailsDAO` — paginated queries by status, consumerId, transactionId for the support API
- **Write**: `EmailContentDAO.updateEmail(status, sparkpostId, timestamp, sentCount)` — status updates after every processing attempt; `EmailSavingService` — inserts raw email content on SparkPost callback receipt; `MaskedEmailDAO` — creates new masked email mappings on first call to `/v1/masked/consumer/{consumerId}/{partnerId}`
- **Indexes**: Not directly visible from the codebase; expected indexes on `email_content.id`, `masked_emails.consumer_id + partner_id`, and `partner_email_domains.partner_id`

## Caches

| Cache | Type | Purpose | TTL |
|-------|------|---------|-----|
| Users-service data buffer | In-memory | Holds recently fetched user/partner email data to reduce users-service call frequency | Refreshed by `UsersServicePollingTask` on a managed periodic schedule |

## Data Flows

- SparkPost relay webhook arrives at `POST /mailmonger/v1/sparkpost-callback` → raw email inserted into `sparkpost_raw_emails` and `email_content` → email content UUID published to MessageBus
- MessageBus consumer retrieves email content from `email_content` by UUID → processes and sends → updates `email_content.status` and `sent_count`
- TPIS calls `/v1/masked/consumer/{consumerId}/{partnerId}` → reads or creates a record in `masked_emails` and `consumer_partner_emails` → returns masked address
- Replication: Master-Slave replication; reads served from local colo (SNC1 reads from SNC1/SAC1; DUB1 reads locally); writes go to the master in each region's primary colo
