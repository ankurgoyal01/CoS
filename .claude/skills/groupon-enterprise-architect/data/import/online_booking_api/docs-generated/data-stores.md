---
service: "online_booking_api"
title: Data Stores
generated: "2026-03-03"
type: data-stores
stores: []
---

# Data Stores

## Overview

The Online Booking API is a stateless orchestration service and does not own any data stores. It does not include ActiveRecord (the `active_record/railtie` is explicitly commented out in `config/application.rb`), has no database configuration files, and performs no direct database operations. All data persistence is delegated to downstream services.

## Stores

> This service is stateless and does not own any data stores.

## Caches

> No evidence found in codebase. No in-process or external caching layer (Redis, Memcached) is configured.

## Data Flows

All data originates from and is persisted to downstream services:

- **Reservation and appointment data**: owned and stored by `continuumAppointmentsEngine`
- **Availability segment data**: computed and owned by `continuumAvailabilityEngine`
- **Calendar and schedule data**: owned by `continuumCalendarService`
- **Deal and option metadata**: owned by `continuumDealCatalogService`
- **Place metadata**: owned by `continuumM3PlacesService`
- **Notification settings**: owned by `continuumOnlineBookingNotifications`
- **User profile data**: owned by `continuumUsersService`
- **Voucher inventory data**: owned by `continuumVoucherInventoryService`

The Online Booking API aggregates responses from these services in-memory per request and returns the merged result to the caller. No data is cached between requests.
