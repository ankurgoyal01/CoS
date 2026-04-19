---
service: "file-sharing-service"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events via a message broker. All interactions are synchronous HTTP request/response. The only time-based processing is handled internally by a cron scheduler (`cronj`) that runs a scheduled task at midnight daily to clear expired file content blobs — this does not involve any external messaging system.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> No evidence found in codebase.

> This service does not publish or consume async events. All processing is synchronous (REST API) or internally scheduled (cronj).
