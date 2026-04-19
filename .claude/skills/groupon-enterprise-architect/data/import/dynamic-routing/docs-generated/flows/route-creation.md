---
service: "dynamic-routing"
title: "Route Creation"
generated: "2026-03-03"
type: flow
flow_name: "route-creation"
flow_type: synchronous
trigger: "Admin UI form submission or PUT /brokers/{brokerId} + addRoute API call"
participants:
  - "continuumDynamicRoutingWebApp"
  - "continuumDynamicRoutingMongoDb"
  - "messageBusBrokers_9f42"
architecture_ref: "components-continuumDynamicRoutingWebApp"
---

# Route Creation

## Summary

An operator uses the JSF admin UI to define a new dynamic route, selecting source and destination brokers and endpoints, and optionally configuring a filter chain and message transformer. The application constructs a new Spring Camel context for the route, starts it (establishing JMS connections to both broker endpoints), and persists the route definition to MongoDB. From this point, the route is live and forwarding messages.

## Trigger

- **Type**: User action (operator)
- **Source**: JSF Admin UI — operator submits the route creation form; internally calls `DynamicRoutesManager.addRoute(dynamicRoute)`
- **Frequency**: On-demand (operator-initiated)

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin UI | Collects route parameters from operator; invokes route manager | `continuumDynamicRoutingWebApp` → `adminUi` |
| Dynamic Routes Manager | Creates Camel context, starts it, and delegates to repository for persistence | `continuumDynamicRoutingWebApp` → `routeManager` |
| Camel Route Builder | Constructs the Camel `RouteBuilder` from the `DynamicRoute` definition | `continuumDynamicRoutingWebApp` → `routeBuilder` |
| Broker Discovery & JMX | Queried before route creation to populate destination picker in admin UI | `continuumDynamicRoutingWebApp` → `brokerDiscovery` |
| Dynamic Route Repository | Persists the new route document to MongoDB | `continuumDynamicRoutingWebApp` → `routeRepository` |
| Dynamic Routing MongoDB | Stores the new route definition | `continuumDynamicRoutingMongoDb` |
| JMS Brokers (source + destination) | Accept JMS connections when the Camel context starts | `messageBusBrokers_9f42` |

## Steps

1. **Operator selects source broker**: The admin UI queries the registered broker list from `BrokersInfoContainer` (populated from `brokerInfo.properties`). Operator picks source broker.
   - From: `adminUi`
   - To: `routeManager`
   - Protocol: Direct (JSF managed bean)

2. **Discover source destinations**: `BrokerDiscoverer.getDestinations(QUEUE or TOPIC)` calls Jolokia on the selected broker to list all available JMS queues or topics. Operator selects source endpoint.
   - From: `brokerDiscovery`
   - To: JMS Broker Jolokia endpoint
   - Protocol: HTTP (Jolokia REST)

3. **Operator selects destination broker and endpoint**: Same discovery process as steps 1–2 for the destination side.
   - From: `adminUi` / `brokerDiscovery`
   - To: JMS Broker Jolokia endpoint
   - Protocol: HTTP (Jolokia REST)

4. **Operator configures optional filter chain and transformer**: Admin UI allows adding filter predicates and a transformer (e.g., JSON body transformation, header modification). Operator submits the form.
   - From: `adminUi`
   - To: `routeManager`
   - Protocol: Direct (JSF form submit)

5. **Create new Spring Camel context**: `DynamicRoutesManager.addRoute()` creates a new `SpringCamelContext` and calls `camelContext.start()`.
   - From: `routeManager`
   - To: `routeBuilder`
   - Protocol: Apache Camel API

6. **Build and register Camel route**: `CamelRouteBuilderProvider.routeBuilder(dynamicRoute, camelContext)` constructs the `CamelRouteBuilder`. Components for source and destination JMS endpoints are added to the context. `camelContext.addRoutes(routeBuilder)` registers the route DSL.
   - From: `routeBuilder`
   - To: `messageBusBrokers_9f42`
   - Protocol: JMS (HornetQ Netty / Artemis JMS client)

7. **Start consuming messages**: The Camel context and route begin consuming from the source endpoint immediately (route starts automatically on context start for new routes).
   - From: `routeManager`
   - To: JMS source broker
   - Protocol: JMS

8. **Persist route to MongoDB**: `DynamicRouteRepository.save(dynamicRoute)` writes the complete route document (name, source endpoint, destination endpoint, filter chain, transformer, tracing, `running=true`) to the `routes` collection.
   - From: `routeManager`
   - To: `continuumDynamicRoutingMongoDb`
   - Protocol: MongoDB wire protocol

9. **Admin UI confirms success**: The JSF UI refreshes to show the new route in the routes list with status `Started`.
   - From: `adminUi`
   - To: Operator (browser)
   - Protocol: HTTPS

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jolokia unreachable during destination discovery | Exception propagated to admin UI | Destination picker is empty; operator cannot select endpoints |
| `camelContext.addRoutes()` fails (e.g., invalid endpoint config) | Runtime exception thrown by `addRoute()` | New Camel context not added to `camelContexts` map; route not persisted; admin UI shows error |
| JMS broker unreachable on context start | `camelContext.start()` throws; exception propagates from `addRoute()` | Route not created or persisted; broker reconnection is not retried for new routes (unlike loaded routes) |
| MongoDB write fails | Spring Data exception propagates | Camel context is running but route is not persisted; it will be lost on restart — operator must re-create |
| Duplicate route name | No explicit check in `addRoute()`; MongoDB `_id` uniqueness constraint would reject duplicate saves | Spring Data throws `DuplicateKeyException`; propagated to admin UI |

## Sequence Diagram

```
Operator -> Admin UI: Submit route creation form
Admin UI -> BrokerDiscovery: getDestinations(sourcebroker, QUEUE)
BrokerDiscovery -> JMS Broker Jolokia: HTTP GET /jolokia (list queues)
JMS Broker Jolokia --> BrokerDiscovery: destination names
BrokerDiscovery --> Admin UI: queue/topic list
Admin UI -> DynamicRoutesManager: addRoute(dynamicRoute)
DynamicRoutesManager -> SpringCamelContext: new context + start()
DynamicRoutesManager -> CamelRouteBuilder: routeBuilder(dynamicRoute, context)
CamelRouteBuilder -> SpringCamelContext: addRoutes(routeBuilder)
SpringCamelContext -> Source JMS Broker: establish connection + start consuming
SpringCamelContext -> Destination JMS Broker: establish connection
DynamicRoutesManager -> DynamicRouteRepository: save(dynamicRoute)
DynamicRouteRepository -> MongoDB: insert routes document
MongoDB --> DynamicRouteRepository: ack
DynamicRoutesManager --> Admin UI: success
Admin UI --> Operator: Route created and active
```

## Related

- Architecture dynamic view: `components-continuumDynamicRoutingWebApp`
- Related flows: [Startup Route Loading](startup-route-loading.md), [Message Forwarding](message-forwarding.md), [Broker Discovery](broker-discovery.md)
