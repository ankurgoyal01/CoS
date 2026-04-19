---
service: "momo-config"
title: "SMTP Authenticated Ingress"
generated: "2026-03-03"
type: flow
flow_name: "smtp-authenticated-ingress"
flow_type: synchronous
trigger: "Internal application or approved sender connecting to MTA SMTP Cluster with SMTP AUTH credentials"
participants:
  - "continuumMtaSmtpService"
  - "continuumMtaTransService"
  - "loggingStack"
  - "metricsStack"
architecture_ref: "dynamic-outbound-mail-flow"
---

# SMTP Authenticated Ingress

## Summary

The SMTP authenticated ingress flow handles mail injected by internal Groupon applications (e.g., Jira, internal tooling) or approved senders through the `continuumMtaSmtpService` cluster. Senders authenticate using SMTP AUTH with digest credentials stored in the SMTP credential file. The SMTP policy engine validates the submission, assigns a binding, and forwards the message to `continuumMtaTransService` for outbound delivery. This cluster is used for Groupon internal email (non-marketing) and trusted third-party relay.

## Trigger

- **Type**: api-call (SMTP AUTH + DATA)
- **Source**: Internal Groupon application or approved external sender connecting to the SMTP cluster's ESMTP listener
- **Frequency**: On-demand; driven by internal application events (e.g., Jira notifications, system alerts, internal tooling)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Internal Application / Approved Sender | Submits mail via authenticated SMTP | External to MTA clusters |
| MTA SMTP Cluster | Validates SMTP AUTH credentials; applies `smtp_policy.lua`; assigns binding; forwards to trans cluster | `continuumMtaSmtpService` |
| SMTP Credential Store | Digest credential file for sender authentication | `continuumMtaSmtpService` (`mtaSmtp_credentialStore`) |
| MTA Trans Cluster | Receives forwarded message; applies outbound policy, adaptive delivery, and DKIM signing; delivers to remote MX | `continuumMtaTransService` |
| Logging Stack | Receives SMTP ingress and delivery log records | `loggingStack` |
| Metrics Stack | Receives SMTP ingress metrics | `metricsStack` |

## Steps

1. **Establishes SMTP AUTH connection**: Internal application or approved sender connects to `continuumMtaSmtpService` ESMTP listener; EHLO negotiation; sender authenticates using SMTP AUTH with digest credentials validated against the SMTP credential store
   - From: Internal Application
   - To: `continuumMtaSmtpService`
   - Protocol: ESMTP (SMTP AUTH)

2. **Validates credentials**: SMTP cluster verifies sender credentials against the digest credential file (`smtp_passwd`); unauthenticated submissions are rejected
   - From: `continuumMtaSmtpService`
   - To: `continuumMtaSmtpService` (`mtaSmtp_credentialStore`)
   - Protocol: direct (file-based)

3. **Applies SMTP policy**: `smtp_policy.lua` (`mtaSmtp_policyEngine`) evaluates the submission; applies sender/recipient guards; validates routing controls; relay host allowlist applied from `relay_hosts.conf`
   - From: `continuumMtaSmtpService`
   - To: `continuumMtaSmtpService` (internal policy)
   - Protocol: direct

4. **Extracts tracking headers and assigns binding**: `validate_data_spool_each_rcpt` extracts Groupon tracking headers (`x-seed`, `x-virtual-mta`, `X-RM-*` headers) where present; maps to binding group via `groupon_config.bg_shared`; applies `bg_distribution` bucket selection; sets VERP return path via `X-RM-Clr`
   - From: `continuumMtaSmtpService`
   - To: `continuumMtaSmtpService` (internal)
   - Protocol: direct

5. **Applies adaptive delivery controls**: SMTP cluster applies adaptive throttle (25% rejection rate threshold); binding/domain suspension state consulted from LevelDB backstore
   - From: `continuumMtaSmtpService`
   - To: LevelDB Adaptive Backstore
   - Protocol: direct

6. **Forwards to MTA Trans Cluster**: Authenticated message forwarded to `continuumMtaTransService` via SMTP for outbound delivery
   - From: `continuumMtaSmtpService`
   - To: `continuumMtaTransService`
   - Protocol: SMTP

7. **Delivers to remote recipient MX**: Trans cluster applies outbound policy and delivers message to recipient's external MX server
   - From: `continuumMtaTransService`
   - To: Remote Recipient MX
   - Protocol: SMTP (port 25)

8. **Emits SMTP ingress and delivery logs**: Structured log records written for SMTP ingress events and delivery outcomes; forwarded to `loggingStack`
   - From: `continuumMtaSmtpService` / `continuumMtaTransService`
   - To: `loggingStack`
   - Protocol: Log pipeline

9. **Emits SMTP ingress metrics**: Connection and delivery metrics pushed to `metricsStack`
   - From: `continuumMtaSmtpService`
   - To: `metricsStack`
   - Protocol: Metrics

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Authentication failure | SMTP AUTH rejection | Sender receives 5xx authentication error; connection dropped |
| Relay denied (unauthorized sender/recipient) | `550 Relaying denied by policy` | Message rejected at SMTP envelope stage |
| Discard domain recipient | `msg:discard()` with 551 text | Message silently discarded |
| Null recipient | `451 NULL recipient found` | Temporary rejection |
| Adaptive suspension active | Message queued in spool; delivery deferred | Message retried after suspension expires (max `Message_Expiration = 259200`s) |
| Transient remote MX failure | Retry per `Retry_Interval = 1200`s | Retry loop; bounce generated on permanent failure (`Generate_Bounces = true` for SMTP cluster) |
| Bounce generated | SMTP cluster generates bounce (`Generate_Bounces = true`) and routes back to sender | Bounce notification delivered to original sender |

## Sequence Diagram

```
InternalApp -> continuumMtaSmtpService: ESMTP EHLO + AUTH (digest)
continuumMtaSmtpService -> CredentialStore: Validate digest credentials
CredentialStore --> continuumMtaSmtpService: Auth OK / Fail
continuumMtaSmtpService -> continuumMtaSmtpService: Apply smtp_policy, assign binding
continuumMtaSmtpService -> continuumMtaTransService: SMTP DATA (forwarded)
continuumMtaTransService -> continuumMtaTransService: Apply outbound policy, DKIM sign
continuumMtaTransService -> RemoteMX: SMTP DATA
RemoteMX --> continuumMtaTransService: 250 OK / 4xx / 5xx
continuumMtaSmtpService -> loggingStack: Write SMTP ingress log
continuumMtaTransService -> loggingStack: Write delivery log
continuumMtaSmtpService -> metricsStack: Emit SMTP ingress metrics
```

## Related

- Architecture dynamic view: `dynamic-outbound-mail-flow`
- Related flows: [Outbound Mail Delivery](outbound-mail-delivery.md), [Adaptive Delivery Control](adaptive-delivery-control.md)
