---
service: "momo-config"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for momo-config (Momentum MTA Clusters).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Outbound Mail Delivery](outbound-mail-delivery.md) | asynchronous | SMTP message injection from upstream email platform or authenticated sender | Email cluster or SMTP cluster accepts, applies policy, hands off to trans cluster for delivery to remote MX |
| [Inbound Feedback Processing](inbound-feedback-processing.md) | event-driven | SMTP connection from external ISP to response domain | Inbound cluster receives bounce/FBL/unsubscribe, classifies, logs, discards; feeds outcomes to outbound suppression |
| [Adaptive Delivery Control](adaptive-delivery-control.md) | asynchronous | Remote MX rejection rate exceeding suspension threshold | Adaptive module monitors per-binding/domain rejection rates, applies throttles and suspensions, resumes delivery |
| [SMTP Authenticated Ingress](smtp-authenticated-ingress.md) | synchronous | Authenticated SMTP connection from internal application | SMTP cluster validates credentials, accepts message, forwards to trans cluster for delivery |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 0 |
| Event-driven | 1 |

## Cross-Service Flows

- **Outbound mail delivery** spans `continuumMtaEmailService` and `continuumMtaTransService`; referenced in architecture dynamic view `dynamic-outbound-mail-flow`
- **Inbound feedback processing** spans `continuumMtaInboundService`, `continuumMtaEmailService`, and `loggingStack`; referenced in architecture dynamic view `dynamic-inbound-feedback-flow`
- **SMTP authenticated ingress** spans `continuumMtaSmtpService` and `continuumMtaTransService`; part of `dynamic-outbound-mail-flow`
- Sink routing (suppressed traffic) spans `continuumMtaTransService` and `continuumMtaSinkService`; part of `dynamic-outbound-mail-flow`
