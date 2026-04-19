---
service: "clo-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for CLO Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Card Enrollment and CLO Activation](card-enrollment-clo-activation.md) | synchronous | API call from user / card network | User links a payment card to a CLO offer; enrollment is registered with Visa, Mastercard, or Amex |
| [Claim Processing and Statement Credit](claim-processing-statement-credit.md) | event-driven | Card network transaction callback | Qualifying purchase matched to enrolled offer; claim created and statement credit issued |
| [Deal-Linked Offer Management](deal-linked-offer-management.md) | event-driven | dealDistribution / dealSnapshot events | CLO offer inventory synced with Deal Catalog and distributed to card networks |
| [User Account Lifecycle](user-account-lifecycle.md) | event-driven | users.account / gdpr.erasure events | User account changes (creation, suspension, GDPR erasure) reflected in CLO enrollment state |
| [Scheduled Health Reporting](scheduled-health-reporting.md) | scheduled | sidekiq-scheduler recurring job | Periodic health and status reports generated and published |
| [Card Network File Transfer and Settlement](card-network-file-transfer-settlement.md) | batch | FileTransfer event / schedule | File-based settlement and statement credit files exchanged with Mastercard and Visa |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 3 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Claim Processing and Statement Credit** spans `continuumCloServiceApi`, `continuumCloServiceWorker`, `continuumCloServicePostgres`, `messageBus`, and `continuumOrdersService`. See architecture dynamic view `dynamic-clo-claim-processing`.
- **Deal-Linked Offer Management** spans `continuumCloServiceWorker`, `messageBus`, and `continuumDealCatalogService`.
- **User Account Lifecycle** spans `continuumCloServiceWorker`, `messageBus`, and `continuumUsersService`.
- **Card Network File Transfer and Settlement** spans `continuumCloServiceWorker` and external Visa/Mastercard networks.
