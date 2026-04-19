---
service: "mvrt"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumMvrt"]
---

# Architecture Context

## System Context

MVRT is a container within the `continuumSystem` — Groupon's legacy/modern commerce platform. It sits as an internal-facing ITier web application in the Continuum system boundary. Internal staff (EMEA merchant partner and CS agents) interact with MVRT via browser; MVRT calls out to core Continuum services through the `apiProxy` for voucher inventory operations, deal catalog lookups, and merchant data reads. Offline workflows also use AWS S3 (for file staging) and Rocketman (for transactional email). MVRT is deployed in the SOX namespace and is subject to SOX/PCI compliance controls.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MVRT Application | `continuumMvrt` | Web Application | Node.js, itier-server, Express | 14.17.0 / ^7.14.2 | Multi-Voucher Redemption Tool web application and background job runtime |

## Components by Container

### MVRT Application (`continuumMvrt`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Web Routing and Auth | Handles HTTP routes, request middleware, Okta user auth context, and view rendering | Express routes/middleware |
| Voucher Search Engine | Executes online and offline voucher and merchant/deal search workflows across multiple code types | Node.js module |
| Voucher Redemption Engine | Performs redemption workflows and status handling for vouchers (normal and forced modes) | Node.js module |
| File Export and Report Builder | Builds offline JSON/XLSX/CSV artifacts and orchestrates file download flows via S3 | Node.js module |
| Offline Job Scheduler | Runs scheduled batch processing (every 1 minute) and outbound notification pipeline via Rocketman | Node.js scheduler (node-schedule) |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMvrt` | `apiProxy` | Routes service-client requests via API Proxy | REST/HTTP |
| `continuumMvrt` | `continuumDealCatalogService` | Reads deal/product metadata | REST via service client |
| `continuumMvrt` | `continuumVoucherInventoryService` | Searches and redeems vouchers | REST via service client |
| `continuumMvrt` | `continuumM3MerchantService` | Reads merchant details | REST via service client |
| `continuumMvrt` | Rocketman | Sends offline notification and error emails | REST SDK (`@grpn/rocketman-client`) |
| `continuumMvrt` | AWS S3 | Stores and retrieves offline code/report files | AWS SDK |
| `mvrt_webRouting` | `voucherSearch` | Invokes voucher search workflows | Direct (in-process) |
| `mvrt_webRouting` | `voucherRedemption` | Invokes voucher redemption workflows | Direct (in-process) |
| `mvrt_webRouting` | `mvrt_fileExport` | Triggers offline export endpoints | Direct (in-process) |
| `voucherSearch` | `mvrt_fileExport` | Passes search results for file export and report generation | Direct (in-process) |
| `mvrt_fileExport` | `offlineProcessing` | Schedules and executes offline processing jobs | Direct (in-process) |
| `voucherRedemption` | `voucherSearch` | Reuses voucher lookup context before redemption | Direct (in-process) |

## Architecture Diagram References

- System context: `contexts-continuumSystem`
- Container: `containers-continuumSystem`
- Component: `components-mvrt_components`
- Dynamic (search and redeem flow): `dynamic-search_and_redeem_flow`
