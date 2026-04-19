---
service: "momo-config"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: [log-pipeline, jlog]
---

# Events

## Overview

The MTA clusters configured by `momo-config` do not publish or consume events via a traditional message broker (no Kafka, RabbitMQ, or SQS integration is evidenced in the configuration files). Instead, event data is emitted as structured log records to the `loggingStack` via Ecelerity's custom logger module and Lua-managed jlog/CSV writers. These log streams are the primary mechanism by which inbound feedback events (bounces, FBLs, unsubscribes) and outbound delivery outcomes flow to downstream consumers. The `continuumMtaInboundService` feeds classified event data back to `continuumMtaEmailService` for suppression and hygiene controls via the event/log pipeline.

## Published Events

| Topic / Queue | Event Type | Trigger | Key Payload Fields |
|---------------|-----------|---------|-------------------|
| `/var/log/ecelerity/delivery.ec` | Delivery record | Successful outbound delivery | timestamp, mail_from, rcpt_domain, binding, binding_group, job_id, email_name, send_id, test_groups, msfbl, clr, rm_user_send_id, rm_emailSubject, rm_businessGroup, rm_campaignGroup, rm_brand, rm_campaign_data |
| `/var/log/ecelerity/delivery.csv` | Delivery record (GDPR) | Successful outbound delivery | timestamp, mail_from, rcpt_domain, binding, binding_group, job_id, email_name, send_id, test_groups, promotions, msfbl, clr, scheduled_send_time |
| `/var/log/ecelerity/inband_bounce.ec` | In-band bounce record | Permanent or transient SMTP failure | timestamp, mail_from, rcpt, dsn, relay_host, smtp_status, binding, bounce_class, email_name, send_id, msfbl, clr, rm_user_send_id, scheduled_send_time |
| `/var/log/ecelerity/inband_bounce.csv` | In-band bounce record (GDPR) | Permanent or transient SMTP failure | timestamp, mail_from, rcpt, dsn, relay_host, smtp_status, binding, bounce_class, email_name, send_id, msfbl, clr |
| `/var/log/ecelerity/custom_bounce.csv` | Custom bounce record | Permanent or transient failure on custom-logged channel (port 40128) | timestamp, mail_from, binding_group, binding, rcpt_domain, header1–header8, bounce_class, msfbl |
| `oob_csv` / `oob_jlog` | Out-of-band bounce record (GDPR) | OOB DSN message received on `bounce.r.grouponmail.co.uk` | timestamp, rcpt_clean, rcpt_domain, o_from, dsn_status, bc_desc, dsn_mta, reporting_mta, bc_code, src_mta, email_name, send_id, msfbl, clr |
| `oob2_csv` | Out-of-band bounce record (non-GDPR) | OOB DSN message received | timestamp, rcpt_clean, o_to, o_from, dsn_status, bc_desc, dsn_mta, reporting_mta, bc_code, src_mta, email_name, user_hash, send_id, msfbl, clr |
| `fbl_csv` / `fbl_jlog` | FBL complaint record (GDPR) | FBL (ARF) message received on `fbl.r.grouponmail.co.uk` | timestamp, src_mta, report_type, user_agent, o_mail_from, original_recipient_domain, source_ip, e_from_domain, return_path, email_name, send_id, msfbl, clr |
| `fbl2_csv` | FBL complaint record (non-GDPR) | FBL (ARF) message received | timestamp, src_mta, report_type, user_agent, o_mail_from, original_recipient, source_ip, e_from_domain, return_path, email_name, user_hash, send_id, msfbl, clr |
| `unsub_csv` / `unsub_jlog` | Unsubscribe record (GDPR) | List-unsubscribe message received on `unsub.r.grouponmail.co.uk` | timestamp, rcpt_to, mailfrom_domain, src_mta, subject, rcpt_domain |
| `unsub2_csv` | Unsubscribe record (non-GDPR) | List-unsubscribe message received | timestamp, rcpt_to, mail_from, src_mta, subject |
| `loggingStack` (metrics path) | Throughput/rejection metrics | Continuous delivery operation | Delivery rate, rejection rate, per-binding-group counters |

### Delivery Record Detail

- **Topic**: `/var/log/ecelerity/delivery.ec` and `/var/log/ecelerity/delivery.csv`
- **Trigger**: Outbound message successfully delivered to remote MX
- **Payload**: Structured CSV with Groupon-specific context variables extracted from message headers: job_id, email_name, send_id, clr (VERP token), binding/binding_group, test_groups, promotions, brand, businessGroup, campaignGroup, campaign_data, custom_campaign_tracking
- **Consumers**: `loggingStack` pipeline; downstream analytics/reporting systems
- **Guarantees**: at-least-once (file-based append)

### OOB Bounce Record Detail

- **Topic**: `oob_csv` / `oob_jlog` (paths configured in `groupon_config.logs`)
- **Trigger**: OOB Delivery Status Notification (DSN) received on `bounce.r.grouponmail.co.uk` from null-envelope-sender
- **Payload**: Bounce classification code and description, reporting MTA, original recipient, X-RM-SendId, X-RM-EmailName, X-MSFBL, X-RM-Clr, source MTA IP
- **Consumers**: Email hygiene/suppression systems via `loggingStack`
- **Guarantees**: at-least-once; message discarded after logging (`598 Discarding Delivery Status Notification after logging`)

### FBL Record Detail

- **Topic**: `fbl_csv` / `fbl_jlog`
- **Trigger**: ARF (Abuse Reporting Format) FBL message received on `fbl.r.grouponmail.co.uk` or configured FBL localparts on `r.grouponmail.co.uk`; GMX FBL handled separately via EHLO domain detection
- **Payload**: Reporter MTA, user agent, original recipient (domain only in GDPR variant), source IP, return path, X-RM-SendId, X-RM-EmailName, X-MSFBL, X-RM-Clr
- **Consumers**: Complaint rate monitoring, suppression pipeline
- **Guarantees**: at-least-once; message discarded after logging

### Unsubscribe Record Detail

- **Topic**: `unsub_csv` / `unsub_jlog`
- **Trigger**: List-unsubscribe message received on `unsub.r.grouponmail.co.uk`
- **Payload**: Timestamp, RCPT TO address, sender domain (GDPR variant), source MTA, subject, recipient domain
- **Consumers**: Subscription management / unsubscribe processing pipeline
- **Guarantees**: at-least-once; message discarded after logging

## Consumed Events

> No evidence found in codebase. The MTA clusters do not consume events from a message broker. Inbound processing is triggered by SMTP connection arrival, not by consuming events from a queue.

## Dead Letter Queues

> No evidence found in codebase. Failed or unprocessable messages are handled inline via SMTP rejection codes or discard with `598` response. On-disk spool at `/var/spool/ecelerity` provides durability for queued outbound messages pending delivery retry.
