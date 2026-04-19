---
service: "ingestion-service"
title: Integrations
generated: "2026-03-03"
type: integrations
external_count: 3
internal_count: 3
---

# Integrations

## Overview

The ingestion-service integrates with three external SaaS systems and three internal Groupon platform services, all via synchronous HTTPS/REST. All downstream calls are made using Retrofit HTTP clients configured via `RetrofitConfiguration` blocks in the service YAML config. There is no circuit breaker framework in evidence; failed Salesforce ticket creation calls are handled via a MySQL job queue + Quartz retry job rather than a circuit breaker pattern.

## External Dependencies

| System | Protocol | Purpose | Critical | Architecture Ref |
|--------|----------|---------|----------|-----------------|
| Salesforce | HTTPS/REST | Creates and manages customer support cases, updates messaging sessions, stores survey responses, fetches account and opportunity data, processes merchant-approved refund orders | yes | `salesForce` |
| CAAP API | HTTPS/REST | Fetches memos, order information, customer attributes, and goods data; executes order refunds and Groupon Bucks issuance; fetches best incentive/promo codes; fetches Signifyd status | yes | `extCaapApi_85f2db0d` (stub — not in federated model) |
| Zingtree | HTTPS/REST | Fetches session transcripts and context for ticket escalation enrichment | no | `extZingtree_0f159531` (stub — not in federated model) |

### Salesforce Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Salesforce REST API v56.0 (standard objects) and v59.0 (surveys); configured via `salesforceConfiguration` and `salesforceMarketplaceConfiguration` YAML blocks; separate configs for CS and Marketplace channels
- **Auth**: Salesforce OAuth 2.0 client credentials flow; tokens cached in MySQL via `SfTokenDBI`
- **Purpose**: Primary CRM integration — creates `Case`, `EmailMessage`, `ContentVersion`, `ContentDocumentLink` objects via Salesforce Composite API (`/services/data/v56.0/composite/sobjects`); queries `Opportunity`, `Account`, `MessagingSession`, and `Surveys__c` objects via SOQL; processes merchant-approved refunds from SF data
- **Failure mode**: Ticket creation failures are persisted to MySQL job queue and retried asynchronously by `SfCreateTicketFailuresJob`. If Salesforce is unavailable during a ticket creation request, the API returns `500` with message "Error creating a ticket! It has been queued for a retry."
- **Circuit breaker**: No — retry handled via Quartz job queue pattern

### CAAP API Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `caapClient` and `caapProxyClient` Retrofit configuration blocks in YAML
- **Auth**: Internal Groupon service auth (details managed via JTier configuration)
- **Purpose**: Multi-purpose internal platform API — used to retrieve order details, customer attributes, inventory unit data, merchant data, memo records (for deal/merchant UUID), execute order refunds (`RefundOrdersRequestBody`), issue Groupon Bucks (`IssueBucksRequestBody`), and fetch the best available promo code for a user (`BestIncentiveResponse`)
- **Failure mode**: HTTP errors propagated to caller; partial refund failures recorded in `RefundOrdersResponseEntity.failedInventoryUnitIds`
- **Circuit breaker**: No evidence found in codebase

### Zingtree Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `zingtreeClient` Retrofit configuration block
- **Auth**: Internal configuration (details managed via JTier YAML)
- **Purpose**: Fetches session transcript data (`SessionDataResponse`) and context for enriching Salesforce case descriptions during ticket escalation
- **Failure mode**: If Zingtree is unavailable, escalation continues with a default description (`SF_TICKET_ZINGTREE_DEFAULT_DESCRIPTION = "<Description not provided>"`)
- **Circuit breaker**: No evidence found in codebase

## Internal Dependencies

| Service | Protocol | Purpose | Architecture Ref |
|---------|----------|---------|-----------------|
| Lazlo API | HTTPS/REST | Fetches deal details and merchant details for deal-related context enrichment | `lazloApi` |
| Orders RO Service | HTTPS/REST | Loads order information for refund workflow validation | `extOrdersRoService_416339e8` (stub — not in federated model) |
| Users Service | HTTPS/REST | Loads user/customer attributes and contact details | `continuumUsersService` |

### Lazlo API Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `lazloClient` Retrofit configuration block
- **Auth**: Internal Groupon service auth
- **Purpose**: Retrieves deal show data (`DealShowResponseWrapper`) — deal details, merchant information — used to enrich Salesforce case creation payloads and to serve the `/odis/api/v1/{domain}/deals/{dealId}` endpoint
- **Failure mode**: HTTP errors propagated to the API caller

### Orders RO Service Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `ordersROClient` Retrofit configuration block
- **Purpose**: Reads order information (`OrderShowResponseWrapper`, `OrdersIndexResponseWrapper`, `PaymentTransaction`) to support the refund workflow; determines order eligibility before submitting refund requests to CAAP
- **Failure mode**: HTTP errors propagated to caller

### Users Service Detail

- **Protocol**: HTTPS/REST
- **Base URL / SDK**: Configured via `usersServiceClient` Retrofit configuration block
- **Purpose**: Fetches customer/user details (`Customer` response object) for the `/odis/api/v1/{domain}/users` endpoint and for enriching escalation context
- **Failure mode**: HTTP errors propagated to caller

## Consumed By

> Upstream consumers are tracked in the central architecture model. Known consumers based on API design and Zingtree references:

| Consumer | Protocol | Purpose |
|----------|----------|---------|
| Zingtree chatbot | HTTPS/REST (webhook) | Triggers ticket creation at conversation end; queries deal/user/memo data during agent sessions |
| GSO internal tooling | HTTPS/REST | Queries memos, refunds, and user data for Customer Support agent workflows |

## Dependency Health

- **Salesforce**: No circuit breaker — failed ticket creation persisted to MySQL and retried by Quartz job on schedule
- **CAAP API**: No circuit breaker — HTTP errors propagated synchronously
- **Lazlo, Orders RO, Users Service, Zingtree**: No circuit breaker — HTTP errors propagated synchronously; Zingtree fallback to default description string
- **MySQL**: If max DB connections are reached, delete and recreate pods; see [Runbook](runbook.md) for procedure
