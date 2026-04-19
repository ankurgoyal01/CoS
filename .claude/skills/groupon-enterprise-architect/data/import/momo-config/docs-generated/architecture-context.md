---
service: "momo-config"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumMtaEmailService, continuumMtaTransService, continuumMtaInboundService, continuumMtaInboundIntService, continuumMtaSmtpService, continuumMtaSinkService, continuumMtaDnsService]
---

# Architecture Context

## System Context

`momo-config` configures the MTA sub-system within `continuumSystem`. The MTA cluster group sits at the boundary of Groupon's email delivery infrastructure: it receives outbound mail from Groupon's email platform via SMTP and authenticated SMTP, delivers messages to external recipient MX servers, and processes inbound response traffic (bounces, Feedback Loop reports, and list-unsubscribe requests) arriving on Groupon's response domains (`bounce.r.grouponmail.co.uk`, `fbl.r.grouponmail.co.uk`, `r.grouponmail.co.uk`, `unsub.r.grouponmail.co.uk`). All clusters emit structured logs to `loggingStack` and metrics to `metricsStack`.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MTA Email Cluster | `continuumMtaEmailService` | Container | Momentum (MTA) | — | Outbound campaign and transactional mail cluster; applies outbound policy, domain routing, DKIM signing, and adaptive controls |
| MTA Trans Cluster | `continuumMtaTransService` | Container | Momentum (MTA) | — | Primary transmission cluster; applies outbound policy engine, DKIM signing, adaptive delivery, and routes to sink when suppressed |
| MTA Inbound Cluster | `continuumMtaInboundService` | Container | Momentum (MTA) | — | Processes inbound bounces, FBLs, and unsubscribe traffic from response domains; classifies and logs each event type |
| MTA Inbound Internal Cluster | `continuumMtaInboundIntService` | Container | Momentum (MTA) | — | Internal inbound processing profile for relay and HTTP delivery handlers used by internal pipelines |
| MTA SMTP Cluster | `continuumMtaSmtpService` | Container | Momentum (MTA) | — | Authenticated SMTP ingress endpoint for approved senders and internal applications |
| MTA Sink Cluster | `continuumMtaSinkService` | Container | Momentum (MTA) | — | Sink environment for suppressed, test, and discard traffic; applies discard and safety-routing policies |
| MTA DNS Service | `continuumMtaDnsService` | Container | BIND | — | Authoritative DNS for MTA-related domains and resolver behavior |

## Components by Container

### MTA Email Cluster (`continuumMtaEmailService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Email Outbound Policy (`mtaEmail_outboundPolicy`) | Lua policy set for outbound acceptance, binding assignment, domain routing, header extraction, VERP return-path construction, and per-binding-group distribution | Lua |
| Email Adaptive Rules (`mtaEmail_adaptiveRules`) | Adaptive domain and sweep override profiles; controls suspension thresholds and retry behavior per domain | Momentum Config |
| Email Domain Profiles (`mtaEmail_domainProfiles`) | Per-domain include files for relay routes, bounce handling, and DKIM-enabled delivery profiles | Momentum Config |

### MTA Trans Cluster (`continuumMtaTransService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Trans Outbound Policy (`mtaTrans_outboundPolicy`) | Primary outbound policy engine for transactional and campaign mail; handles binding group mapping, discard-domain filtering, and VERP return path | Lua |
| Trans DKIM Signer (`mtaTrans_dkimSigner`) | DKIM signing policy with RSA-SHA256, selector `s2048d20190430`, relaxed canonicalization for header and body | Lua/Momentum Config |
| Trans Adaptive Delivery (`mtaTrans_adaptiveDelivery`) | Adaptive delivery controls; per-domain connection and throttle limits (e.g., qq.com, walla.com, gmx.de) | Momentum Config |

### MTA Inbound Cluster (`continuumMtaInboundService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Inbound Policy Engine (`mtaInbound_policyEngine`) | Parses inbound response traffic; classifies bounce (OOB DSN), FBL (ARF), and unsubscribe message types; logs each to structured CSV/jlog files; discards after logging | Lua |
| Inbound Log Writer (`mtaInbound_logWriter`) | Structured log writer with sampling controls; writes to `/var/log/ecelerity/inbound_samples/`; manages per-type file I/O with mutex | Lua |
| Inbound Domain Classifier (`mtaInbound_domainClassifier`) | Domain/localpart mapping tables (`groupon_config.msg_types`) for message type selection across regional response domains | Lua Config |

### MTA Inbound Internal Cluster (`continuumMtaInboundIntService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Inbound Internal Policy Engine (`mtaInboundInt_policyEngine`) | Processes internal inbound traffic and applies internal routing/relay policies | Lua |
| Inbound Internal HTTP Delivery Adapters (`mtaInboundInt_httpDelivery`) | HTTP delivery adapters for internal consumers and pipelines | Lua |
| Inbound Internal Relay Domains (`mtaInboundInt_relayDomains`) | Allowlist and relay domain include configuration for internal ingress | Momentum Config |

### MTA SMTP Cluster (`continuumMtaSmtpService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| SMTP Policy Engine (`mtaSmtp_policyEngine`) | Authenticated SMTP ingress policy; sender/recipient guards and routing controls via `smtp_policy.lua` | Lua |
| SMTP Credential Store (`mtaSmtp_credentialStore`) | Digest credential file references for authenticated SMTP users | Momentum Config |

### MTA Sink Cluster (`continuumMtaSinkService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Sink Policy Engine (`mtaSink_policyEngine`) | Applies sink/discard handling policies for non-deliverable and suppressed traffic | Lua |
| Sink Bindings (`mtaSink_bindings`) | Sink cluster binding and logging include configuration | Momentum Config |

### MTA DNS Service (`continuumMtaDnsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| DNS Zone Definitions (`mtaDns_zoneDefinitions`) | Authoritative zone and resolver policies for MTA domains | BIND Config |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMtaEmailService` | `continuumMtaTransService` | Submits outbound campaign and transactional traffic for delivery | SMTP |
| `continuumMtaSmtpService` | `continuumMtaTransService` | Forwards authenticated SMTP submissions | SMTP |
| `continuumMtaTransService` | `continuumMtaSinkService` | Routes suppressed and controlled sink traffic | SMTP |
| `continuumMtaInboundService` | `continuumMtaEmailService` | Feeds bounce/FBL/unsubscribe outcomes into outbound suppression and hygiene controls | Event/Log |
| `continuumMtaInboundIntService` | `continuumMtaInboundService` | Shares inbound parsing policies and operational controls | Config/Policy |
| `continuumMtaDnsService` | `continuumMtaInboundService` | Publishes and resolves inbound response-domain DNS records | DNS |
| `continuumMtaDnsService` | `continuumMtaEmailService` | Publishes and resolves outbound sender-domain DNS records | DNS |
| `continuumMtaDnsService` | `continuumMtaTransService` | Publishes and resolves transmission-domain DNS records | DNS |
| `continuumMtaEmailService` | `loggingStack` | Emits delivery, bounce, and policy logs | Log pipeline |
| `continuumMtaTransService` | `loggingStack` | Emits transmission and routing logs | Log pipeline |
| `continuumMtaInboundService` | `loggingStack` | Emits inbound event-processing logs | Log pipeline |
| `continuumMtaInboundIntService` | `loggingStack` | Emits internal inbound-processing logs | Log pipeline |
| `continuumMtaSmtpService` | `loggingStack` | Emits SMTP ingress and auth logs | Log pipeline |
| `continuumMtaSinkService` | `loggingStack` | Emits sink/discard and safety-routing logs | Log pipeline |
| `continuumMtaEmailService` | `metricsStack` | Publishes throughput and rejection metrics | Metrics |
| `continuumMtaTransService` | `metricsStack` | Publishes delivery and adaptive-control metrics | Metrics |
| `continuumMtaInboundService` | `metricsStack` | Publishes bounce/FBL/unsubscribe processing metrics | Metrics |
| `continuumMtaSmtpService` | `metricsStack` | Publishes SMTP ingress metrics | Metrics |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-continuumMtaEmailService`, `components-continuumMtaTransService`, `components-continuumMtaInboundService`, `components-continuumMtaInboundIntService`, `components-continuumMtaSmtpService`, `components-continuumMtaSinkService`
- Dynamic views: `dynamic-outbound-mail-flow`, `dynamic-inbound-feedback-flow`
