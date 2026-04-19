---
service: "tableau-terraform"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. `tableau-terraform` is an Infrastructure-as-Code repository whose execution model is operator-triggered Terraform plan/apply commands. There is no message bus, event stream, or pub/sub integration. Operational alerting is performed by on-VM cron scripts that send email notifications directly via SMTP rather than through any event system.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.
