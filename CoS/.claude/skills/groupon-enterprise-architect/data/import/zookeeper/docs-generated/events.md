---
service: "zookeeper"
title: Events
generated: "2026-03-03"
type: events
messaging_systems: []
---

# Events

## Overview

ZooKeeper does not use an external asynchronous messaging system such as Kafka or RabbitMQ. Instead, it implements its own internal watch-notification mechanism: clients register watches on znodes and ZooKeeper delivers one-time event notifications to those clients when the watched znode changes. These notifications are delivered over the existing TCP client session and are not routed through any external message bus.

## Published Events

> No evidence found in codebase of ZooKeeper publishing to any external topic, queue, or message bus.

ZooKeeper delivers the following internal watch event types over the client protocol session:

| Event Type | Trigger | Delivered To |
|------------|---------|-------------|
| `NodeCreated` | A watched znode path is created | Clients with an `exists` watch on that path |
| `NodeDeleted` | A watched znode is deleted | Clients with a data or child watch on that path |
| `NodeDataChanged` | A watched znode's data is updated via `setData` | Clients with a data watch on that path |
| `NodeChildrenChanged` | A child is created or deleted under a watched znode | Clients with a children watch on that path |
| `None` / `SessionExpired` | Client session expires | The affected client session |

> These are internal protocol events, not external messaging. They are delivered once per registration (non-persistent) unless the client re-registers the watch.

## Consumed Events

> No evidence found in codebase. ZooKeeper does not consume events from any external messaging system.

## Dead Letter Queues

> Not applicable. ZooKeeper does not use external message queues and therefore has no dead letter queue configuration.
