---
service: "my_appointments_client"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuum"
  containers: ["continuumMyAppointmentsClient"]
---

# Architecture Context

## System Context

`continuumMyAppointmentsClient` is a front-end application container within the Continuum platform. It sits at the boundary between Groupon's customer-facing web and mobile surfaces and the internal booking engine. Customers arrive via the Groupon.com routing layer or mobile app webviews; the service orchestrates calls to the appointments engine, Groupon V2 API, geodetails service, and layout service to deliver a complete reservation management experience.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| My Appointments Client | `continuumMyAppointmentsClient` | WebApp / Service | Node.js, Express, itier-server | 2.0.0 | Node.js I-Tier application serving mobile reservation pages, JS widget assets, and booking REST endpoints |

## Components by Container

### My Appointments Client (`continuumMyAppointmentsClient`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Request Module Registry (`myAppts_requestModules`) | Wires shared request modules: grouponV2, onlineBooking, geodetailsV2, remoteLayout, auth, localization, feature flags | Node.js module |
| Mobile Web Controller (`myAppts_mobileController`) | Handles `/mobile-reservation` loader, main webview rendering, and order-status orchestration for mobile booking journeys | Express controller |
| REST Resources Controller (`myAppts_restApiController`) | Implements booking REST endpoints for reservations, availability, settings, deals, order status, and user lookups | Express controller |
| JS API Controller (`myAppts_jsApiController`) | Serves widget script metadata: JS/CSS asset URLs, CSRF token, feature-flag payload, login state | Express controller |
| Booking Widget Frontend (`myAppts_bookingFrontend`) | Preact booking widgets and touch flows rendered in mobile and webview contexts; calls REST endpoints for data | Preact, Webpack |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumMyAppointmentsClient` | `continuumAppointmentsEngine` | Creates, updates, and fetches reservations and option availability | HTTPS/JSON |
| `continuumMyAppointmentsClient` | `continuumApiLazloService` | Reads groupons, deals, users, and order status | HTTPS/JSON |
| `continuumMyAppointmentsClient` | `continuumBhuvanService` | Fetches merchant/place geolocation details | HTTPS/JSON |
| `continuumMyAppointmentsClient` | `continuumLayoutService` | Builds remote mobile layout and touch presentation | HTTPS/JSON |
| `continuumMyAppointmentsClient` | `loggingStack` | Emits application logs and operational events | Structured logs |
| `continuumMyAppointmentsClient` | `metricsStack` | Publishes runtime and request metrics | Metrics |
| `myAppts_bookingFrontend` | `myAppts_restApiController` | Calls reservation/availability/settings endpoints | HTTPS/JSON |
| `myAppts_restApiController` | `continuumAppointmentsEngine` | Calls reservation and availability endpoints | HTTPS/JSON |
| `myAppts_mobileController` | `continuumLayoutService` | Requests mobile layout composition | HTTPS/JSON |
| `myAppts_requestModules` | `continuumApiLazloService` | Provides Groupon V2 request clients | HTTPS/JSON |
| `myAppts_requestModules` | `continuumBhuvanService` | Provides geodetails request client | HTTPS/JSON |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuumMyAppointmentsClient`
- Dynamic view: `dynamic-dynamics-continuum-my-appointments-client-reservation`
