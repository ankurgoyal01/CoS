---
service: "selfsetup-fd"
title: "Fetch Merchant BT Details"
generated: "2026-03-02T00:00:00Z"
type: flow
flow_name: "fetch-merchant-bt-details"
flow_type: synchronous
trigger: "Employee or internal component requests existing Booking Tool configuration details for a merchant"
participants:
  - "ssuWebControllers"
  - "selfsetupFd_ssuBookingToolClient"
  - "bookingToolSystem_7f1d"
architecture_ref: "dynamic-ssu_fd_self_setup_flow"
---

# Fetch Merchant BT Details

## Summary

This flow retrieves the current Booking Tool configuration details for a given merchant from the Booking Tool System. It is invoked by the Web Controllers — either in response to an employee requesting setup status in the wizard, or as a read step within a broader setup or review operation. The Booking Tool Client calls the BT API via HTTPS and returns the configuration data for display or processing.

## Trigger

- **Type**: user-action (or internal api-call as part of setup review)
- **Source**: `ssuWebControllers` initiates the fetch, typically triggered by an employee viewing merchant BT status in the wizard
- **Frequency**: On-demand (per page load or status check)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Web Controllers | Receives request and delegates to Booking Tool Client | `ssuWebControllers` |
| Booking Tool Client | Calls Booking Tool System API to retrieve merchant BT configuration | `selfsetupFd_ssuBookingToolClient` |
| Booking Tool System | External system; returns existing BT instance configuration for the merchant | `bookingToolSystem_7f1d` |

## Steps

1. **Receives merchant detail request**: Employee navigates to a merchant status or review page in the wizard; Web Controllers initiate the fetch.
   - From: `grouponEmployee_51c9`
   - To: `ssuWebControllers`
   - Protocol: HTTPS (browser GET)

2. **Delegates to Booking Tool Client**: Web Controllers call `selfsetupFd_ssuBookingToolClient` with the merchant identifier to retrieve BT details.
   - From: `ssuWebControllers`
   - To: `selfsetupFd_ssuBookingToolClient`
   - Protocol: direct (in-process)

3. **Calls Booking Tool API**: Booking Tool Client sends an HTTPS request to the Booking Tool System to fetch the merchant's current BT configuration.
   - From: `selfsetupFd_ssuBookingToolClient`
   - To: `bookingToolSystem_7f1d`
   - Protocol: HTTPS

4. **Returns BT configuration**: Booking Tool System responds with the merchant's BT instance details (options, status, configuration).
   - From: `bookingToolSystem_7f1d`
   - To: `selfsetupFd_ssuBookingToolClient`
   - Protocol: HTTPS

5. **Surfaces details to Web Controllers**: Booking Tool Client returns the parsed BT configuration to Web Controllers.
   - From: `selfsetupFd_ssuBookingToolClient`
   - To: `ssuWebControllers`
   - Protocol: direct (in-process)

6. **Renders response**: Web Controllers render the merchant BT details for the employee.
   - From: `ssuWebControllers`
   - To: `grouponEmployee_51c9`
   - Protocol: HTTPS (browser response)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Booking Tool API returns 404 (no BT instance found) | Booking Tool Client surfaces not-found result | Web Controllers display "no BT configured" message to employee |
| Booking Tool API connectivity failure | Request fails; exception surfaced by Booking Tool Client | Employee sees error page; manual retry required |
| Unexpected API response format | Booking Tool Client parsing error | Web Controllers surface error; no partial data displayed |

## Sequence Diagram

```
grouponEmployee_51c9            ->  ssuWebControllers: GET merchant BT status page
ssuWebControllers               ->  selfsetupFd_ssuBookingToolClient: Creates booking tool setup / fetch details
selfsetupFd_ssuBookingToolClient -> bookingToolSystem_7f1d: HTTPS GET (merchant BT configuration)
bookingToolSystem_7f1d          --> selfsetupFd_ssuBookingToolClient: BT configuration response
selfsetupFd_ssuBookingToolClient --> ssuWebControllers: BT details
ssuWebControllers               --> grouponEmployee_51c9: Merchant BT details page
```

## Related

- Architecture dynamic view: `dynamic-ssu_fd_self_setup_flow`
- Related flows: [Employee Initiates F&D Setup](employee-initiate-fd-setup.md), [Async Configure BT Options](async-configure-bt-options.md)
