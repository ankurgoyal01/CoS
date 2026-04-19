---
service: "scs-jtier"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers:
    - "scsJtierService"
    - "continuumScsJtierReadMysql"
    - "continuumScsJtierWriteMysql"
---

# Architecture Context

## System Context

scs-jtier is a backend service within the Continuum platform responsible for managing user shopping cart state. It sits behind the GAPI/Lazlo API gateway, which handles all consumer-facing authentication before forwarding cart requests. The service reads from and writes to a dedicated MySQL DaaS database pair (read replica + primary), calls the Deal Catalog Service to validate deal data, calls inventory services to check purchasability, and publishes cart lifecycle events to the Groupon internal message bus (Mbus). The service is deployed across US and EMEA regions.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SCS JTier Service | `scsJtierService` | Application | Java, Dropwizard | 0.4.x | HTTP API server handling all cart operations and scheduled background jobs |
| SCS JTier Read MySQL | `continuumScsJtierReadMysql` | Database | MySQL | DaaS | Read replica for shopping cart data; handles all SELECT queries |
| SCS JTier Write MySQL | `continuumScsJtierWriteMysql` | Database | MySQL | DaaS | Primary shopping cart data store; handles all INSERT/UPDATE/DELETE |

## Components by Container

### SCS JTier Service (`scsJtierService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ScsJtierResource` | Exposes HTTP API endpoints for all cart operations | JAX-RS |
| `AddUpdateService` | Orchestrates add-to-cart and update-quantity requests | Java |
| `CartService` | Central cart business logic: load, persist, publish events, find abandoned/inactive carts | Java |
| `PurchasabilityChecker` | Validates each cart item against deal data and inventory availability | Java |
| `ShoppingCartReadDAO` | Reads cart records from the MySQL read replica via SQL queries | JDBI |
| `ShoppingCartWriteDAO` | Writes cart records to the MySQL primary via SQL statements | JDBI |
| `DealServiceClient` | Retrofit HTTP client for fetching deal data from `continuumDealService` | Retrofit |
| `InventoryServiceClient` | Retrofit HTTP client for checking inventory availability | Retrofit |
| `MessageBusPublisher` | Publishes cart events (`updated_cart`, `abandoned_cart`) to Mbus | Mbus |
| `AbandonedCartsJob` | Quartz scheduled job: scans for abandoned carts every 30 minutes | Quartz |
| `InactiveCartsJob` | Quartz scheduled job: marks and moves inactive carts on schedule | Quartz |
| `AbandonedCarts` | Worker that finds carts abandoned in a given window and publishes events | Java |
| `InactiveCarts` | Worker that marks carts as inactive or moves them to backup table | Java |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `scsJtierService` | `continuumScsJtierReadMysql` | Reads cart data (SELECT queries via ShoppingCartReadDAO) | JDBC |
| `scsJtierService` | `continuumScsJtierWriteMysql` | Writes cart data (INSERT/UPDATE/DELETE via ShoppingCartWriteDAO) | JDBC |
| `scsJtierService` | `continuumDealService` | Fetches deal data for purchasability validation | HTTPS |
| `scsJtierService` | `continuumGoodsInventoryService` | Checks goods inventory availability | HTTPS |
| `scsJtierService` | `continuumVoucherInventoryService` | Checks voucher inventory availability | HTTPS |
| `scsJtier_apiResource` | `cartService` | Reads and returns cart data for GET requests | direct |
| `scsJtier_apiResource` | `addUpdateService` | Delegates add/update cart mutations | direct |
| `addUpdateService` | `purchasabilityChecker` | Validates items before persisting | direct |
| `cartService` | `scsJtier_messageBusPublisher` | Publishes updated cart events after each mutation | Mbus |
| `abandonedCartsWorker` | `scsJtier_messageBusPublisher` | Publishes abandoned cart events on schedule | Mbus |

## Architecture Diagram References

- System context: `contexts-scsJtier`
- Container: `containers-scsJtier`
- Component: `components-scsJtierService-components`
