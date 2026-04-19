---
service: "ios-consumer"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: ["continuumIosConsumerApp"]
---

# Architecture Context

## System Context

The iOS Consumer App (`continuumIosConsumerApp`) is a native iOS container within the `continuumSystem` (Continuum Platform). It is the primary mobile client for iPhone and iPad consumers. The app communicates with Groupon backend services through the `api-lazlo-sox` mobile API gateway, which aggregates deal, user, order, and geo data. Push notifications are delivered to the app via APNS, with the server-side delivery pipeline managed by `gaurun`.

The app also occupies a dual role: it serves as the standalone legacy Groupon iOS app distributed on the App Store, and it is embedded as the `groupon-legacy` git submodule within `next-pwa-app/apps/mobile-expo`, allowing the MBNXT mobile shell to launch either the legacy native app or the new MBNXT React Native experience depending on bucketing state.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| iOS Consumer App | `continuumIosConsumerApp` | MobileApp | Swift | Not specified | Native iOS application for Groupon consumers |

## Components by Container

### iOS Consumer App (`continuumIosConsumerApp`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| App Shell (`iosConsumer_appShell`) | Application lifecycle, navigation, and shared UI composition | Swift / UIKit |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumIosConsumerApp` | `api-lazlo-sox` | Requests deal, user, order, and geo data | HTTPS / REST |
| `continuumIosConsumerApp` | APNS | Registers device token; receives push notifications | APNS (Apple Push Notification service) |
| `gaurun` | `continuumIosConsumerApp` | Delivers push notifications via APNS queue (`ios-consumer` Kafka consumer) | Kafka + APNS |
| `next-pwa-app` (mobile-expo) | `continuumIosConsumerApp` | Embeds legacy app as git submodule `groupon-legacy`; reads shared NSUserDefaults and Keychain state | Native iOS bridge |
| `continuumIosConsumerApp` | `continuumSystem` (Continuum services) | Authenticates, browses deals, purchases, and manages orders via Lazlo gateway | HTTPS / REST |

## Architecture Diagram References

- System context: `contexts-continuum`
- Container: `containers-continuum`
- Component: `components-continuum-ios-consumer-app`
