---
service: "subscription-programs-itier"
title: "Select Landing Page"
generated: "2026-03-03T00:00:00Z"
type: flow
flow_name: "select-landing-page"
flow_type: synchronous
trigger: "HTTP GET from browser to /programs/select"
participants:
  - "Browser"
  - "subscriptionProgramsItier"
  - "Birdcage"
  - "GeoDetailsAPI"
  - "GrouponV2APISelectMembership"
architecture_ref: "dynamic-select-landing"
---

# Select Landing Page

## Summary

This flow renders the Groupon Select subscription landing page when an authenticated user navigates to `/programs/select`. The service evaluates feature flags via Birdcage to determine the appropriate offer variant, resolves geo context, checks the user's current membership state from Groupon V2 API, and returns a server-rendered HTML page tailored to whether the user is a prospective member or already enrolled.

## Trigger

- **Type**: user-action
- **Source**: Browser HTTP GET to `/programs/select`
- **Frequency**: per-request

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Browser | Initiates navigation; renders returned HTML | — |
| Select I-Tier | Orchestrates upstream calls; renders HTML page | `subscriptionProgramsItier` |
| Birdcage | Evaluates feature flags to determine offer variant | — |
| GeoDetails API | Resolves user geo context / division | — |
| Groupon V2 API (Select Membership) | Returns current membership state for authenticated user | — |

## Steps

1. **Receives landing page request**: Authenticated browser sends `GET /programs/select` to `subscriptionProgramsItier`.
   - From: `Browser`
   - To: `subscriptionProgramsItier`
   - Protocol: REST / HTTPS

2. **Validates user authentication**: `itier-user-auth` middleware confirms the user session is valid. Unauthenticated users are redirected to login.
   - From: `subscriptionProgramsItier`
   - To: `subscriptionProgramsItier` (itier-user-auth middleware)
   - Protocol: direct (in-process)

3. **Evaluates feature flags**: Calls Birdcage to determine which offer variant (`purchg1`, `purchgg`, `purchge`) and page features are active for this user's context.
   - From: `subscriptionProgramsItier`
   - To: `Birdcage`
   - Protocol: REST / HTTPS

4. **Resolves geo context**: Calls GeoDetails API to determine the user's region, country, and division for locale-specific rendering.
   - From: `subscriptionProgramsItier`
   - To: `GeoDetails API`
   - Protocol: REST / HTTPS

5. **Fetches current membership state**: Calls Groupon V2 API (Select Membership) via `itier-groupon-v2-select-membership` to determine if the user is already a Select member, a cancelled member, or a non-member.
   - From: `subscriptionProgramsItier`
   - To: `Groupon V2 API (Select Membership)`
   - Protocol: REST / HTTPS

6. **Reads from Memcached**: Checks Memcached for cached membership state to avoid repeat API calls within the same session.
   - From: `subscriptionProgramsItier`
   - To: Memcached
   - Protocol: Memcached binary protocol

7. **Renders landing page**: Assembles membership state, geo context, feature flag assignments, and offer variant; renders Preact components server-side via Keldor; returns HTML page.
   - From: `subscriptionProgramsItier`
   - To: `Browser`
   - Protocol: REST / HTTPS (HTML response)

8. **Emits page view event**: Sends a landing page view tracking event to Tracking Hub via `tracking-hub-node`.
   - From: `subscriptionProgramsItier`
   - To: `Tracking Hub`
   - Protocol: REST / HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| User not authenticated | Redirect to login | User redirected to Groupon login page |
| Birdcage unavailable | Use default flag values | Default offer variant displayed |
| GeoDetails API unavailable | Fall back to default division/region | Page renders with default locale |
| Groupon V2 API unavailable | Treat user as non-member (default state) | Non-member offer shown regardless of actual status |
| Memcached unavailable | Fall through to live V2 API call | Elevated V2 API load |

## Sequence Diagram

```
Browser -> subscriptionProgramsItier: GET /programs/select
subscriptionProgramsItier -> subscriptionProgramsItier: Validate user session (itier-user-auth)
subscriptionProgramsItier -> Birdcage: Evaluate feature flags (variant selection)
Birdcage --> subscriptionProgramsItier: Flag assignments
subscriptionProgramsItier -> GeoDetailsAPI: Resolve geo context
GeoDetailsAPI --> subscriptionProgramsItier: Geo context (region, division)
subscriptionProgramsItier -> Memcached: Read membership state cache
Memcached --> subscriptionProgramsItier: Cache hit OR miss
subscriptionProgramsItier -> GrouponV2API (SelectMembership): GET membership state (on cache miss)
GrouponV2API --> subscriptionProgramsItier: Membership state
subscriptionProgramsItier -> TrackingHub: Emit page view event
subscriptionProgramsItier --> Browser: Rendered HTML landing page
```

## Related

- Architecture dynamic view: `dynamic-select-landing`
- Related flows: [Subscription Enrollment](subscription-enrollment.md), [Benefits Display](benefits-display.md)
