---
service: "mygroupons"
title: "Request Voucher PDF Download"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "request-voucher-pdf-download"
flow_type: synchronous
trigger: "User requests /mygroupons/vouchers/:id/pdf"
participants:
  - "browser"
  - "continuumMygrouponsService"
  - "apiProxy"
  - "continuumUsersService"
  - "continuumOrdersService"
  - "continuumDealCatalogService"
  - "continuumVoucherInventoryService"
  - "barcodeService"
architecture_ref: "dynamic-mygroupons-pdf-download"
---

# Request Voucher PDF Download

## Summary

This flow generates a printable PDF version of a voucher for the authenticated user. The service fetches voucher, deal, and barcode data, renders a full HTML voucher page internally, then uses Puppeteer with headless Chromium to print it to PDF and stream the binary PDF response to the browser.

## Trigger

- **Type**: user-action
- **Source**: Browser GET request to `/mygroupons/vouchers/:id/pdf`
- **Frequency**: On demand — triggered when a customer clicks "Download PDF" on a voucher detail page

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Requests PDF; receives binary PDF stream | — |
| My Groupons Service | Route handler, data orchestration, Puppeteer PDF rendering | `continuumMygrouponsService` |
| API Proxy | Routes outbound downstream HTTP calls | `apiProxy` |
| Users Service | Validates session and confirms ownership of the voucher | `continuumUsersService` |
| Orders Service | Returns voucher details and redemption data | `continuumOrdersService` |
| Deal Catalog Service | Returns deal metadata and redemption instructions | `continuumDealCatalogService` |
| Voucher Inventory Service | Confirms voucher state and validity | `continuumVoucherInventoryService` |
| Barcode Service | Generates barcode image data for inclusion in PDF | — |

## Steps

1. **Receives PDF request**: Browser sends `GET /mygroupons/vouchers/:id/pdf` with session cookie.
   - From: `browser`
   - To: `continuumMygrouponsService`
   - Protocol: REST/HTTP

2. **Validates session and ownership**: keldor validates session; Users Service confirms the user owns the requested voucher.
   - From: `continuumMygrouponsService`
   - To: `continuumUsersService` (via `apiProxy`)
   - Protocol: REST/HTTP

3. **Fetches voucher data**: Calls Orders Service to retrieve the voucher details and redemption code.
   - From: `continuumMygrouponsService`
   - To: `continuumOrdersService` (via `apiProxy`)
   - Protocol: REST/HTTP

4. **Checks voucher state**: Validates voucher is active and eligible for PDF download via Voucher Inventory Service.
   - From: `continuumMygrouponsService`
   - To: `continuumVoucherInventoryService` (via `apiProxy`)
   - Protocol: REST/HTTP

5. **Fan-out enrichment**: In parallel, fetches deal metadata from Deal Catalog and generates barcode data from Barcode Service.
   - From: `continuumMygrouponsService`
   - To: `continuumDealCatalogService`, Barcode Service (via `apiProxy`)
   - Protocol: REST/HTTP

6. **Renders HTML voucher**: Assembles all data and renders the voucher as a self-contained HTML document using Preact and Mustache.
   - From: `continuumMygrouponsService` (internal)
   - To: `continuumMygrouponsService` (internal)
   - Protocol: direct

7. **Generates PDF**: Launches Puppeteer with Chromium, loads the rendered HTML, prints to PDF with appropriate paper size and margins.
   - From: `continuumMygrouponsService` (internal)
   - To: Chromium (Puppeteer subprocess)
   - Protocol: direct

8. **Streams PDF to browser**: Sets `Content-Type: application/pdf` and `Content-Disposition: attachment` headers, streams the PDF binary to the browser.
   - From: `continuumMygrouponsService`
   - To: `browser`
   - Protocol: REST/HTTP

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Session invalid | keldor redirects to login | Redirect to sign-in page |
| Voucher not owned by user | Returns 403 | Permission denied error page |
| Orders Service unavailable | Critical failure | 500 error returned |
| Chromium/Puppeteer launch fails | Critical failure | 500 error returned |
| Puppeteer timeout | Kills subprocess; returns error | 500 error with timeout message |
| Barcode Service unavailable | Non-critical; barcode omitted from PDF | PDF generated without barcode |

## Sequence Diagram

```
Browser -> MyGrouponsService: GET /mygroupons/vouchers/:id/pdf
MyGrouponsService -> APIProxy: validate session + ownership
APIProxy -> UsersService: resolve user
UsersService --> APIProxy: user data
APIProxy --> MyGrouponsService: user data
MyGrouponsService -> APIProxy: fetch voucher details
APIProxy -> OrdersService: get voucher by id
OrdersService --> APIProxy: voucher details
APIProxy --> MyGrouponsService: voucher details
MyGrouponsService -> APIProxy: check voucher state (parallel)
MyGrouponsService -> APIProxy: fetch deal metadata (parallel)
MyGrouponsService -> APIProxy: generate barcode (parallel)
APIProxy --> MyGrouponsService: voucher state
APIProxy --> MyGrouponsService: deal metadata
APIProxy --> MyGrouponsService: barcode data
MyGrouponsService -> MyGrouponsService: render HTML voucher (Preact + Mustache)
MyGrouponsService -> Chromium: print HTML to PDF (Puppeteer)
Chromium --> MyGrouponsService: PDF binary
MyGrouponsService --> Browser: PDF binary (Content-Type: application/pdf)
```

## Related

- Architecture dynamic view: `dynamic-mygroupons-pdf-download`
- Related flows: [Render My Groupons Page](render-mygroupons-page.md), [Exchange Voucher](exchange-voucher.md)
