---
service: "Netsuite"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for NetSuite.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Vendor Bill Creation](vendor-bill-creation.md) | synchronous | REST POST to RESTlet from GLS | External system submits invoice data; NetSuite creates vendor bills or credits |
| [OTP Export to GLS](otp-export-gls.md) | scheduled | Timed interval (scheduled script) | Queries modified Drop-Ship purchase orders and pushes OTP JSON to GLS invoicing service |
| [OTP Export to PO Manager (EMEA)](otp-export-emea.md) | scheduled | Timed interval (scheduled script) | Queries modified EMEA purchase orders and pushes OTP JSON to PO Manager EMEA |
| [JPM ACH Payment Batch Submission](jpm-ach-payment-batch.md) | synchronous | Finance user action via Suitelet | Finance staff select staged payment files and submit ACH batch to JPMorgan Chase via SnapLogic |
| [Kyriba Treasury File Exchange](kyriba-treasury-exchange.md) | synchronous | Finance user action via Suitelet | Finance staff trigger Kyriba outbound (NS-to-Kyriba) or inbound (Kyriba-to-NS) file sync via SnapLogic |
| [Reconciliation Balance Pull](reconciliation-balance-pull.md) | synchronous | Finance user action via Suitelet | Finance staff trigger NS2 balance export to SnapLogic for BlackLine close process |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 3 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |
| User-triggered (Suitelet) | 1 |

## Cross-Service Flows

All flows that interact with external platforms (SnapLogic, JPM, Kyriba, BlackLine, GLS) span multiple services. The central architecture dynamic view `dynamic-netsuite-integration-flows` captures the top-level cross-service relationships. See [Architecture Context](../architecture-context.md) for participant IDs and [Integrations](../integrations.md) for dependency details.
