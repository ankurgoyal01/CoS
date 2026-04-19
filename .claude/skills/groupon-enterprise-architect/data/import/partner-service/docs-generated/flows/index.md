---
service: "partner-service"
title: Flows
generated: "2026-03-02T00:00:00Z"
type: flows-index
flow_count: 4
---

# Flows

Process and flow documentation for Partner Service.

## Flow Catalog

| Flow | Type | Trigger | Description |
|------|------|---------|-------------|
| [Partner Onboarding Workflow](partner-onboarding-workflow.md) | asynchronous | Operator API call or MBus event initiating onboarding | Multi-step workflow that creates and configures a new 3PIP partner across Salesforce, Deal Catalog, ePOS, and internal stores |
| [Deal Mapping Reconciliation](deal-mapping-reconciliation.md) | scheduled | Quartz scheduled job | Batch job that reconciles partner-to-deal mappings against Deal Catalog and Deal Management API to detect and repair drift |
| [Simulator Testing Workflow](simulator-testing-workflow.md) | synchronous | API call to simulator endpoints | On-demand testing flow that exercises partner integration paths against simulator state without affecting live data |
| [Partner Uptime and Metrics Reporting](partner-uptime-and-metrics-reporting.md) | scheduled | Quartz scheduled job | Scheduled job that collects partner uptime signals and publishes metrics events to MBus |

## Flow Types

| Type | Count |
|------|-------|
| Synchronous (request/response) | 1 |
| Asynchronous (event-driven) | 1 |
| Batch / Scheduled | 2 |

## Cross-Service Flows

- **Partner Onboarding Workflow** spans `continuumPartnerService`, `salesForce`, `continuumDealCatalogService`, `continuumDealManagementApi`, `continuumEpodsService`, `continuumUsersService`, and `messageBus`. See [Partner Onboarding Workflow](partner-onboarding-workflow.md).
- **Deal Mapping Reconciliation** spans `continuumPartnerService`, `continuumDealCatalogService`, `continuumDealManagementApi`, and `continuumGeoPlacesService`. See [Deal Mapping Reconciliation](deal-mapping-reconciliation.md).
