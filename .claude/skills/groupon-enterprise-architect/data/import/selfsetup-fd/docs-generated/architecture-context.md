---
service: "selfsetup-fd"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: [continuumEmeaBtSelfSetupFdApp, continuumEmeaBtSelfSetupFdDb]
---

# Architecture Context

## System Context

selfsetup-fd sits within the **Continuum** platform as an EMEA-regional internal tool. EMEA employees (`grouponEmployee_51c9`) access it via browser to initiate Food & Drinks merchant onboarding. The service integrates outward to **Salesforce** (via HTTPS) for opportunity data and to the **Booking Tool System** (`bookingToolSystem_7f1d`, via HTTPS) to create and configure merchant BT instances. Metrics are emitted to the **Telegraf gateway** (`telegrafGateway_6a2b`). All queue and session state is persisted in the owned MySQL database (`continuumEmeaBtSelfSetupFdDb`).

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| SSU FD Web App | `continuumEmeaBtSelfSetupFdApp` | WebApp | PHP/Zend | PHP 5.6, Zend 1.11.6 | Zend/PHP web application handling UI, API, and async queue processing for Booking Tool self-setup (Food & Drinks) |
| SSU FD Database | `continuumEmeaBtSelfSetupFdDb` | Database | MySQL | — | MySQL datastore for queue and setup state |

## Components by Container

### SSU FD Web App (`continuumEmeaBtSelfSetupFdApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `ssuWebControllers` | Handles UI and API HTTP requests via Zend MVC; routes to downstream components | Zend_Controller (PHP) |
| `ssuCappingService` | Calculates capacity and validation rules before Booking Tool setup is permitted | PHP |
| `selfsetupFd_ssuSalesforceClient` | Manages Salesforce OAuth and REST API calls for opportunity/merchant lookups | PHP / HTTPS |
| `selfsetupFd_ssuBookingToolClient` | Calls Booking Tool APIs to create and configure merchant BT instances | PHP / HTTPS |
| `ssuQueueRepository` | Persists and retrieves async setup jobs from the MySQL queue table | PHP / MySQL |
| `ssuCronJobs` | Scheduled scripts that process queued setup requests, send reminder emails, and resolve merchant IDs from Salesforce | PHP / cron |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `grouponEmployee_51c9` | `continuumEmeaBtSelfSetupFdApp` | Uses for merchant self-setup workflows | HTTPS (browser) |
| `continuumEmeaBtSelfSetupFdApp` | `continuumEmeaBtSelfSetupFdDb` | Reads/writes queue and setup state | MySQL |
| `continuumEmeaBtSelfSetupFdApp` | `salesForce` | Queries and updates Salesforce | HTTPS |
| `continuumEmeaBtSelfSetupFdApp` | `bookingToolSystem_7f1d` | Calls Booking Tool APIs | HTTPS |
| `continuumEmeaBtSelfSetupFdApp` | `telegrafGateway_6a2b` | Emits metrics | HTTP |
| `ssuWebControllers` | `ssuCappingService` | Calculates capping and validation | direct |
| `ssuWebControllers` | `selfsetupFd_ssuSalesforceClient` | Reads opportunity and merchant details | direct |
| `ssuWebControllers` | `selfsetupFd_ssuBookingToolClient` | Creates Booking Tool setup | direct |
| `ssuWebControllers` | `ssuQueueRepository` | Reads/writes setup queue | direct |
| `ssuCronJobs` | `selfsetupFd_ssuSalesforceClient` | Fetches merchant identifiers | direct |
| `ssuCronJobs` | `selfsetupFd_ssuBookingToolClient` | Creates Booking Tool setup | direct |
| `ssuCronJobs` | `ssuQueueRepository` | Processes queued setup requests | direct |

## Architecture Diagram References

- Component: `components-ssu_fd_components`
- Dynamic flow: `dynamic-ssu_fd_self_setup_flow`
