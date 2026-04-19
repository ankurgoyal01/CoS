---
service: "gpapi"
title: Events
generated: "2026-03-03T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. gpapi operates exclusively over synchronous HTTP. All integrations — both upstream (Vendor Portal UI) and downstream (Goods Stores Service, Goods Inventory Service, Goods Product Catalog, Goods Promotion Manager, Deal Catalog, DMAPI, Pricing Service, Taxonomy Service, Users Service, Vendor Compliance Service, Commerce Interface, Geo Details Service, Accounting Service) — use REST/HTTPS request-response patterns.

The sole inbound external call that resembles an event is the NetSuite webhook (`POST /webhooks/netsuite`), which is handled synchronously as a standard HTTP endpoint rather than through a message broker.

## Published Events

> No evidence found in codebase. gpapi does not publish to any message bus, queue, or topic.

## Consumed Events

> No evidence found in codebase. gpapi does not consume from any message bus, queue, or topic.

## Dead Letter Queues

> Not applicable. No async messaging infrastructure is used by this service.
