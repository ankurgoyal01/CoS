---
service: "Netsuite"
title: API Surface
generated: "2026-03-03"
type: api-surface
protocols: [rest]
auth_mechanisms: [api-key, bearer-token, custom-header]
---

# API Surface

## Overview

The NetSuite customizations expose inbound HTTP endpoints via the SuiteScript RESTlet and Suitelet mechanisms. RESTlets accept JSON payloads and are called by external integration consumers (primarily SnapLogic pipelines and the GLS invoicing service). Suitelets provide interactive browser-accessible UI pages used by finance operations staff to trigger payment batch submissions, treasury file exchanges, and reconciliation pulls. All outbound calls from NetSuite use `nlapiRequestURL` with Bearer token authorization targeting SnapLogic pipeline trigger URLs.

## Endpoints

### Vendor Bill / Credit RESTlet (GOODS — NS2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| POST | `GG_VendorBillExpense_RESTletv1` (NetSuite RESTlet) | Create vendor bills or vendor credits from GLS payment data | Custom headers (`x-client-id`, `x-signature`, `x-request-time`) |
| POST | `3p vb bill restlet` (NetSuite RESTlet) | Create third-party vendor bills | NetSuite session token |
| POST | `bill_po_restlet` (NetSuite RESTlet) | Create bills linked to purchase orders | NetSuite session token |

### Vendor Bank Info RESTlet (GOODS — NS2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET | `get_vendor_bank_info_restlet` (NetSuite RESTlet) | Retrieve vendor banking information for payment processing | NetSuite session token |

### Payment File Submission Suitelets (GOODS — NS2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `JPM Goods ACH Launch SnapLogic NS2 MP` (Suitelet) | Display and submit Goods Marketplace ACH payment files to JPM via SnapLogic | NetSuite session |
| GET/POST | `JPM Goods ACH Launch SnapLogic NS2 Trade` (Suitelet) | Display and submit Goods Trade ACH payment files to JPM via SnapLogic | NetSuite session |
| GET/POST | `JPM NS2 Send Goods MP to PS` (Suitelet) | Send Goods Marketplace payment files to payment system (global) | NetSuite session |
| GET/POST | `JPM NS2 Send Goods MP to PS US` (Suitelet) | Send Goods Marketplace payment files to payment system (US) | NetSuite session |
| GET/POST | `JPM NS2 Send Goods Trade to PS` (Suitelet) | Send Goods Trade payment files to payment system (global) | NetSuite session |
| GET/POST | `JPM NS2 Send Goods Trade to PS US` (Suitelet) | Send Goods Trade payment files to payment system (US) | NetSuite session |

### Kyriba Suitelets (GOODS — NS2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `Kyriba Inbound trigger` (Suitelet) | Trigger Kyriba inbound (NS-to-Kyriba) via SnapLogic | NetSuite session |
| GET/POST | `Kyriba Outbound Trigger` (Suitelet) | Trigger Kyriba outbound (Kyriba-to-NS) via SnapLogic | NetSuite session |

### Reconciliation Suitelets (GOODS — NS2)

| Method | Path | Purpose | Auth |
|--------|------|---------|------|
| GET/POST | `NS_Reconciliation_Pull` (Suitelet) | Trigger NS2 reconciliation balance pull via SnapLogic | NetSuite session |

### Outbound SnapLogic Trigger URLs (called from NetSuite)

| Method | URL Pattern | Purpose |
|--------|-------------|---------|
| POST | `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Banking/JPM%20NS2%20Send%20to%20ACH` | Submit ACH file to JPMorgan Chase |
| POST | `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Kyriba/Kyriba%20outbound%20parent%20Trigger` | Trigger Kyriba outbound pipeline |
| POST | `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Kyriba/Kyriba%20NS2%20Inbound%20Kickoff` | Trigger Kyriba inbound pipeline |
| POST | `https://elastic.snaplogic.com:443/api/1/rest/slsched/feed/GrouponProd/projects/Reconciliation/NS2%20Refresh%20Balance%20Trigger` | Trigger reconciliation balance refresh |

## Request/Response Patterns

### Common headers

Inbound RESTlet calls (from GLS/SnapLogic to NetSuite):
- `Content-Type: application/json`
- `x-client-id`: Client identifier for authentication
- `x-signature`: HMAC or pre-shared signature
- `x-request-time`: Unix timestamp in milliseconds

Outbound calls (from NetSuite to SnapLogic):
- `Authorization: Bearer <token>`
- `Content-Type: application/json`

### Error format

RESTlet responses return a JSON array. Each element contains:
```json
{
  "glsPaymentUuid": "<string>",
  "netsuiteRecordId": "<string or empty>",
  "status": "created | error",
  "message": "<description>",
  "billtype": "mktpl"
}
```
Errors include human-readable `message` fields such as `"missing vendor"`, `"governance exceeded"`, or `"process error: <code>: <detail>"`.

### Pagination

> Not applicable. RESTlet batch inputs are bounded by the `custscript_vb_min_usage` governance limit. Scheduled scripts paginate internally using NetSuite search result windows.

## Rate Limits

| Tier | Limit | Window |
|------|-------|--------|
| NetSuite governance | 1,000 units per scheduled script execution | Per execution |
| Script rescheduling threshold | Configurable via `custscript_push_emea_running_reset` / `custscript_push_gls_otp_running_reset` | Minutes |

## Versioning

RESTlet and Suitelet scripts are versioned via NetSuite Script Deployment records. API versioning is not applied via URL path; multiple versions of vendor bill numbering scripts coexist in the File Cabinet (e.g., `Groupon_SS_VendorBillNumbering 1.1.js` through `1_4_2.js`), with deployment activation controlling which version is live.

## OpenAPI / Schema References

> No evidence found in codebase. No OpenAPI spec, proto files, or GraphQL schema are present. RESTlet payload schemas are implicit in the SuiteScript source code.
