---
service: "proximity-ui"
title: "Application Startup and Auth Gate"
generated: "2026-03-03"
type: flow
flow_name: "app-startup-auth-gate"
flow_type: synchronous
trigger: "Browser loads the Proximity UI SPA"
participants:
  - "administrator"
  - "continuumProximityUi"
  - "proximityWebUi"
  - "proximityApiRouter"
  - "proximityUserApiProxy"
  - "continuumProximityHotzoneApi"
architecture_ref: "components-continuumProximityUi"
---

# Application Startup and Auth Gate

## Summary

When a user navigates to the Proximity UI in a browser, the Vue.js SPA bootstraps itself by making two sequential API calls: one to retrieve the current user's identity, and one to retrieve the allowlist of authorized users. If the current user is present in the allowlist, the router mounts all management screens. If not, every route maps to the `Permission` view, effectively locking out the user.

## Trigger

- **Type**: user-action
- **Source**: Browser navigates to the Proximity UI URL (e.g., `proximity.groupondev.com`)
- **Frequency**: On every page load / SPA bootstrap

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Administrator | Initiates by loading the page in their browser | `administrator` |
| Proximity UI (Express server) | Serves `index.html`; handles `/api/proximity/users/current` and `/api/proximity/users` | `continuumProximityUi` |
| Web UI Router and Views | Vue app bootstrap code in `src/main.js`; registers router routes based on auth result | `proximityWebUi` |
| Proximity API Router | Routes `/api/proximity/users/*` requests to the user proxy | `proximityApiRouter` |
| User API Proxy | Extracts `X-Remote-User` header for current user; proxies user list request to Hotzone API | `proximityUserApiProxy` |
| Continuum Proximity Hotzone API | Returns the authorized user list | `continuumProximityHotzoneApi` |

## Steps

1. **Browser requests page**: Administrator navigates to the Proximity UI URL.
   - From: `administrator` (browser)
   - To: `continuumProximityUi` (Nginx + Express)
   - Protocol: HTTPS

2. **Express serves index.html**: The catch-all Express route returns `index.html`, which loads the bundled Vue SPA assets.
   - From: `continuumProximityUi`
   - To: `administrator` (browser)
   - Protocol: HTTP

3. **SPA requests current user**: The Vue bootstrap code calls `GET /api/proximity/users/current` via `vue-resource`.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP (same-origin AJAX)

4. **User API Proxy resolves current user**: The `proximityUserApiProxy` reads the `X-Remote-User` request header (set by Nginx) and returns `{ user: "<username>" }` without calling the upstream API.
   - From: `proximityUserApiProxy`
   - To: `proximityWebUi`
   - Protocol: HTTP (JSON response)

5. **SPA requests user allowlist**: The Vue bootstrap code calls `GET /api/proximity/users` via `vue-resource`.
   - From: `proximityWebUi`
   - To: `proximityApiRouter`
   - Protocol: HTTP (same-origin AJAX)

6. **User API Proxy fetches allowlist**: The `proximityUserApiProxy` proxies the request to `continuumProximityHotzoneApi` at `/v1/proximity/location/hotzone/users?client_id=ec-team`.
   - From: `proximityUserApiProxy`
   - To: `continuumProximityHotzoneApi`
   - Protocol: HTTP GET

7. **Hotzone API returns user list**: The upstream API responds with `{ users: ["user1", "user2", ...] }`.
   - From: `continuumProximityHotzoneApi`
   - To: `proximityUserApiProxy` -> `proximityWebUi`
   - Protocol: HTTP JSON

8. **Vue router applies auth gate**: The bootstrap code checks whether the current user's name is in `userList`. If authenticated, the full route map (home, summary, create, delete, campaigns, etc.) is registered. If not, all routes map to the `Permission` view.
   - From: `proximityWebUi` (internal)
   - To: Vue Router
   - Protocol: in-process

9. **Router starts the app**: `router.start({ components: { App } }, 'body')` mounts the SPA and navigates to the initial route.
   - From: Vue Router
   - To: `administrator` (browser renders the UI)
   - Protocol: DOM

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `GET /api/proximity/users/current` fails | No explicit error handling in `src/main.js`; promise rejection is unhandled | `remoteUser` remains undefined; user list check fails; user is shown Permission screen |
| `GET /api/proximity/users` fails | No explicit error handling; the `.then()` chain that calls `router.start()` does not execute | SPA fails to mount; blank page |
| Current user not in allowlist | `authenticated` is set to `false`; all routes map to `Permission` component | User sees the Permission view on every route |

## Sequence Diagram

```
Administrator     -> ProximityUI (Nginx+Express): GET / (page load)
ProximityUI       -> Administrator: 200 index.html (loads Vue SPA)
ProximityWebUi    -> ProximityApiRouter: GET /api/proximity/users/current
ProximityApiRouter -> ProximityUserApiProxy: route to user controller
ProximityUserApiProxy -> ProximityWebUi: { user: "X-Remote-User header value" }
ProximityWebUi    -> ProximityApiRouter: GET /api/proximity/users
ProximityApiRouter -> ProximityUserApiProxy: route to user controller
ProximityUserApiProxy -> continuumProximityHotzoneApi: GET /v1/proximity/location/hotzone/users?client_id=ec-team
continuumProximityHotzoneApi --> ProximityUserApiProxy: { users: [...] }
ProximityUserApiProxy --> ProximityWebUi: 200 { users: [...] }
ProximityWebUi    -> VueRouter: router.map(authenticatedRoutes OR permissionOnlyRoutes)
VueRouter         -> Administrator: Renders Home or Permission screen
```

## Related

- Architecture dynamic view: `dynamic-proximity-create-hotzone-flow`
- Related flows: [Create Hotzone](create-hotzone.md), [Browse and Search Hotzones](browse-hotzones.md)
