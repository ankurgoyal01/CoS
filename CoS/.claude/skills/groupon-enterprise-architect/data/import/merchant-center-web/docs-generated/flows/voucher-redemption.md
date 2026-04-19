---
service: "merchant-center-web"
title: "Voucher Redemption"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "voucher-redemption"
flow_type: synchronous
trigger: "Merchant redeems a customer voucher at point of service"
participants:
  - "merchantCenterWebSPA"
  - "continuumUmapi"
architecture_ref: "dynamic-continuum-voucher-redemption"
---

# Voucher Redemption

## Summary

The voucher redemption flow allows merchants to mark a customer's Groupon voucher as redeemed at the point of service. The merchant inputs a voucher code or scans it, the SPA submits the redemption request to UMAPI, and UMAPI records the redemption and confirms validity. This prevents double-redemption and keeps order state consistent in Groupon's commerce platform.

## Trigger

- **Type**: user-action
- **Source**: Merchant enters or scans a customer voucher code in the redemption UI.
- **Frequency**: On-demand (per customer visit/transaction).

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Merchant (browser) | Enters or scans voucher code | N/A (human actor) |
| Merchant Center Web SPA | Submits redemption request, displays result | `merchantCenterWebSPA` |
| UMAPI | Validates voucher, records redemption, returns status | `continuumUmapi` |

## Steps

1. **Merchant Navigates to Redemption UI**: Merchant opens the voucher redemption section of the portal.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA`
   - Protocol: Client-side route transition

2. **Merchant Enters Voucher Code**: Merchant types or scans the customer's voucher code into the input field.
   - From: Merchant (browser)
   - To: `merchantCenterWebSPA` (form engine)
   - Protocol: In-browser (direct)

3. **Client-Side Validation**: SPA validates the voucher code format using zod before submitting.
   - From: `merchantCenterWebSPA`
   - To: `merchantCenterWebSPA`
   - Protocol: In-browser (direct)

4. **Submit Redemption to UMAPI**: SPA posts the redemption request to UMAPI with the voucher code and merchant context.
   - From: `merchantCenterWebSPA`
   - To: `continuumUmapi`
   - Protocol: REST / HTTPS (proxied, Bearer token)

5. **UMAPI Validates and Records Redemption**: UMAPI checks the voucher is valid, unused, and belongs to this merchant's deal. Records the redemption timestamp.
   - From: `continuumUmapi`
   - To: `merchantCenterWebSPA`
   - Protocol: REST / HTTPS

6. **SPA Displays Redemption Result**: SPA shows a success confirmation (voucher details, customer name if available) or an error message if the voucher is invalid/already redeemed.
   - From: `merchantCenterWebSPA`
   - To: Merchant (browser)
   - Protocol: Client-side render

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Invalid voucher code format | zod validation blocks submission; inline error shown | Merchant re-enters code |
| Voucher already redeemed | UMAPI returns conflict/error; SPA shows "already redeemed" message | Merchant does not re-redeem |
| Voucher not found | UMAPI returns 404; SPA shows "voucher not found" message | Merchant verifies code with customer |
| UMAPI unavailable | react-query error state; error toast | Merchant cannot redeem; must retry when service recovers |
| Voucher expired | UMAPI returns expired status | SPA shows expiry message to merchant |

## Sequence Diagram

```
Merchant -> merchantCenterWebSPA: Enter voucher code
merchantCenterWebSPA -> merchantCenterWebSPA: Validate code format (zod)
merchantCenterWebSPA -> continuumUmapi: POST /vouchers/{code}/redeem
continuumUmapi -> continuumUmapi: Validate voucher (valid, unused, correct merchant)
continuumUmapi --> merchantCenterWebSPA: Redemption confirmed (voucher details)
merchantCenterWebSPA -> Merchant: Display redemption success
```

## Related

- Architecture dynamic view: `dynamic-continuum-voucher-redemption`
- Related flows: [Report Generation](report-generation.md), [Performance Monitoring](performance-monitoring.md)
