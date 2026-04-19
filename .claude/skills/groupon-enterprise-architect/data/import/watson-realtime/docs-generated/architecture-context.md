---
service: "watson-realtime"
title: Architecture Context
generated: "2026-03-03T00:00:00Z"
type: architecture-context
architecture_refs:
  system: "continuumSystem"
  containers: [continuumAnalyticsKsService, continuumCookiesService, continuumDealviewService, continuumRealtimeKvService, continuumRvdService, continuumUserIdentitiesService, continuumKsTableTrimmerService]
---

# Architecture Context

## System Context

watson-realtime is a set of stream-processing containers within the `continuumSystem` (Continuum Platform). It sits between Groupon's Janus event infrastructure (sourced via Conveyor Cloud from the Kafka cluster `kafkaCluster_9f3c`) and the watson-api read layer. Each Kafka Streams worker pulls events, transforms them using Janus schema mappings from `janusMetadataService_4d1e`, and writes derived data to one of three persistence stores: Redis (`raasRedis_3a1f`), Cassandra/Keyspaces (`cassandraKeyspaces_5c9a`), or PostgreSQL (`postgresCookiesDb_2f7a`). watson-api consumes the resulting store contents to power search ranking and analytics.

## Containers

| Container | ID | Type | Technology | Version | Description |
|-----------|----|------|-----------|---------|-------------|
| Analytics KS Stream Processor | `continuumAnalyticsKsService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Computes analytics counters and writes to Cassandra Keyspaces |
| Cookies Stream Processor | `continuumCookiesService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Writes consumer bcookie mappings to PostgreSQL |
| Dealview Stream Processor | `continuumDealviewService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Writes deal view counts to Redis |
| Realtime KV Stream Processor | `continuumRealtimeKvService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Writes realtime user/deal KV data to Redis |
| RVD Stream Processor | `continuumRvdService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Writes realtime view data aggregations to Redis |
| User Identities Stream Processor | `continuumUserIdentitiesService` | Kafka Streams worker | Java, Kafka Streams | 2.7.0 | Writes user identity data to Redis |
| Keyspaces Table Trimmer | `continuumKsTableTrimmerService` | Scheduled job | Java | 11 | Trims aged rows from Cassandra/Keyspaces tables |

## Components by Container

### Analytics KS Stream Processor (`continuumAnalyticsKsService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Analytics stream processor | Consumes Janus impression/tier2 events, aggregates counters, and writes to Cassandra/Keyspaces | Kafka Streams, Cassandra driver, AWS SigV4 |

### Cookies Stream Processor (`continuumCookiesService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Cookies stream processor | Consumes Janus events, resolves bcookie-to-identity mappings via Janus Metadata Service, and writes to PostgreSQL | Kafka Streams, JDBI3, PostgreSQL |

### Dealview Stream Processor (`continuumDealviewService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Dealview stream processor | Consumes Janus events, resolves schemas via Janus Metadata Service, and writes deal view counters to Redis | Kafka Streams, Jedis |

### Realtime KV Stream Processor (`continuumRealtimeKvService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Realtime KV stream processor | Consumes Janus events, resolves schemas via Janus Metadata Service, and writes user/deal KV pairs to Redis | Kafka Streams, Jedis |

### RVD Stream Processor (`continuumRvdService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| RVD stream processor | Consumes Janus events, resolves schemas via Janus Metadata Service, and writes realtime view data to Redis | Kafka Streams, Jedis |

### User Identities Stream Processor (`continuumUserIdentitiesService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| User identities stream processor | Consumes Janus events, resolves schemas via Janus Metadata Service, enriches records, and writes user identity data to Redis | Kafka Streams, Jedis |

### Keyspaces Table Trimmer (`continuumKsTableTrimmerService`)

| Component | Responsibility | Technology |
|-----------|---------------|-----------|
| Table trimmer job | Connects to Cassandra/Keyspaces on a schedule and deletes rows that exceed retention thresholds | Java, Cassandra driver, AWS SigV4 |

## Key Relationships

| From | To | Description | Protocol |
|------|----|-------------|----------|
| `continuumAnalyticsKsService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumAnalyticsKsService` | `cassandraKeyspaces_5c9a` | Writes analytics counters | Cassandra |
| `continuumCookiesService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumCookiesService` | `postgresCookiesDb_2f7a` | Writes consumer bcookie mappings | PostgreSQL |
| `continuumCookiesService` | `janusMetadataService_4d1e` | Fetches event schemas and mappings | HTTP |
| `continuumDealviewService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumDealviewService` | `raasRedis_3a1f` | Writes deal view counters | Redis |
| `continuumDealviewService` | `janusMetadataService_4d1e` | Fetches event schemas and mappings | HTTP |
| `continuumRealtimeKvService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumRealtimeKvService` | `raasRedis_3a1f` | Writes realtime KV data | Redis |
| `continuumRealtimeKvService` | `janusMetadataService_4d1e` | Fetches event schemas and mappings | HTTP |
| `continuumRvdService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumRvdService` | `raasRedis_3a1f` | Writes realtime view data | Redis |
| `continuumRvdService` | `janusMetadataService_4d1e` | Fetches event schemas and mappings | HTTP |
| `continuumUserIdentitiesService` | `kafkaCluster_9f3c` | Consumes Janus events | Kafka |
| `continuumUserIdentitiesService` | `raasRedis_3a1f` | Writes user identity data | Redis |
| `continuumUserIdentitiesService` | `janusMetadataService_4d1e` | Fetches event schemas and mappings | HTTP |
| `continuumKsTableTrimmerService` | `cassandraKeyspaces_5c9a` | Trims tables | Cassandra |
| `conveyorCloud_7b2c` | `kafkaCluster_9f3c` | Publishes curated events | Kafka |

## Architecture Diagram References

- Component: `components-analytics-ks-components`
- Component: `components-cookies-components`
- Component: `components-dealview-components`
- Component: `components-ks-table-trimmer-components`
- Component: `components-realtime-kv-components`
- Component: `components-rvd-components`
- Component: `components-user-identities-components`
