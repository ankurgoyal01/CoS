---
service: "deal_wizard"
title: Events
generated: "2026-03-02T00:00:00Z"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. Deal Wizard uses synchronous Salesforce integration exclusively — all deal data operations (reads and writes to Salesforce Opportunities and Accounts) are performed via direct REST/APEX API calls at request time. Background processing for deferred Salesforce operations is handled via `delayed_job` using a MySQL-backed queue rather than an external message bus.

## Published Events

> Not applicable

## Consumed Events

> Not applicable

## Dead Letter Queues

> Not applicable
