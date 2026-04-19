---
service: "dynamic-routing"
title: "Route Start and Stop"
generated: "2026-03-03"
type: flow
flow_name: "route-start-stop"
flow_type: synchronous
trigger: "Admin UI start/stop action or service shutdown"
participants:
  - "continuumDynamicRoutingWebApp"
  - "continuumDynamicRoutingMongoDb"
architecture_ref: "components-continuumDynamicRoutingWebApp"
---

# Route Start and Stop

## Summary

Operators can start or stop individual dynamic routes at runtime through the admin UI without restarting the application. Starting a route begins message consumption from the source endpoint; stopping it pauses consumption while preserving the route definition. The `running` state is persisted to MongoDB so the route resumes its correct state on next application startup. On application shutdown, all routes are gracefully stopped.

## Trigger

- **Type**: User action (operator) or application lifecycle event
- **Source**: Admin UI start/stop button; or Spring `DisposableBean.destroy()` on JVM shutdown
- **Frequency**: On-demand (operator-initiated) or once on service shutdown

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin UI | Presents route status and start/stop controls; invokes route manager | `continuumDynamicRoutingWebApp` → `adminUi` |
| Dynamic Routes Manager | Controls Camel context lifecycle; persists state changes | `continuumDynamicRoutingWebApp` → `routeManager` |
| Dynamic Route Repository | Fetches and updates route documents in MongoDB | `continuumDynamicRoutingWebApp` → `routeRepository` |
| Dynamic Routing MongoDB | Stores updated `running` state | `continuumDynamicRoutingMongoDb` |

## Steps — Start Route

1. **Operator clicks Start in admin UI**: The admin UI invokes `DynamicRoutesManager.startRoute(routeName)` (synchronized).
   - From: `adminUi`
   - To: `routeManager`
   - Protocol: Direct (JSF managed bean)

2. **Fetch current route state from MongoDB**: `DynamicRouteRepository.findOne(routeName)` retrieves the current `DynamicRoute` document.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

3. **Start the Camel route**: `camelContexts.get(routeName).startRoute(routeName)` resumes message consumption on the existing Camel context. The context was already initialized during startup loading or route creation.
   - From: `routeManager`
   - To: Camel context (in-process)
   - Protocol: Apache Camel API

4. **Update running state**: `dynamicRoute.setRunning(true)` and `DynamicRouteRepository.save(dynamicRoute)` persist the updated state.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

5. **Admin UI refreshes route status**: Route shows `Started` in the admin UI routes list.
   - From: `adminUi`
   - To: Operator (browser)
   - Protocol: HTTPS

## Steps — Stop Route

1. **Operator clicks Stop in admin UI**: The admin UI invokes `DynamicRoutesManager.stopRoute(routeName)` (synchronized).
   - From: `adminUi`
   - To: `routeManager`
   - Protocol: Direct

2. **Fetch current route state**: `DynamicRouteRepository.findOne(routeName)` retrieves the route document.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

3. **Stop the Camel route**: `camelContexts.get(routeName).stopRoute(routeName)` halts message consumption. In-flight messages are allowed to complete (Camel graceful shutdown).
   - From: `routeManager`
   - To: Camel context (in-process)
   - Protocol: Apache Camel API

4. **Update running state to false**: `dynamicRoute.setRunning(false)` and `DynamicRouteRepository.save(dynamicRoute)` persist the stopped state.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

## Steps — Remove Route

1. **Operator clicks Delete in admin UI**: The admin UI invokes `DynamicRoutesManager.removeRoute(routeName)` (synchronized).
   - From: `adminUi`
   - To: `routeManager`
   - Protocol: Direct

2. **Stop and remove Camel route and context**: `stopRoute()`, `removeRoute()`, component removal (`<routeName>SrcBroker`, `<routeName>DstBroker`), and `camelContext.stop()` are called sequentially.
   - From: `routeManager`
   - To: Camel context (in-process)
   - Protocol: Apache Camel API

3. **Drop durable subscription if applicable**: If the source endpoint was a durable `TopicEndpoint` with JNDI connection, `dropDurableSubscription()` is called. This sends a JMS management message to `hornetq.management` queue requesting `dropDurableSubscription` on the topic MBean.
   - From: `routeManager`
   - To: Source JMS Broker (HornetQ management queue)
   - Protocol: JMS management API (`hornetq.management` queue)

4. **Delete route document from MongoDB**: `DynamicRouteRepository.delete(routeName)` removes the document from the `routes` collection.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

## Steps — Application Shutdown (Graceful)

On JVM shutdown, Spring calls `DynamicRoutesManager.destroy()` (registered via `DisposableBean`):

1. **Iterate all active Camel contexts**: For each entry in `camelContexts`, call `camelContext.stop()`.
2. **Stop each context gracefully**: Camel allows in-flight messages to complete before stopping.
3. Note: `running` state is NOT updated in MongoDB during graceful shutdown — routes that were running will be restarted automatically on next startup because their `running=true` state is still stored in MongoDB.

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Route not in `camelContexts` map | `NullPointerException` from `camelContexts.get(routeName)` | Exception propagates to admin UI; route state unchanged |
| MongoDB update fails on `save()` | Spring Data exception propagated | Camel route state changed but MongoDB not updated; state drift on next restart |
| `dropDurableSubscription` fails | Wrapped in `Exception("Unable to drop Durable Subscription!!")` | `removeRoute()` fails; Camel context is stopped but MongoDB deletion may not occur |
| `camelContext.stopRoute()` throws | Exception propagates | Route may be in inconsistent state; restart may be required |

## Sequence Diagram — Stop Route

```
Operator -> Admin UI: click Stop (routeName)
Admin UI -> DynamicRoutesManager: stopRoute(routeName) [synchronized]
DynamicRoutesManager -> DynamicRouteRepository: findOne(routeName)
DynamicRouteRepository -> MongoDB: query routes by _id
MongoDB --> DynamicRouteRepository: DynamicRoute document
DynamicRouteRepository --> DynamicRoutesManager: DynamicRoute
DynamicRoutesManager -> SpringCamelContext: stopRoute(routeName)
SpringCamelContext --> DynamicRoutesManager: route stopped
DynamicRoutesManager -> DynamicRoute: setRunning(false)
DynamicRoutesManager -> DynamicRouteRepository: save(dynamicRoute)
DynamicRouteRepository -> MongoDB: update routes document (running=false)
MongoDB --> DynamicRouteRepository: ack
DynamicRoutesManager --> Admin UI: success
Admin UI --> Operator: Route shows Stopped
```

## Related

- Architecture dynamic view: `components-continuumDynamicRoutingWebApp`
- Related flows: [Startup Route Loading](startup-route-loading.md), [Route Creation](route-creation.md)
