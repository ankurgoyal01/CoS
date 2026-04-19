---
service: "voucher-inventory-jtier"
title: Flows
generated: "2026-03-03"
type: flows-index
flow_count: 5
---

# Flows

Process and flow documentation for Voucher Inventory JTier.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Inventory Product Lookup](inventory-product-lookup.md) | synchronous | Incoming HTTP GET request | API receives a product ID list, checks Redis cache, enriches with pricing and availability, and returns inventory data |
| [Inventory Event Processing](inventory-event-processing.md) | event-driven | MessageBus topic message | Worker consumes an inventory update event and refreshes the MySQL and Redis state |
| [Sold-Out Error Processing](sold-out-error-processing.md) | event-driven | Orders.Vouchers.SoldOutError topic | Worker receives a sold-out notification from Orders Service and updates inventory sold-out state |
| [Replenishment Job (Ouroboros)](replenishment-job.md) | scheduled | Quartz cron trigger | Worker fetches replenishment schedule data from Legacy VIS and updates the RW database |
| [Unit Redeem Job](unit-redeem-job.md) | scheduled | Quartz cron trigger | Worker downloads unit redeem CSV files from SFTP, processes them, and posts redeem updates to Legacy VIS |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 2 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The **Inventory Product Lookup** flow spans `continuumVoucherInventoryApi`, `continuumPricingService`, `continuumCalendarService`, `continuumVoucherInventoryRedis`, and the three MySQL databases.
- The **Inventory Event Processing** and **Sold-Out Error Processing** flows originate in external publishing services (e.g., VIS 2.0, Orders Service) and terminate in `continuumVoucherInventoryWorker`.
- The **Replenishment Job** and **Unit Redeem Job** flows originate in `continuumVoucherInventoryWorker` and reach `legacyVoucherInventoryService` and `transferSftp`.
