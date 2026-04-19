---
service: "openvpn-config"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

This service does not publish or consume async events. OpenVPN Config Automation operates exclusively as a synchronous CLI toolset — scripts are invoked manually or on a schedule, perform synchronous HTTPS calls to the OpenVPN Cloud Connexa API, and write results to local filesystem JSON files. No message broker, queue, or event bus integration exists in the codebase.

## Published Events

> No evidence found in codebase.

## Consumed Events

> No evidence found in codebase.

## Dead Letter Queues

> Not applicable. No async messaging is used by this service.
