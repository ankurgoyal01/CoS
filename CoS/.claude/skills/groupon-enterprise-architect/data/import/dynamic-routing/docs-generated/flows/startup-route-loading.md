---
service: "dynamic-routing"
title: "Startup Route Loading"
generated: "2026-03-03"
type: flow
flow_name: "startup-route-loading"
flow_type: batch
trigger: "Application startup"
participants:
  - "continuumDynamicRoutingWebApp"
  - "continuumDynamicRoutingMongoDb"
  - "messageBusBrokers_9f42"
architecture_ref: "components-continuumDynamicRoutingWebApp"
---

# Startup Route Loading

## Summary

When the dynamic-routing application starts, it asynchronously loads all route definitions stored in MongoDB and initializes a dedicated Apache Camel context for each one. Routes that were running when the service last shut down are automatically restarted. Routes that fail to build or start are marked as not running in MongoDB so that the bad state is persisted and operators can investigate.

## Trigger

- **Type**: Application lifecycle event
- **Source**: Spring application context initialization — `DynamicRoutesManager` constructor submits the `loadRoutes()` task to a single-thread executor
- **Frequency**: Once per service startup

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Dynamic Routes Manager | Orchestrates loading; iterates pages of routes; builds and starts Camel contexts | `continuumDynamicRoutingWebApp` → `routeManager` |
| Dynamic Route Repository | Provides paginated access to the `routes` MongoDB collection | `continuumDynamicRoutingWebApp` → `routeRepository` |
| Dynamic Routing MongoDB | Stores route definitions; receives updated `running` flag after each route is processed | `continuumDynamicRoutingMongoDb` |
| Camel Route Builder | Constructs the Camel `RouteBuilder` from each `DynamicRoute` definition | `continuumDynamicRoutingWebApp` → `routeBuilder` |
| JMS Brokers (HornetQ/Artemis) | Target of JMS `ConnectionFactory` initialization when the Camel context starts | `messageBusBrokers_9f42` |

## Steps

1. **Submit async load task**: `DynamicRoutesManager` constructor submits `loadRoutes()` to a dedicated single-thread executor, allowing Spring context initialization to complete without blocking.
   - From: `routeManager`
   - To: `routeManager` (async thread)
   - Protocol: Java `Executors.newSingleThreadExecutor()`

2. **Paginate route documents from MongoDB**: `DynamicRouteRepository.findAll(Pageable)` is called page-by-page via a `PageableSpliterator`. Null pages (MongoDB read errors) increment a failure counter and are skipped.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol (Spring Data)

3. **Pre-process each route**: For each loaded `DynamicRoute`, the manager upgrades legacy endpoint definitions — resets JNDI port if applicable, sets the consumer flag on the source endpoint, and migrates missing `Tracing` objects to defaults.
   - From: `routeManager`
   - To: `routeManager` (in-process)
   - Protocol: Direct

4. **Build Camel context**: A new `SpringCamelContext` is created for the route. `CamelRouteBuilder` is instantiated with the route definition, wiring the source endpoint, filter chain, message processors, transformer, and destination endpoint into a Camel route DSL. If `addRoutes()` fails, the route's `running` flag is set to `false`.
   - From: `routeManager`
   - To: `routeBuilder`
   - Protocol: Direct (Apache Camel API)

5. **Start Camel context**: `camelContext.start()` is called. This establishes JMS connections to the source and destination brokers. If the broker is unreachable, the context fails to start and the route is marked `running=false`.
   - From: `routeManager`
   - To: `messageBusBrokers_9f42`
   - Protocol: JMS (HornetQ Netty / Artemis)

6. **Auto-start route**: If the persisted `DynamicRoute.running` is `true`, `camelContext.startRoute(routeName)` is called to begin consuming messages. Failures set `running=false`.
   - From: `routeManager`
   - To: `routeManager` (Camel context)
   - Protocol: Apache Camel API

7. **Persist updated running state**: Each processed route is saved back to MongoDB with its updated `running` flag, reflecting whether the route successfully started.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol (Spring Data)

8. **Log completion**: After all pages are exhausted, logs either `"All N routes are successfully loaded"` (if `numberOfRoutesFailedToLoad == 0`) or a warning listing load failures.
   - From: `routeManager`
   - To: Log (Steno/Logback)
   - Protocol: SLF4J

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MongoDB page read failure | Null page is counted and skipped; iteration continues | Route(s) from that page not loaded; `numberOfRoutesFailedToLoad` incremented; warning logged at end |
| `addRoutes()` throws exception | Caught; `route.setRunning(false)` | Route Camel context exists but has no routes; route persisted as not running |
| `camelContext.start()` throws exception | Caught; `route.setRunning(false)` | Camel context stopped; route persisted as not running; HornetQ client retries in background |
| `startRoute()` throws exception | Caught; `route.setRunning(false)` | Route context started but route not consuming; persisted as not running |

## Sequence Diagram

```
DynamicRoutesManager -> [Executor Thread]: submit loadRoutes()
[Executor Thread] -> DynamicRouteRepository: findAll(page 0)
DynamicRouteRepository -> MongoDB: query routes collection (page)
MongoDB --> DynamicRouteRepository: page of DynamicRoute documents
DynamicRouteRepository --> [Executor Thread]: Page<DynamicRoute>
[Executor Thread] -> [Executor Thread]: preProcessRoute(route)
[Executor Thread] -> CamelRouteBuilder: new RouteBuilder(route, context)
CamelRouteBuilder --> [Executor Thread]: configured RouteBuilder
[Executor Thread] -> SpringCamelContext: addRoutes(routeBuilder)
[Executor Thread] -> SpringCamelContext: start()
SpringCamelContext -> JMS Broker: establish JMS connection (source + destination)
JMS Broker --> SpringCamelContext: connection established
[Executor Thread] -> SpringCamelContext: startRoute(routeName)
SpringCamelContext --> [Executor Thread]: route started
[Executor Thread] -> DynamicRouteRepository: save(route) [running=true]
DynamicRouteRepository -> MongoDB: update routes document
[Executor Thread] -> [Executor Thread]: continue with next page/route
```

## Related

- Architecture dynamic view: `components-continuumDynamicRoutingWebApp`
- Related flows: [Route Creation](route-creation.md), [Route Start and Stop](route-start-stop.md)
