---
service: "replay-tool"
title: Architecture Context
generated: "2026-03-03"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers:
    - continuumMbusReplayToolService
    - continuumReplayToolBosonHosts
---

# Architecture Context

## System Context

The MBus Replay Tool is an operator tool within the Continuum platform, residing alongside the MBus messaging infrastructure. It is accessed exclusively by MBus administrators (the `administrator` person in the C4 model) via HTTPS. The tool depends on three external systems: Boson log hosts for retrieving intercepted messages, the SigInt configuration service (`continuumMbusSigintConfigurationService`) for discovering cluster topology and destination metadata, and the MBus broker cluster (`messageBus`) for publishing replayed messages via STOMP.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| MBus Replay Tool Service | `continuumMbusReplayToolService` | Service | Java 8 / Spring Boot | 1.5.1 | Spring Boot application providing UI and APIs to load intercepted bus messages and replay them to target destinations |
| Boson Log Hosts | `continuumReplayToolBosonHosts` | Infrastructure | SSH / bzip2 | — | Boson hosts queried for intercepted message logs used during replay load |

## Components by Container

### MBus Replay Tool Service (`continuumMbusReplayToolService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Replay API Controllers (`continuumMbusReplayToolService_replayHttpApi`) | Exposes REST endpoints for replay lifecycle — submit request, list requests, get messages, execute, check status — and environment lookups | Spring MVC |
| Replay Service (`continuumMbusReplayToolService_replayOrchestrationService`) | Coordinates message loading from Boson, manages replay request batches in-memory, schedules and tracks execution workers, runs background status polling | Spring Service |
| Environment Service (`continuumMbusReplayToolService_environmentDiscoveryService`) | Resolves broker environments, available destinations, and publish credentials by querying SigInt; caches results for 30 minutes | Spring Service |
| Boson Command Frame Provider (`continuumMbusReplayToolService_bosonCommandFrameProvider`) | Loads and filters intercepted command frames from Boson logs by time range, destination, and message ID | Provider |
| SigInt Data Provider (`continuumMbusReplayToolService_sigintDataProvider`) | Calls the SigInt REST API to retrieve cluster topology, destination metadata, and user credentials | REST Client |
| Message Replay Worker (`continuumMbusReplayToolService_mbusReplayWorker`) | Publishes loaded message frames to the target MBus destination via STOMP in batches of 200; tracks sent/failed counts | Worker |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `administrator` | `continuumMbusReplayToolService` | Loads and executes replay requests | HTTPS |
| `continuumMbusReplayToolService` | `continuumMbusSigintConfigurationService` | Fetches cluster configuration and permissions | HTTP/REST |
| `continuumMbusReplayToolService` | `continuumReplayToolBosonHosts` | Reads intercepted message logs | SSH/grep |
| `continuumMbusReplayToolService` | `messageBus` | Publishes replayed messages to queues/topics | STOMP (port 61613) |
| `continuumMbusReplayToolService_replayHttpApi` | `continuumMbusReplayToolService_replayOrchestrationService` | Submits and queries replay requests | In-process call |
| `continuumMbusReplayToolService_replayHttpApi` | `continuumMbusReplayToolService_environmentDiscoveryService` | Reads environments and destinations | In-process call |
| `continuumMbusReplayToolService_replayOrchestrationService` | `continuumMbusReplayToolService_bosonCommandFrameProvider` | Loads intercepted command frames | In-process call |
| `continuumMbusReplayToolService_replayOrchestrationService` | `continuumMbusReplayToolService_mbusReplayWorker` | Dispatches replay workers | In-process call |
| `continuumMbusReplayToolService_environmentDiscoveryService` | `continuumMbusReplayToolService_sigintDataProvider` | Retrieves cluster configuration | In-process call |

## Architecture Diagram References

- Component: `components-replay-tool`
