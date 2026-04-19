---
service: "momo-config"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [smtp, esmtp]
auth_mechanisms: [smtp-auth-digest, tls-client]
---

# API Surface

## Overview

`momo-config` does not expose an HTTP/REST/gRPC API. The MTA clusters it configures accept mail exclusively via SMTP and Extended SMTP (ESMTP). There are three distinct ingress surfaces: the outbound email cluster (receives injected campaign/transactional mail from upstream senders), the authenticated SMTP cluster (receives mail from internal applications using SMTP AUTH), and the inbound cluster (receives bounce and FBL responses from external ISPs on the response domains).

## Endpoints

### Outbound Email Cluster — ESMTP Ingress

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| SMTP DATA | Port defined in `esmtp_listener.conf` | Accepts outbound campaign and transactional mail from upstream email platform | Relay host allowlist (`relay_hosts.conf`) |
| SMTP DATA | Port `40128` | Custom-logged channel for transactional mail with extended header extraction (`x-ex-uuid`, `x-uuid`, `x-mess-uuid`, `x-ex-key`, `x-jrny-key`, `x-ut-id`, `x-rc-id`, `x-sl-send`) | Relay host allowlist |

### MTA Trans Cluster — ESMTP Ingress

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| SMTP DATA | Port defined in `esmtp_listener.conf` | Accepts forwarded outbound mail from email and SMTP clusters for transmission to external recipients | Relay host allowlist |

### MTA SMTP Cluster — Authenticated SMTP Ingress

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| SMTP AUTH + DATA | Port defined in `esmtp_listener.conf` | Accepts mail from approved internal senders using SMTP AUTH (digest credentials) | SMTP AUTH (digest credentials file) |

### MTA Inbound Cluster — ESMTP Ingress (Response Domains)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| SMTP DATA | Port 25 (`Remote_SMTP_Port = 25`) | Accepts OOB bounce DSN messages addressed to `bounce.r.grouponmail.co.uk` | None (open MX) |
| SMTP DATA | Port 25 | Accepts FBL (ARF) reports addressed to `fbl.r.grouponmail.co.uk` and FBL localparts on `r.grouponmail.co.uk` | None (open MX) |
| SMTP DATA | Port 25 | Accepts list-unsubscribe requests addressed to `unsub.r.grouponmail.co.uk` | None (open MX) |

## Request/Response Patterns

### Common headers

Outbound mail injected into the email and trans clusters carries Groupon-specific tracking headers extracted by the outbound policy engine:

- `X-RM-EmailName` — email campaign name
- `X-RM-SendID` — send/campaign ID
- `X-RM-UserHash` / `X-RM-Clr` — subscriber identifier / VERP token
- `X-RM-JobId` — job identifier
- `X-RM-TestGroups` — A/B test group assignment
- `X-RM-Promotions` — promotions flag
- `X-Brand` — brand identifier
- `businessGroup` / `campaignGroup` — business/campaign group
- `campaign_data` / `custom_campaign_tracking` — campaign metadata
- `X-RM-ScheduledSendTime` — scheduled delivery time
- `X-RM-Engaged` — engagement flag (used for binding group override)
- `x-virtual-mta` / `x-seed` — binding group or binding override directives
- `X-MSFBL` — Microsoft FBL token
- `X-Feedback-ID` — Gmail feedback loop header (set by policy)

### Error format

SMTP standard response codes are used. Custom policy-defined rejection codes include:

- `550` — Relaying denied by policy
- `551` — Domain silently discarded by policy
- `552` — Denied by policy (generic)
- `553` — IP auto-reply rate limit exceeded
- `554` — Recipient auto-reply rate limit exceeded
- `598` — Internal discard after logging (bounce/FBL/unsubscribe processing complete)
- `451` — NULL recipient found

### Pagination

> Not applicable. SMTP is a message-per-session protocol; pagination does not apply.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| IP auto-reply audit | 2 messages per CIDR | 300 seconds |
| Recipient auto-reply audit | 6 messages per recipient | 600 seconds |
| Adaptive suspension (email/trans) | Triggered at 50% rejection rate | Per adaptive cycle |
| Adaptive suspension (smtp) | Triggered at 25% rejection rate | Per adaptive cycle |
| Default adaptive suspension duration | 1 hour | Per binding/domain |
| Per-domain: qq.com / vip.qq.com / foxmail.qq.com | Max 1 outbound connection, 5 messages throttle | Per connection |
| Per-domain: gmx.de / web.de | Max 9 outbound connections, 60 messages per 20s | Rolling window |
| Per-domain: gmx.net | Max 9 outbound connections, 1331 messages per 900s | Rolling window |
| Global outbound | `Server_Max_Outbound_Connections = 20000`, `Max_Outbound_Connections = 32` per binding/domain | Per node |

## Versioning

> Not applicable. SMTP protocol versioning is handled by EHLO capability negotiation. MTA configuration is versioned via Git on the `master` branch.

## OpenAPI / Schema References

> No evidence found in codebase. The MTA clusters expose no HTTP APIs and therefore have no OpenAPI/proto/GraphQL schemas. Protocol is SMTP/ESMTP as defined by RFC 5321.
