---
service: "itier-ttd-booking"
title: "Experimentation Serving"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "experimentation-serving"
flow_type: synchronous
trigger: "Inbound request to booking widget endpoint during GLive Booking Redesign Controller execution"
participants:
  - "Browser"
  - "continuumTtdBookingService"
  - "gliveBookingRedesignController"
  - "ExpyOptimizely"
architecture_ref: "dynamic-booking-reservation-reservationWorkflow"
---

# Experimentation Serving

## Summary

This flow describes how A/B experiment and feature flag assignments are evaluated and applied during booking widget rendering. When the `gliveBookingRedesignController` processes a booking page request, it evaluates experiment assignments via the Expy/Optimizely SDK (in-process) and injects the resulting variant configuration into the widget rendering context. This flow is a sub-flow of [Booking Widget Render](booking-widget-render.md) and does not have its own standalone endpoint.

## Trigger

- **Type**: api-call (sub-flow, triggered within booking widget render)
- **Source**: `gliveBookingRedesignController` invokes Expy/Optimizely SDK during request handling
- **Frequency**: Per request to `/live/checkout/booking/{dealId}`

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Originates the booking page request that triggers experiment evaluation | — |
| GLive Booking Redesign Controller | Evaluates experiment assignments and applies variant to rendering context | `gliveBookingRedesignController` |
| Expy / Optimizely SDK | In-process library that returns experiment variant assignments for the current user/request | External (in-process SDK) |

## Steps

1. **Receives booking request**: `gliveBookingRedesignController` begins processing GET `/live/checkout/booking/{dealId}`
   - From: `itierTtdBooking_webRouting`
   - To: `gliveBookingRedesignController`
   - Protocol: Direct

2. **Evaluates experiment assignments**: Controller invokes Expy/Optimizely SDK with user and request context to determine variant assignments for active experiments
   - From: `gliveBookingRedesignController`
   - To: Expy/Optimizely SDK (in-process)
   - Protocol: Direct (in-process function call)

3. **Receives variant assignments**: SDK returns experiment bucket/variant assignments based on user identifier and experiment configuration
   - From: Expy/Optimizely SDK
   - To: `gliveBookingRedesignController`
   - Protocol: Direct (in-process return value)

4. **Injects variant into rendering context**: Controller applies experiment variant configuration (e.g., feature toggles, UI layout flags) to the booking widget assembly payload
   - From: `gliveBookingRedesignController`
   - To: `gliveBookingRedesignController` (internal state)
   - Protocol: Direct

5. **Continues widget rendering**: Controller proceeds with normal data assembly and HTML rendering using the experiment-configured context (see [Booking Widget Render](booking-widget-render.md) steps 3–7)
   - From: `gliveBookingRedesignController`
   - To: `Browser`
   - Protocol: HTTPS (text/html)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Expy/Optimizely SDK fails to initialize | SDK initialization error caught at startup | Service falls back to control variant for all users; booking widget renders normally |
| Experiment assignment evaluation throws | In-process error handled by controller | Controller falls back to control variant; booking widget renders normally with default configuration |
| Missing `EXPY_API_KEY` | SDK initializes in no-op mode | All users receive control variant; no experiment data is recorded |
| Experiment not active or user not in segment | SDK returns control assignment | Control variant rendered; no A/B difference applied |

## Sequence Diagram

```
itierTtdBooking_webRouting -> gliveBookingRedesignController: route /live/checkout/booking/{dealId}
gliveBookingRedesignController -> ExpyOptimizely: evaluate experiment assignments (user context)
ExpyOptimizely --> gliveBookingRedesignController: variant assignment map
gliveBookingRedesignController -> gliveBookingRedesignController: inject variant config into render context
note over gliveBookingRedesignController: continues with data assembly and rendering
gliveBookingRedesignController --> Browser: text/html booking widget (variant-specific)
```

## Related

- Architecture dynamic view: `dynamic-booking-reservation-reservationWorkflow`
- Related flows: [Booking Widget Render](booking-widget-render.md)
