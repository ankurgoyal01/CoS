---
service: "momo-config"
title: "Outbound Mail Delivery"
generated: "2026-03-03"
type: flow
flow_name: "outbound-mail-delivery"
flow_type: asynchronous
trigger: "SMTP message injection from upstream email platform or authenticated SMTP sender"
participants:
  - "continuumMtaEmailService"
  - "continuumMtaTransService"
  - "continuumMtaSinkService"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-outbound-mail-flow"
---

# Outbound Mail Delivery

## Summary

The outbound mail delivery flow handles the full lifecycle of a campaign or transactional email from injection into the MTA email cluster through policy processing, adaptive routing, DKIM signing, and final delivery to the recipient's mailbox provider MX server. Suppressed or sink-bound traffic is routed to the `continuumMtaSinkService` rather than delivered externally. All delivery outcomes are logged to the `loggingStack`.

## Trigger

- **Type**: api-call (SMTP injection)
- **Source**: Upstream Groupon email platform or internal application submitting via the email cluster's ESMTP listener
- **Frequency**: On-demand, continuously throughout the day for campaign and transactional mail

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Groupon Email Platform | Upstream sender — injects messages via SMTP | External |
| MTA Email Cluster | Accepts mail, applies outbound policy, assigns binding/binding-group, constructs VERP return path | `continuumMtaEmailService` |
| MTA Trans Cluster | Applies transmission policy, DKIM signs, applies adaptive controls, delivers to remote MX | `continuumMtaTransService` |
| MTA Sink Cluster | Accepts and discards suppressed/test/sink-routed traffic | `continuumMtaSinkService` |
| Remote Recipient MX | Final delivery destination (external mailbox provider) | External |
| Logging Stack | Receives structured delivery and bounce log records | `loggingStack` |
| Metrics Stack | Receives throughput and rejection metrics | `metricsStack` |

## Steps

1. **Receives SMTP connection**: Upstream sender connects to `continuumMtaEmailService` ESMTP listener; relay host allowlist validated against `relay_hosts.conf`
   - From: `Groupon Email Platform`
   - To: `continuumMtaEmailService`
   - Protocol: ESMTP

2. **Validates RCPT TO**: `outbound_policy.lua` (`mod:validate_rcptto`) checks recipient domain direction; performs DNS MX lookup (`msys.dnsLookup`) to detect non-existent domains; detects Gmail MX patterns and sets TLS enforcement (`tls_policy = "encrypt"`, `use_starttls = "always"`, `tls_verify = "peer"`)
   - From: `continuumMtaEmailService`
   - To: External DNS
   - Protocol: DNS

3. **Extracts message headers and assigns binding**: `outbound_policy.lua` (`mod:validate_data_spool_each_rcpt`) extracts Groupon tracking headers (`X-RM-EmailName`, `X-RM-SendID`, `X-RM-UserHash`, `X-RM-Clr`, `X-RM-JobId`, `X-RM-TestGroups`, `X-RM-Promotions`, `X-Brand`, `businessGroup`, `campaignGroup`, `campaign_data`, `custom_campaign_tracking`, `X-MSFBL`, `x-seed`, `x-virtual-mta`); maps `x-virtual-mta` to binding group via `groupon_config.bg_shared`; applies `bg_distribution` for weighted bucket selection
   - From: `continuumMtaEmailService`
   - To: `continuumMtaEmailService` (internal policy)
   - Protocol: direct

4. **Constructs VERP return path**: Sets envelope sender to `<clr_token>@bounce.<from_domain>` for bounce tracking; sets `X-Feedback-ID` header for Gmail feedback loop; discards configured discard domains (`groupon_config.discard_domains`)
   - From: `continuumMtaEmailService`
   - To: `continuumMtaEmailService` (internal policy)
   - Protocol: direct

5. **Applies stable-environment sink routing**: In `"stable"` environment, recipient domains other than `groupon.com` and `grouponfraud.com` are rerouted to `groupon_config.sink` (`mta-sink-stable.grpn-mta-stable.us-west-1.aws.groupondev.com`) via `msg:routing_domain()`
   - From: `continuumMtaEmailService`
   - To: `continuumMtaEmailService` (policy) / `continuumMtaSinkService` (stable env)
   - Protocol: direct / SMTP

6. **Assigns binding group**: `mod:validate_set_binding` applies the resolved binding group name to the message; default binding group `"uk_commercial"` is applied when binding group maps to `"default"` in the email cluster
   - From: `continuumMtaEmailService`
   - To: `continuumMtaEmailService` (internal)
   - Protocol: direct

7. **Submits to MTA Trans Cluster**: Email cluster forwards the message to `continuumMtaTransService` via SMTP for transmission
   - From: `continuumMtaEmailService`
   - To: `continuumMtaTransService`
   - Protocol: SMTP

8. **Applies transmission outbound policy**: Trans cluster `outbound_policy.lua` re-applies header extraction, binding assignment, adaptive delivery controls; DKIM signs message with `opendkim` (RSA-SHA256, selector `s2048d20190430`, relaxed/relaxed canonicalization, signed headers: from, to, message-id, date, subject, Content-Type)
   - From: `continuumMtaTransService`
   - To: `continuumMtaTransService` (internal)
   - Protocol: direct

9. **Routes sink traffic**: Suppressed or sink-bound messages are forwarded to `continuumMtaSinkService`
   - From: `continuumMtaTransService`
   - To: `continuumMtaSinkService`
   - Protocol: SMTP

10. **Delivers to remote MX**: Trans cluster opens outbound SMTP connection to recipient's MX server; applies per-domain throttle profiles (connection limits, message-rate limits); respects adaptive delivery state from LevelDB backstore
    - From: `continuumMtaTransService`
    - To: Remote Recipient MX
    - Protocol: SMTP (port 25), TLS via STARTTLS where supported; enforced for Gmail

11. **Logs delivery outcome**: Custom loggers write structured delivery record to `/var/log/ecelerity/delivery.ec` and `/var/log/ecelerity/delivery.csv`; in-band bounce written to `/var/log/ecelerity/inband_bounce.ec` and `inband_bounce.csv` on failure
    - From: `continuumMtaEmailService` / `continuumMtaTransService`
    - To: `loggingStack`
    - Protocol: Log pipeline

12. **Emits delivery metrics**: Throughput, rejection, and adaptive-control metrics pushed to `metricsStack`
    - From: `continuumMtaTransService`
    - To: `metricsStack`
    - Protocol: Metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Null recipient | `vctx:set_code(451, "NULL recipient found")` | Message rejected with 451 |
| Discard domain recipient | `msg:discard()` with 551 text | Message silently discarded; logged |
| Non-existent MX domain | DNS lookup returns nil; message flagged | Delivery deferred or discarded |
| Remote MX transient failure | Retry per `Retry_Interval = 1200`s; adaptive throttle applied | Message retried up to `Message_Expiration` |
| Remote MX permanent failure | Logged to `inband_bounce.ec`; message expired | Bounce record written; message removed from queue |
| Adaptive suspension triggered | Delivery suspended for `adaptive_default_suspension = "1 hours"` for that binding/domain pair | Queue held; resumes after suspension window |
| Memory high-water mark reached | Ecelerity reduces intake; queue drains | Temporary injection throttle; delivery continues from spool |
| Relay denied | `vctx:set_code(550, "Relaying denied by policy")` | Connection rejected |

## Sequence Diagram

```
EmailPlatform -> continuumMtaEmailService: SMTP RCPT TO (outbound)
continuumMtaEmailService -> DNS: MX lookup for recipient domain
DNS --> continuumMtaEmailService: MX records (or NXDOMAIN)
continuumMtaEmailService -> continuumMtaEmailService: Extract headers, assign binding, set VERP return path
continuumMtaEmailService -> continuumMtaTransService: SMTP DATA (with tracking headers)
continuumMtaTransService -> continuumMtaTransService: Apply outbound policy, DKIM sign
continuumMtaTransService -> RemoteMX: SMTP DATA (STARTTLS where supported)
RemoteMX --> continuumMtaTransService: 250 OK (or 4xx/5xx)
continuumMtaTransService -> loggingStack: Write delivery.ec / delivery.csv
continuumMtaTransService -> metricsStack: Emit delivery metrics
```

## Related

- Architecture dynamic view: `dynamic-outbound-mail-flow`
- Related flows: [Inbound Feedback Processing](inbound-feedback-processing.md), [Adaptive Delivery Control](adaptive-delivery-control.md), [SMTP Authenticated Ingress](smtp-authenticated-ingress.md)
