---
service: "momo-config"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

The MTA clusters interact with three categories of external systems (remote recipient MX servers, external ISPs delivering FBL/bounce traffic, and DKIM-signed DNS authorities) and three internal Groupon infrastructure services (`loggingStack`, `metricsStack`, `tracingStack`). No REST, gRPC, or SDK-based service integrations are evidenced in the configuration; all external communication is via SMTP and DNS protocols.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Remote Recipient MX Servers | SMTP (port 25) | Deliver outbound campaign and transactional email to recipient mailbox providers | yes | — |
| External ISPs / Mailbox Providers | SMTP (port 25, inbound) | Receive bounce DSN and FBL (ARF) reports from ISPs on response domains | yes | — |
| DNS (external resolvers) | DNS | MX record lookup for recipient domain validation (`msys.dnsLookup`) and routing; Gmail MX detection for TLS enforcement | yes | `continuumMtaDnsService` |

### Remote Recipient MX Servers Detail

- **Protocol**: SMTP (RFC 5321), TLS via STARTTLS where negotiated; TLS enforced for Gmail (detected by MX pattern match to `gmail.com`, `googlemail.com`, `google.com`)
- **Base URL / SDK**: Standard DNS MX resolution; static routes configured for specific ISPs (e.g., walla.com routed to `wmailbe05–07.walla.co.il`, `wmailne05–07.walla.co.il`)
- **Auth**: None for external delivery; TLS peer verification enabled for Gmail (`tls_verify = "peer"`)
- **Purpose**: Final-mile email delivery to subscriber mailboxes
- **Failure mode**: Transient failures retried per `Retry_Interval = 1200` seconds up to `Message_Expiration` (79201s email cluster, 259200s trans cluster); permanent failures logged as in-band bounces
- **Circuit breaker**: Adaptive delivery module acts as circuit breaker — suspends per-binding/domain delivery for `adaptive_default_suspension = "1 hours"` when rejection rate exceeds `adaptive_rejection_rate_suspension_percentage`

### External ISPs / FBL Senders Detail

- **Protocol**: SMTP inbound on port 25
- **Base URL / SDK**: ISPs submit to Groupon's response domains (`fbl.r.grouponmail.co.uk`, `bounce.r.grouponmail.co.uk`, `unsub.r.grouponmail.co.uk`)
- **Auth**: None; inbound relay limited to configured relay domains
- **Purpose**: Receive complaint (FBL/ARF), bounce (OOB DSN), and unsubscribe notifications from external mailbox providers; GMX FBL handled via special EHLO domain detection (`groupon_config.gmx_ehlo`)
- **Failure mode**: Messages that cannot be classified are rejected with `552 Denied by policy`
- **Circuit breaker**: Not applicable for inbound processing

### DNS Detail

- **Protocol**: DNS (UDP/TCP)
- **Base URL / SDK**: Ecelerity built-in resolver (`msys.dnsLookup`) used in outbound policy for MX validation and Gmail detection; authoritative DNS managed by `continuumMtaDnsService` (BIND)
- **Auth**: None
- **Purpose**: Validate recipient domain MX existence; detect Gmail-hosted domains for TLS enforcement; resolve static route overrides for partner ISPs
- **Failure mode**: MX lookup failure causes message to be held in queue; nil result logged as error
- **Circuit breaker**: No; DNS failures result in deferred delivery

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| `loggingStack` | Log pipeline | Receives structured delivery, bounce, FBL, unsubscribe, and rejection logs from all MTA clusters | `loggingStack` |
| `metricsStack` | Metrics push | Receives throughput, rejection rate, and adaptive delivery metrics from email, trans, inbound, and SMTP clusters | `metricsStack` |
| `tracingStack` | Tracing | Receives trace data from MTA clusters (stub referenced in DSL) | `tracingStack` |

## Consumed By

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Groupon Email Platform | SMTP | Injects outbound campaign and transactional mail into `continuumMtaEmailService` and `continuumMtaTransService` |
| Internal Applications | SMTP AUTH | Submit mail through `continuumMtaSmtpService` using authenticated SMTP (digest credentials) |
| External ISPs | SMTP (inbound) | Deliver bounce DSN, FBL, and unsubscribe traffic to `continuumMtaInboundService` on response domains |

> Upstream consumers are tracked in the central architecture model.

## Dependency Health

The adaptive delivery module provides automatic throttle management and suspension for outbound delivery paths — if a destination ISP begins rejecting at high rates, the adaptive module suspends that binding/domain combination for one hour (`adaptive_default_suspension = "1 hours"`). LevelDB backs the adaptive state to survive restarts. SNMP monitoring is enabled on all clusters at `127.0.0.1:8162` (community `public`) for local health instrumentation. Panic logs are written to `/var/log/ecelerity/paniclog.ec`. No circuit breaker is configured for `loggingStack` or `metricsStack` — log write failures are surfaced via the Ecelerity panic log.
