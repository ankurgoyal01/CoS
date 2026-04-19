---
service: "dynamic-routing"
title: Runbook
generated: "2026-03-03"
type: runbook
---

# Runbook

## Health Checks

| Endpoint / Mechanism | Type | Interval | Timeout |
|---------------------|------|----------|---------|
| `GET /status` | HTTP | Not specified in code | Not specified in code |

The `/status` endpoint returns JSON with `status: "up"`, the application version, and the mbus-client version. The service portal status endpoint is **disabled** (`.service.yml`: `status_endpoint.disabled: true`), so health is monitored through external checks.

Note: On startup, `DynamicRoutesManager` logs route loading progress. The `isInitializing()` flag is true until all routes have been loaded; `getNumberOfRoutesFailedToLoad()` reflects any routes that failed to load from MongoDB or failed to start their Camel context.

## Monitoring

### Metrics

> No in-process metrics instrumentation (e.g., Micrometer, Dropwizard Metrics) was found in the codebase. Monitoring relies on external infrastructure-level metrics.

| Metric | Type | Description | Alert Threshold |
|--------|------|-------------|----------------|
| JVM process health | External (CheckMK) | Host-level check for `mbus.*-camel.*` hosts | Process down |
| Route active count | Jolokia / Wavefront | Number of active Camel contexts (routes in STARTED state) | Deviation from expected count |

### Dashboards

| Dashboard | Tool | Link |
|-----------|------|------|
| MBus Camel | Wavefront | `https://groupon.wavefront.com/dashboard/mbus-camel` |
| CheckMK Host View | CheckMK | `https://checkmk-lvl3.groupondev.com/ber1_prod/check_mk/index.py?start_url=%2Fber1_prod%2Fcheck_mk%2Fview.py%3Ffilled_in%3Dfilter%26host_regex%3Dmbus.%252A-camel..%252A%26view_name%3Dsearchhost` |

### Alerts

| Alert | Condition | Severity | Runbook Action |
|-------|-----------|----------|---------------|
| Service unreachable | `GET /status` fails or host down | P1 — critical | See PagerDuty service `PGG3KB5`; follow failover runbook |
| Routes failed to load | `numberOfRoutesFailedToLoad > 0` at startup | P2 — warning | Check MongoDB connectivity; review logs for `"Could not build Camel context"` or `"Could not read N routes from the DB"` |
| Route stopped unexpectedly | Camel context for a route enters STOPPED/FAILED state | P2 — warning | Use admin UI or restart service; check broker connectivity |

- **PagerDuty**: `https://groupon.pagerduty.com/services/PGG3KB5`
- **Pager email**: `mbus@groupon.pagerduty.com`
- **Slack channel**: `CF7HYM0KS`

## Common Operations

### Restart Service

1. Connect to the target host (e.g., `mbus-camel1.snc1` or `mbus-camel1.dub1`)
2. Stop Tomcat gracefully — `DynamicRoutesManager.destroy()` is registered as a Spring `DisposableBean` and will stop all Camel contexts cleanly on shutdown
3. Start Tomcat; routes are reloaded from MongoDB on startup
4. Monitor startup logs for `"All N routes are successfully loaded"` or any `"Could not build/start Camel context"` warnings
5. Verify active routes in the admin UI or via `GET /status`

Refer to: [Confluence — How-to failover dynamic routing in roller based environment](https://confluence.groupondev.com/display/GMB/How-to+failover+dynamic+routing+in+roller+based+environment)

### Failover (US)
Refer to: [Confluence — How-to failover dynamic routing in roller based environment](https://confluence.groupondev.com/display/GMB/How-to+failover+dynamic+routing+in+roller+based+environment)

### Failover (INTL / LUP1)
Refer to: [Confluence — How to failover dynamic routes in intl. LUP1](https://confluence.groupondev.com/display/GMB/How+to+...+failover+dynamic+routes+in+intl.+LUP1)

### Scale Up / Down
> Operational procedures to be defined by service owner. Horizontal scaling is performed via Ansible. Each instance manages its own Camel contexts. There is no shared in-process state between instances beyond MongoDB.

### Add a New Broker

1. Log in to the admin UI at the target environment URL
2. Use the admin UI broker registration form, or issue a `PUT /brokers/{brokerId}` REST call with the broker JSON body
3. Verify the broker appears in `GET /brokers` and that its Jolokia endpoint is reachable (the admin UI will attempt to discover destinations)
4. Note: broker registration is create-only; to update a broker, it must be removed and re-added

### Add a New Dynamic Route

1. Log in to the admin UI
2. Select source broker, source endpoint (queue or topic), destination broker, destination endpoint
3. Optionally configure filter chain and transformer
4. Submit — `DynamicRoutesManager.addRoute()` creates a new `SpringCamelContext`, starts it, and persists the route to MongoDB
5. Verify route status in the admin UI (`RouteInfo.status = Started`)

### Start / Stop a Route

1. In the admin UI, select the route and click Start or Stop
2. `DynamicRoutesManager.startRoute()` / `stopRoute()` updates the Camel context and persists the new `running` flag to MongoDB
3. The state persists across restarts

### Database Operations

- **Backup**: Standard MongoDB backup via Ansible-managed procedures
- **Manual route cleanup**: Removing a route via the admin UI calls `DynamicRoutesManager.removeRoute()`, which stops the Camel context and deletes the document from the `routes` collection
- **Durable subscription cleanup**: When a durable topic source is removed, `removeRoute()` also calls `dropDurableSubscription()` via JMS management queue (`hornetq.management`) to remove the subscription from the broker

## Troubleshooting

### Routes Not Loading on Startup
- **Symptoms**: Log warning `"Could not read N routes from the DB"` or `"Could not build/start Camel context for the route '...' due to '...'"`, fewer routes active than expected
- **Cause**: MongoDB unreachable, malformed route document, or JMS broker unavailable at the time the route's Camel context tried to start
- **Resolution**: Check MongoDB connectivity (`mongodb.hosts` property); inspect logs for specific route name and exception; use the admin UI to manually start routes that loaded but did not auto-start; fix any malformed documents in the `routes` collection

### Broker Connection Failures
- **Symptoms**: Camel route in STOPPED/FAILED state; log entries with `"Could not start Camel context for the route"` or HornetQ reconnect warnings
- **Cause**: Target JMS broker is unreachable or credentials are wrong
- **Resolution**: Verify broker host/port from `brokerInfo.properties`; confirm Jolokia reachable at `http://<host>:<jolokiaPort>/jolokia`; check broker is running; use admin UI to stop and restart the route once broker is available

### Duplicate Messages
- **Symptoms**: Downstream consumers receive duplicate messages
- **Cause**: In-memory idempotent repository is cleared on service restart; messages delivered before shutdown may be re-delivered after restart
- **Resolution**: Design downstream consumers to be idempotent; consider increasing in-memory repository size (currently hardcoded to 500,000 entries in `CamelRouteBuilder`)

### Admin UI Login Failure
- **Symptoms**: 401/403 on the admin UI
- **Cause**: `app.admin.username` / `app.admin.password` in `dynamic-routing-config.properties` are incorrect or the file is missing
- **Resolution**: Verify the properties file is present at the path given by `application.properties.file` JVM system property; confirm the password is a valid `StandardPasswordEncoder`-encoded value

## Incident Response

| Severity | Impact | Response Time | Escalation |
|----------|--------|--------------|------------|
| P1 | Service completely down; all dynamic routes stopped; message delivery halted | Immediate | GMB team via PagerDuty `PGG3KB5` (`mbus@groupon.pagerduty.com`) |
| P2 | Some routes failing or not loading; partial message delivery degradation | 30 min | GMB team via Slack `CF7HYM0KS` |
| P3 | Minor impact; single route issue; admin UI degraded | Next business day | messagebus-team@groupon.com |

## Dependencies Health

| Dependency | Health Check | Fallback |
|------------|-------------|----------|
| MongoDB | `mongodb.hosts` connectivity; `DynamicRouteRepository.findAll()` succeeds on startup | Routes that fail to load from MongoDB are skipped; `numberOfRoutesFailedToLoad` is logged |
| JMS Brokers (HornetQ/Artemis) | Jolokia reachable at `http://<host>:<jolokiaPort>/jolokia`; JMS connection established | Route marked `running=false`; HornetQ client retries connection infinitely in background |
| Jolokia endpoint | HTTP GET to Jolokia URL returns valid JSON | Admin UI destination picker shows empty list; route creation blocked until broker is reachable |
| Backend Services (BES) | HTTP GET to `http://<besHost>/bs/...` returns 200 | 3-attempt retry; throws `BSConnectionException` on exhaustion; transformer fails and message goes to dead-letter log |
