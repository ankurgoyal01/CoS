---
service: "travel-search"
title: Runbook
generated: "2026-03-02T00:00:00Z"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `/travel-search/health` | http | > No evidence found | > No evidence found |
| MySQL connectivity (`continuumTravelSearchDb`) | tcp | Platform-managed | — |
| Redis connectivity (`continuumTravelSearchRedis`) | tcp | Platform-managed | — |

> Health endpoint path and interval details are not specified in the architecture model. Verify the Jetty WAR health check endpoint in the service source repository.

## Monitoring

### Metrics

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| `travel_search_request_count` | counter | Total search API requests received | — |
| `travel_search_request_latency` | histogram | End-to-end latency of search requests | > No evidence found |
| `hotel_detail_cache_hit_rate` | gauge | Redis cache hit ratio for hotel detail reads | < 50% — warning |
| `ean_price_consumer_lag` | gauge | Kafka consumer lag for EAN price update topic | > No evidence found |
| `mbus_publish_error_rate` | counter | Rate of MDS hotel update publish failures | > 0 — warning |
| `db_connection_pool_active` | gauge | Active MySQL connection pool connections | > No evidence found |

> Metric names are inferred from component responsibilities. Verify exact metric names and alert thresholds in the service's metrics instrumentation and monitoring dashboards.

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| Getaways Search Service | > No evidence found | > No evidence found |

> Dashboard links are managed externally. Contact the Getaways Engineering team for access to operational dashboards.

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| High search error rate | Error responses exceed threshold | critical | Check downstream dependency health; review logs for root cause |
| Redis cache unavailable | `continuumTravelSearchRedis` unreachable | critical | Service degrades to MySQL fallback; contact platform infra team |
| MySQL unavailable | `continuumTravelSearchDb` unreachable | critical | Service cannot serve requests; escalate to platform DBA team |
| Kafka consumer lag high | EAN price update lag exceeds threshold | warning | Check Kafka broker health and consumer thread count |
| MBus publish failures | MDS update publish error rate > 0 | warning | Check MBus broker connectivity; review `travelSearch_mbusPublisher` logs |
| Background job failure | OTA sync or Google Hotels upload job fails | warning | Review scheduled job logs; re-trigger manually if needed |

## Common Operations

### Restart Service

1. Identify the Kubernetes deployment for `travel-search` in the Continuum cluster.
2. Run `kubectl rollout restart deployment/travel-search -n <namespace>`.
3. Monitor pod readiness: `kubectl get pods -n <namespace> -l app=travel-search`.
4. Verify health check endpoint returns 200 after restart.

### Scale Up / Down

1. Adjust the HPA min/max replica counts in the Kubernetes manifest, or use:
   `kubectl scale deployment/travel-search --replicas=<N> -n <namespace>`.
2. Monitor pod count and resource utilisation after scaling.

### Database Operations

- **Schema migrations**: Run Ebean migration scripts against `continuumTravelSearchDb`. Coordinate with the Getaways Engineering team for production migrations.
- **Cache invalidation**: Connect to `continuumTravelSearchRedis` and issue `FLUSHDB` (targeted key deletion preferred) to force cache refresh. Exercise caution in production — this increases MySQL and external service load.
- **Price data backfill**: Re-process Kafka topic from an earlier offset using the `travelSearch_kafkaConsumer` reset procedure. Coordinate with the messaging platform team.

## Troubleshooting

### Search results empty or degraded

- **Symptoms**: Search API returns empty result sets or partial results; no error response code
- **Cause**: Downstream service unavailable — likely `externalGeoService_4c0d`, `externalInventoryService_5d2a`, or `continuumDealCatalogService`
- **Resolution**: Check health of each downstream dependency; review `travelSearch_externalClients` HTTP client logs for timeout or connection errors; verify dependency URLs in environment configuration

### Hotel detail missing content

- **Symptoms**: Hotel detail endpoint returns hotel record but content fields (description, images, amenities) are absent or stale
- **Cause**: `externalContentService_3b91` unavailable or returning errors; Redis cache may hold stale records
- **Resolution**: Verify content service health; if cache is stale, invalidate Redis keys for affected hotels; review `hotelDetailsManager` logs

### Stale pricing data

- **Symptoms**: Hotel rates displayed to users are outdated; EAN availability check returns different prices
- **Cause**: Kafka consumer lag on `externalKafkaCluster_f6a7`; `travelSearch_kafkaConsumer` has fallen behind
- **Resolution**: Check Kafka consumer group lag; scale consumer threads if needed; verify broker connectivity; check `ENABLE_EAN_PRICE_UPDATES` flag is enabled

### MDS updates not publishing

- **Symptoms**: Downstream MDS consumers report no hotel update events; MBus queue appears empty
- **Cause**: `travelSearch_mbusPublisher` failing to connect to `externalMessageBus_e5f6`; JMS credentials may be expired
- **Resolution**: Check MBus broker connectivity; verify `MBUS_BROKER_URL` and `MBUS_CREDENTIALS` configuration; review `travelSearch_mbusPublisher` logs for JMS exceptions

### Background OTA upload failures

- **Symptoms**: Google Hotels feed not updated; `travelSearch_backgroundJobs` logs show errors
- **Cause**: `externalGoogleHotels_b2c3` endpoint unreachable; feed format error; credentials expired
- **Resolution**: Check `GOOGLE_HOTELS_FEED_URL` configuration; verify credentials; inspect job logs; re-trigger manually via MDS control API if needed

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service down — no search results returned | Immediate | Getaways Engineering on-call |
| P2 | Degraded — partial results or elevated latency | 30 min | Getaways Engineering on-call |
| P3 | Minor impact — stale data, non-critical feature unavailable | Next business day | Getaways Engineering team |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| `continuumTravelSearchDb` (MySQL) | TCP connectivity check on DB port | No fallback — service cannot persist data |
| `continuumTravelSearchRedis` (Redis) | TCP connectivity check on Redis port | Falls back to MySQL reads via `travelSearch_persistenceLayer` |
| `externalContentService_3b91` | HTTP GET health endpoint | Hotel detail returned without content fields |
| `externalGeoService_4c0d` | HTTP GET health endpoint | Destination-based search results degraded or empty |
| `externalInventoryService_5d2a` | HTTP GET health endpoint | Availability data unavailable for hotel detail |
| `externalExpediaEanApi_a1b2` | HTTP GET health endpoint | Rates fall back to cached/persisted values |
| `continuumDealCatalogService` | HTTP GET health endpoint | Deal results excluded from search response |
| `continuumForexService` | HTTP GET health endpoint | Multi-currency pricing unavailable; single-currency fallback |
| `externalKafkaCluster_f6a7` (Kafka) | Kafka consumer group health | EAN price updates stale until connectivity restored |
| `externalMessageBus_e5f6` (MBus) | JMS broker connectivity | MDS update publications queued locally; risk of message loss |

> Operational procedures not fully discoverable from the architecture model alone. Service owner should supplement this runbook with environment-specific details, dashboard links, and PagerDuty escalation paths.
