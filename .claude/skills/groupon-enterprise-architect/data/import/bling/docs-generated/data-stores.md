---
service: "bling"
title: Data Stores
generated: "2026-03-03T00:00:00Z"
type: data-stores
stores: []
---

# Data Stores

## Overview

This service is stateless and does not own any data stores. bling is a client-side single-page application; all persistent data (invoices, contracts, payments, paysource files, users, batches, system errors) is owned and stored by the Accounting Service backend. bling holds no database, cache, or file storage of its own. Compiled static application assets (JavaScript, CSS, HTML) are served by `blingNginx` from the container filesystem but are not a data store in the operational sense.

## Stores

> Not applicable. bling does not own any data stores. All data is accessed via the Accounting Service and File Sharing Service through the Nginx proxy.

## Caches

> Not applicable. No server-side cache layer exists. Browser-level caching of static assets is managed by `broccoli-asset-rev` asset fingerprinting (cache-busting on each deployment).

## Data Flows

All data displayed in bling flows from the Accounting Service via the Nginx proxy. Write operations (invoice approval, payment creation, paysource file upload) are sent from the browser through the Nginx proxy to the Accounting Service, which owns the persistence layer. Files are routed through the File Sharing Service proxy path (`/file-sharing-service/files`).
