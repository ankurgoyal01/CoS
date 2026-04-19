---
service: "selfsetup-hbw"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 6
---

# Flows

Process and flow documentation for EMEA Booking Tool Self Setup — Health & Beauty.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Merchant Signup and Opportunity Lookup](merchant-signup-and-opportunity-lookup.md) | synchronous | User action — merchant follows Salesforce invitation URL | Merchant lands on the setup portal; the application resolves the Salesforce opportunity and initialises the session |
| [Merchant Complete Availability and Capacity Setup](merchant-complete-availability-and-capacity-setup.md) | synchronous | User action — merchant submits availability and capping forms | Merchant provides weekly availability windows and per-slot capacity caps; data is validated and stored |
| [Merchant Push Configuration to Salesforce and BookingTool](merchant-push-configuration-to-salesforce-and-bookingtool.md) | synchronous | User action — merchant submits final setup wizard step | Finalised setup configuration is pushed to Salesforce and to the BookingTool API |
| [Scheduled SSU Reminder and Reconciliation](scheduled-ssu-reminder-and-reconciliation.md) | scheduled | Cron schedule | Cron jobs send reminder emails to merchants with incomplete setups and reconcile local state with the DWH |
| [Merchant Edit and Update Existing Profile](merchant-edit-and-update-existing-profile.md) | synchronous | User action — returning merchant edits an existing setup | Merchant accesses a previously completed profile and updates availability, capping, or service details |
| [Health Check and Monitoring](health-check-and-monitoring.md) | synchronous | Infrastructure probe (EKS liveness) + background metric/log emission | EKS probes `/heartbeat.txt`; `ssuMetricsReporter` emits metrics; `ssuLogger` emits logs |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 4 |
| Asynchronous (event-driven) | 0 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- The [Merchant Push Configuration to Salesforce and BookingTool](merchant-push-configuration-to-salesforce-and-bookingtool.md) flow spans `continuumSsuWebApp`, `salesForce`, and `bookingToolApi` — three distinct systems.
- The [Scheduled SSU Reminder and Reconciliation](scheduled-ssu-reminder-and-reconciliation.md) flow involves the DWH reconciliation pipeline as a downstream sink.
- Central architecture dynamic views: no dynamic views are currently defined in the DSL (`views/dynamics.dsl` is empty).
