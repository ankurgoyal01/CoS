---
service: "bots"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for BOTS (Booking Oriented Tools & Services).

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Booking Creation and Confirmation](booking-creation-and-confirmation.md) | synchronous | API call — `POST /merchants/{id}/bookings` | Customer or merchant initiates a new booking; BOTS validates, persists, and publishes a booking-created event |
| [Booking Availability Query](booking-availability-query.md) | synchronous | API call — `GET /merchants/{id}/availability` | Merchant or consumer queries available booking slots; BOTS computes availability from stored windows and existing bookings |
| [Deal Onboarding and Initialization](deal-onboarding-and-initialization.md) | event-driven | Message Bus event — `deal.onboarding` | BOTS receives a deal onboarding event and initializes merchant booking configuration (campaigns, services, availability) |
| [Calendar Synchronization Background Job](calendar-synchronization-background-job.md) | scheduled | Quartz scheduler — periodic interval | BOTS Worker runs a Google Calendar import/export job to keep merchant calendars in sync with BOTS booking data |
| [Voucher Redemption Processing](voucher-redemption-processing.md) | synchronous + asynchronous | API call — `PUT /merchants/{id}/bookings/{id}/checkin` + Worker job | Customer checks in for a booking; BOTS coordinates voucher redemption with VIS and publishes a booking-checked-in event |
| [GDPR Data Erasure](gdpr-data-erasure.md) | event-driven | Message Bus event — `gdpr.erasure` | BOTS Worker receives a GDPR erasure request and deletes or anonymizes personal data from booking records |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 2 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 1 |
| Hybrid (synchronous + asynchronous) | 1 |

## Cross-Service Flows

- **Booking Creation and Confirmation** spans `continuumBotsApi`, `continuumM3MerchantService`, `continuumVoucherInventoryService`, `continuumCalendarService`, and `messageBus`. See architecture dynamic view: `dynamic-bots-booking-request-flow`.
- **Deal Onboarding and Initialization** spans `messageBus`, `continuumBotsWorker`, `continuumDealManagementService`, `continuumDealCatalogService`, `salesForce`, and `continuumBotsMysql`.
- **Voucher Redemption Processing** spans `continuumBotsApi`, `continuumBotsWorker`, and `continuumVoucherInventoryService`.
- **GDPR Data Erasure** spans `messageBus`, `continuumBotsWorker`, and `continuumBotsMysql`.
