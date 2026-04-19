---
service: "momo-config"
title: "Inbound Feedback Processing"
generated: "2026-03-03"
type: flow
flow_name: "inbound-feedback-processing"
flow_type: event-driven
trigger: "SMTP connection from external ISP delivering bounce DSN, FBL (ARF), or list-unsubscribe message to Groupon response domain"
participants:
  - "continuumMtaInboundService"
  - "continuumMtaInboundIntService"
  - "continuumMtaEmailService"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-inbound-feedback-flow"
---

# Inbound Feedback Processing

## Summary

The inbound feedback processing flow handles all response traffic arriving on Groupon's email response domains (`bounce.r.grouponmail.co.uk`, `fbl.r.grouponmail.co.uk`, `r.grouponmail.co.uk`, `unsub.r.grouponmail.co.uk`). The `continuumMtaInboundService` classifies each incoming message as a bounce (OOB DSN), FBL complaint (ARF), or unsubscribe; extracts Groupon tracking headers from the embedded original message; writes a structured log record to CSV and jlog files; and discards the message after logging. Classified outcomes feed back into outbound suppression and list hygiene controls via `continuumMtaEmailService`.

## Trigger

- **Type**: event (inbound SMTP connection)
- **Source**: External ISP or mailbox provider delivering response traffic to Groupon's MX records for response domains
- **Frequency**: Continuous; driven by recipient actions (complaints, bounced deliveries, unsubscribes)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| External ISP / Mailbox Provider | Delivers bounce DSN, FBL, or unsubscribe SMTP message to inbound cluster | External |
| MTA Inbound Cluster | Classifies message type; parses MIME parts; extracts tracking headers; logs to CSV/jlog; discards | `continuumMtaInboundService` |
| MTA Inbound Internal Cluster | Shares inbound parsing policies for internal pipeline events; forwards to inbound cluster | `continuumMtaInboundIntService` |
| MTA Email Cluster | Receives hygiene outcomes (bounce/FBL/unsubscribe) for outbound suppression updates | `continuumMtaEmailService` |
| Logging Stack | Receives structured OOB bounce, FBL, and unsubscribe log records | `loggingStack` |
| Metrics Stack | Receives inbound processing metrics | `metricsStack` |

## Steps

1. **Receives inbound SMTP connection**: External ISP connects to `continuumMtaInboundService` ESMTP listener on port 25; relay domains (`fbl.r.grouponmail.co.uk`, `r.grouponmail.co.uk`, `unsub.r.grouponmail.co.uk`) and bounce domains (`bounce.r.grouponmail.co.uk`) are declared in `ecelerity.conf`
   - From: External ISP
   - To: `continuumMtaInboundService`
   - Protocol: ESMTP (port 25)

2. **Validates RCPT TO and classifies message type**: `inbound_policy.lua` (`mod:validate_rcptto`) resolves the destination domain via `groupon_config.msg_types` lookup; classifies as `"bounce"`, `"fbl"`, `"unsub"`, or `"r"` (generic response); admin/postmaster addresses and configured merchant addresses are allowed; all other inbound mail is rejected with `552 Denied by policy`
   - From: `continuumMtaInboundService`
   - To: `continuumMtaInboundService` (internal policy)
   - Protocol: direct

3. **Extracts message context** (`mod:validate_data_spool_each_rcpt`): Extracts `via_ip`, `via_port`, `sending_host`; reads Groupon tracking headers (`X-RM-EmailName`, `X-RM-SendID`, `X-RM-UserHash`, `X-RM-Clr`, `X-RM-JobId`, `X-RM-TestGroups`, `X-RM-Promotions`) from message context; optionally samples raw message to `/var/log/ecelerity/inbound_samples/` when `log_samples = true`
   - From: `continuumMtaInboundService`
   - To: `continuumMtaInboundService` (internal)
   - Protocol: direct

4. **Processes unsubscribe messages** (if `msg_type == "unsub"`): Extracts RCPT TO, mail-from domain, source MTA, and subject; writes GDPR-compliant record to `unsub_csv` and `unsub_jlog` (domain only, no email address); writes non-GDPR record to `unsub2_csv` (full address); discards message with `598 Discarding unsubscribe request after logging`
   - From: `continuumMtaInboundService`
   - To: `loggingStack` (via log files)
   - Protocol: Log pipeline (jlog/CSV)

5. **Processes OOB bounce messages** (if `msg_type == "bounce"` and null envelope sender): Parses MIME parts to find `message/delivery-status` DSN part and embedded `message/rfc822` original message; extracts bounce classification (`msys.bounce.classify`), reporting MTA, original recipient, and Groupon tracking headers (`X-RM-SendId`, `X-RM-EmailName`, `X-RM-UserHash`, `X-RM-Clr`, `X-MSFBL`) from original; attempts fallback body match for `X-RM-SendId` header if RFC 2822 part absent; writes GDPR-compliant record to `oob_csv` and `oob_jlog` (domain only); writes non-GDPR record to `oob2_csv` (full address); discards with `598 Discarding Delivery Status Notification after logging`
   - From: `continuumMtaInboundService`
   - To: `loggingStack` (via log files)
   - Protocol: Log pipeline (jlog/CSV)

6. **Processes FBL complaint messages** (if `msg_type == "fbl"` or FBL localpart on `"r"` domain): Parses MIME parts for `message/feedback-report` (ARF) and embedded `message/rfc822` original; applies GMX-specific FBL parsing when EHLO domain matches `groupon_config.gmx_ehlo`; extracts user agent, source IP, original recipient, original mail-from, `X-RM-SendId`, `X-RM-EmailName`, `X-RM-Clr`, `X-MSFBL`, `X-HmXmrOriginalRecipient` (Microsoft); recovers `X-MSFBL` from raw message body as fallback; writes GDPR-compliant record to `fbl_csv` and `fbl_jlog` (domain only); writes non-GDPR record to `fbl2_csv` (full address); discards with `598 Discarding FBL message after logging`
   - From: `continuumMtaInboundService`
   - To: `loggingStack` (via log files)
   - Protocol: Log pipeline (jlog/CSV)

7. **Feeds outcomes to outbound suppression**: Classified bounce/FBL/unsubscribe outcomes flow to `continuumMtaEmailService` for outbound list hygiene and suppression updates via the event/log pipeline
   - From: `continuumMtaInboundService`
   - To: `continuumMtaEmailService`
   - Protocol: Event/Log

8. **Forwards internal events**: `continuumMtaInboundIntService` shares inbound parsing policies and operational controls with `continuumMtaInboundService` for internal pipeline events
   - From: `continuumMtaInboundIntService`
   - To: `continuumMtaInboundService`
   - Protocol: Config/Policy

9. **Emits inbound processing metrics**: Bounce/FBL/unsubscribe processing metrics pushed to `metricsStack`
   - From: `continuumMtaInboundService`
   - To: `metricsStack`
   - Protocol: Metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Uncategorized inbound domain | `vctx:set_code(552, "Denied by policy")` + disconnect | Connection rejected |
| Bounce message with non-null sender | Rejected with `552 Denied by policy`; not processed as OOB bounce | Sender receives rejection |
| Null recipient | `451 NULL recipient found` | Temporary rejection |
| RFC 2822 parse failure in DSN original | Error logged to `logs.policy`; `debug_log_msg` called; processing continues with available fields | Partial log record written with empty fields |
| FBL feedback-report part absent | Error logged; fallback body match for `X-RM-SendId` attempted | FBL record written with reduced fidelity |
| `X-MSFBL` header missing from FBL | Raw message body scanned for `X-MSFBL` pattern as fallback | Header recovered or field left empty |
| Admin/postmaster address | Message copied and injected to configured redirect address; original discarded | Admin mail forwarded; not treated as feedback |

## Sequence Diagram

```
ExternalISP -> continuumMtaInboundService: SMTP RCPT TO (response domain)
continuumMtaInboundService -> continuumMtaInboundService: Classify msg_type (bounce/fbl/unsub/r)
continuumMtaInboundService -> continuumMtaInboundService: Parse MIME parts, extract tracking headers
continuumMtaInboundService -> loggingStack: Write oob_csv/oob_jlog OR fbl_csv/fbl_jlog OR unsub_csv/unsub_jlog
continuumMtaInboundService -> continuumMtaInboundService: msg:discard(598)
continuumMtaInboundService -> continuumMtaEmailService: Feed bounce/FBL/unsubscribe outcomes for suppression
continuumMtaInboundIntService -> continuumMtaInboundService: Forward internal inbound events
continuumMtaInboundService -> metricsStack: Emit inbound processing metrics
```

## Related

- Architecture dynamic view: `dynamic-inbound-feedback-flow`
- Related flows: [Outbound Mail Delivery](outbound-mail-delivery.md)
