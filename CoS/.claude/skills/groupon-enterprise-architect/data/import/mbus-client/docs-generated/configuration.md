---
service: "mbus-client"
title: Configuration
generated: "2026-03-03"
type: configuration
config_sources: ["config-objects", "properties-files"]
---

# Configuration

## Overview

The MBus Java Client Library is configured programmatically via two Java configuration objects: `ProducerConfig` (for publishing) and `ConsumerConfig` (for consuming). There are no environment variables, Consul entries, or external config files used by the library itself — all settings are passed in by the embedding application at instantiation time. Example properties files are documented in the README for quick-start use with the example runner classes.

## ProducerConfig Parameters

| Parameter | Method | Required | Default | Purpose |
|-----------|--------|----------|---------|---------|
| `broker` | `setBroker(HostParams)` | yes | none | Broker host and port to publish to (e.g., `mbus-vip.snc1`, `61613`) |
| `destinationName` | `setDestinationName(String)` | yes | none | Full destination name, e.g., `jms.topic.myTopic` or `jms.queue.myQueue` |
| `destinationType` | `setDestinationType(DestinationType)` | yes | `QUEUE` | Must match destination name prefix: `TOPIC` or `QUEUE` |
| `userName` | `setUserName(String)` | no | `rocketman` | STOMP auth username |
| `password` | `setPassword(String)` | no | `rocketman` | STOMP auth password |
| `publishMaxRetryAttempts` | `setPublishMaxRetryAttempts(int)` | no | `3` | Number of retries before `sendSafe` fails |
| `receiptTimeoutMillis` | `setReceiptTimeoutMillis(long)` | no | `5000` (from `StompConnection.RECEIPT_TIMEOUT`) | Per-attempt timeout in ms waiting for STOMP RECEIPT in `sendSafe` |
| `connectionLifetime` | `setConnectionLifetime(long)` | no | `300000` (5 min) | Interval in ms after which producer reconnects to rebalance cluster load |
| `keepAlivePeriodSeconds` | `setKeepAlivePeriodSeconds(long)` | no | 60 (from `StompConnection.KEEP_ALIVE_PERIOD`) | Keepalive heartbeat period in seconds; 0 or negative disables |
| `verboseLog` | `setVerboseLog(boolean)` | no | `false` | If `true`, logs publish count and latency metrics at INFO level |
| `metricAppName` | `setMetricAppName(String)` | no | `mbus` | App name under which metricslib reports producer metrics |

## ConsumerConfig Parameters

| Parameter | Method | Required | Default | Purpose |
|-----------|--------|----------|---------|---------|
| `hostParams` | `setHostParams(Set<HostParams>)` | yes | none | Set of VIP or broker host:port pairs to connect to |
| `destinationName` | `setDestinationName(String)` | yes (or `destinationList`) | none | Single destination to subscribe, e.g., `jms.topic.myTopic` |
| `destinationList` | `setDestinationList(List<String>)` | yes (or `destinationName`) | none | Multiple destinations to subscribe in one consumer |
| `destinationType` | `setDestinationType(DestinationType)` | yes | `QUEUE` | `TOPIC` or `QUEUE` — must match destination name prefix |
| `ackType` | `setAckType(ConsumerAckType)` | no | `CLIENT_ACK` | Ack mode: `CLIENT_ACK`, `AUTO_CLIENT_ACK`, or `CLIENT_INDIVIDUAL` |
| `subscriptionId` | `setSubscriptionId(String)` | yes (for topics) | none | Subscription identifier; same ID across consumers = load-balanced; different IDs = independent copies |
| `durable` | `setDurable(boolean)` | no | `true` | If `true`, broker retains messages for this subscription when consumer disconnects |
| `autoUnsubscribe` | `setAutoUnsubscribe(boolean)` | no | `false` | If `true`, sends STOMP UNSUBSCRIBE on controlled `stop()` |
| `useDynamicServerList` | `setUseDynamicServerList(boolean)` | no | `true` | If `true`, fetches active broker list from VIP HTTP endpoint; set `false` only for local testing |
| `dynamicServerListFetchURL` | `setDynamicServerListFetchURL(String)` | no | Auto-derived from `hostParams` | Override URL for fetching active broker host list |
| `connectionLifetime` | `setConnectionLifetime(long)` | no | `300000` (5 min) | Interval in ms after which consumer refreshes the broker host list |
| `threadPoolSize` | `setThreadPoolSize(int)` | no | `4` | Size of internal thread pool managing broker fetcher threads |
| `consumerCreditsInBytes` | `setConsumerCreditsInBytes(int)` | no | `-1` (server default) | Message buffer limit per broker in bytes; set to `1` for slow consumers (>5 sec/message) |
| `messageTTL` | `setMessageTTL(long)` | no | `-1` (disabled) | Expected processing time in ms; used to calculate broker-side TTL |
| `keepAlivePeriodSeconds` | `setKeepAlivePeriodSeconds(long)` | no | 60 (from `StompConnection.KEEP_ALIVE_PERIOD`) | Keepalive heartbeat period in seconds; 0 or negative disables |
| `messageSelector` | `setMessageSelector(String)` | no | none | STOMP message selector expression for server-side message filtering |
| `receiveSleepInterval` | `setReceiveSleepInterval(long)` | no | `1` ms | Interval consumer waits when polling internal prefetch cache |
| `userName` | `setUserName(String)` | no | `rocketman` | STOMP auth username |
| `password` | `setPassword(String)` | no | `rocketman` | STOMP auth password |

## Feature Flags

| Flag | Purpose | Default | Scope |
|------|---------|---------|-------|
| `useDynamicServerList` | Enables cluster-mode dynamic broker discovery from VIP HTTP endpoint | `true` | per-consumer instance |
| `durable` | Controls whether broker retains messages for this subscription when offline | `true` | per-consumer instance |
| `autoUnsubscribe` | Sends UNSUBSCRIBE on controlled consumer stop | `false` | per-consumer instance |
| `verboseLog` | Logs publish count and latency at INFO level | `false` | per-producer instance |

## Config Files

| File | Format | Purpose |
|------|--------|---------|
| `producer_example.properties` | Properties | Quick-start properties file for `SimpleTopicProducer` example (`server`, `port`, `dest_type`, `dest_name`, `msg_count`, `msg_size`) |
| `consumer_example.properties` | Properties | Quick-start properties file for `SimpleTopicConsumer` example (`server`, `port`, `dest_type`, `dest_name`, `msg_count`, `msg_size`, `subscription_id`, `durable`, `rcv_timeout`, `use_dynamic_servers`) |

## Secrets

> IMPORTANT: Never document actual secret values. Only variable names and purposes.

| Secret Reference | Purpose | Store |
|-----------------|---------|-------|
| STOMP `userName` / `password` | Credentials for authenticating to MBus broker destinations; each destination may be access-controlled | Set by application code; sourced from application's own secret management |

## Per-Environment Overrides

| Setting | UAT | Staging | Production |
|---------|-----|---------|-----------|
| Broker VIP host | `mbus-uat-vip.snc1` (port 8081 HTTP / 61613 STOMP) | `mbus-staging-vip.snc1` | `mbus-vip.snc1` (snc1/sac1/dub1) |
| `durable` | `false` (required) | `false` (required) | `true` (recommended) |
| `useDynamicServerList` | `true` | `true` | `true` |

> When connecting to staging or UAT, `durable` must be set to `false` because these environments do not persist subscription state between deployments.
