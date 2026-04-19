---
service: "routing_config_production"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

> No evidence found in codebase.

`routing_config_production` does not publish or consume async events. It is a configuration repository whose lifecycle is driven by CI/CD pipeline execution, not by message-bus events. The only signal it produces after a successful deployment is an HTTP `POST` to `localhost:9001/config/routes/reload` on each routing-service node to trigger hot-reload, and an automated comment on the originating GitHub pull request via the GitHub API. Neither of these constitutes an async event in the messaging-bus sense.

## Published Events

> This service does not publish async events.

## Consumed Events

> This service does not consume async events.

## Dead Letter Queues

> Not applicable — no async messaging is used.
