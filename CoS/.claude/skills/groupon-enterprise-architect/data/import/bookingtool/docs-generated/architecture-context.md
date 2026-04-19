---
service: "bookingtool"
title: Architecture Context
generated: "2026-03-02T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumBookingToolApp, continuumBookingToolMySql]
---

# Architecture Context

## System Context

The Booking Tool is a container within the `continuumSystem` (Continuum Platform) software system. It is a legacy PHP web application that sits at the intersection of merchant operations and customer-facing reservation flows. Merchants interact with it directly to configure availability; customers interact with it via booking UIs to reserve time slots against purchased vouchers. The service depends on MySQL for persistence, Redis for session and cache state, and a range of internal Continuum services and external SaaS integrations for data and communication.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Booking Tool Application | `continuumBookingToolApp` | WebApp | PHP (Apache + PHP-FPM) | PHP 5.6 | Legacy booking operations and reservations management web application |
| Booking Tool MySQL | `continuumBookingToolMySql` | Database | MySQL | 5.6 | Primary relational datastore for booking tool entities |
| Redis Cache | — | Cache | Redis | — | Session store and application cache (referenced in inventory; no dedicated DSL container ID) |

## Components by Container

### Booking Tool Application (`continuumBookingToolApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| HTTP Controllers (`btControllers`) | Route and handle admin and booking UI requests; map `?api_screen=` query parameters to handlers | PHP Controllers |
| Domain Services (`btDomainServices`) | Core booking, availability, and reservation business logic; orchestrates all use cases | PHP Services |
| Repositories (`btRepositories`) | Persistence layer for booking domain entities; executes SQL via Doctrine DBAL | Doctrine DBAL Repositories |
| Integration Clients (`btIntegrationClients`) | Outbound clients for third-party and internal platform integrations; wraps Guzzle HTTP calls | Guzzle-based Clients |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumBookingToolApp` | `continuumBookingToolMySql` | Reads and writes reservation and deal data | SQL/TCP |
| `continuumBookingToolApp` | `salesForce` | Synchronizes merchant and deal metadata | HTTPS/REST |
| `btControllers` | `btDomainServices` | Invokes booking and reservation use cases | direct |
| `btDomainServices` | `btRepositories` | Reads and persists booking data | direct |
| `btDomainServices` | `btIntegrationClients` | Calls upstream and third-party services | direct |

## Architecture Diagram References

- System context: `contexts-bookingtool`
- Container: `containers-bookingtool`
- Component: `bookingToolAppComponents`
