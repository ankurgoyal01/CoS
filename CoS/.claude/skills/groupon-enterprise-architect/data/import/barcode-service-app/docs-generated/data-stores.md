---
service: "barcode-service-app"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. As documented in the service README: "This application does not store data." and "This application does not cache information." All barcode rendering is performed entirely in-memory per request using the ZXing and Barbecue libraries. No database connections, cache clients, or persistent storage clients are present in the codebase.

## Stores

> Not applicable — no data stores owned or operated by this service.

## Caches

> Not applicable — no caching layer is used. Each request is rendered on-demand.

## Data Flows

> Not applicable — the service receives a payload via HTTP request and returns a rendered image in the HTTP response. No data is persisted or forwarded to any downstream store.
