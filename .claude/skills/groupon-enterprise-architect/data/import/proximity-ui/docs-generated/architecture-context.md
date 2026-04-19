---
service: "proximity-ui"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumProximityUi"]
---

# Architecture Context

## System Context

Proximity UI sits within the **Continuum Platform** (`continuumSystem`) as an internal-facing administrative tool. An `administrator` user accesses it via a web browser to manage proximity hotzones and campaigns. The application has a single downstream system dependency: `continuumProximityHotzoneApi`, the backend hotzone data service. There are no direct database connections; all data persistence is delegated through the Hotzone API. Access control is enforced by inspecting the `X-Remote-User` header injected by the Nginx reverse proxy layer, and by consulting the user allowlist retrieved from the Hotzone API at startup.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Proximity UI | `continuumProximityUi` | Web Application | Node.js, Express, Vue.js | 1.0.0 | Single deployable Node.js/Express + Vue application that serves the proximity management UI and exposes proxied API routes under `/api/proximity/*`. |

## Components by Container

### Proximity UI (`continuumProximityUi`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| `proximityWebUi` | Vue.js routes and views for create, browse, summary, hotzone detail, campaign management, and permission screens | Vue.js |
| `proximityApiRouter` | Express route registration for `/api/proximity/users`, `/campaigns`, `/categories`, and `/hotzoneDeals` | Express Router |
| `proximityUserApiProxy` | Proxies current-user and user-list requests to the upstream Hotzone API | Node.js `request` |
| `proximityCampaignApiProxy` | Proxies campaign CRUD requests (list, get, create, update, delete) to the upstream Hotzone API | Node.js `request` |
| `proximityCategoryApiProxy` | Proxies category retrieval requests to the upstream Hotzone API | Node.js `request` |
| `proximityHotzoneDealsApiProxy` | Proxies browse, create, get, and delete hotzone deal requests to the upstream Hotzone API | Node.js `request` |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumProximityUi` | Uses browser UI to manage proximity hotzones and campaigns | HTTPS (browser) |
| `proximityWebUi` | `proximityApiRouter` | Calls `/api/proximity/*` routes via VueResource AJAX | HTTP (same-process) |
| `proximityApiRouter` | `proximityUserApiProxy` | Routes user endpoints | Internal |
| `proximityApiRouter` | `proximityCampaignApiProxy` | Routes campaign endpoints | Internal |
| `proximityApiRouter` | `proximityCategoryApiProxy` | Routes category endpoints | Internal |
| `proximityApiRouter` | `proximityHotzoneDealsApiProxy` | Routes hotzone deals endpoints | Internal |
| `continuumProximityUi` | `continuumProximityHotzoneApi` | Reads/writes hotzone, campaign, category, and user data | HTTP (GET/POST/DELETE) |

## Architecture Diagram References

- System context: `contexts-continuumProximityUi`
- Container: `containers-continuumProximityUi`
- Component: `components-continuumProximityUi`
- Dynamic view (create hotzone flow): `dynamic-proximity-create-hotzone-flow`
