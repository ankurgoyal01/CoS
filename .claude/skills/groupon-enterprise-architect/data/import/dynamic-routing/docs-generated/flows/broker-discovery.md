---
service: "dynamic-routing"
title: "Broker Discovery"
generated: "2026-03-03"
type: flow
flow_name: "broker-discovery"
flow_type: synchronous
trigger: "Admin UI requests destination list for a broker"
participants:
  - "continuumDynamicRoutingWebApp"
  - "messageBusBrokers_9f42"
architecture_ref: "components-continuumDynamicRoutingWebApp"
---

# Broker Discovery

## Summary

When an operator uses the admin UI to create or inspect a dynamic route, the application queries the target JMS broker's Jolokia HTTP-JMX endpoint to discover available queues and topics, and to determine the broker's connection parameters. This allows the admin UI to present a live list of valid JMS destinations and to correctly configure connection factories for new routes.

## Trigger

- **Type**: User action (admin UI interaction)
- **Source**: Admin UI destination picker — operator selects a broker to view its queues/topics
- **Frequency**: On-demand; called each time the operator opens the destination picker or adds a new broker

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Admin UI | Initiates discovery request when operator selects a broker | `continuumDynamicRoutingWebApp` → `adminUi` |
| Broker Discovery & JMX | Calls Jolokia; interprets acceptor data and destination lists | `continuumDynamicRoutingWebApp` → `brokerDiscovery` |
| Jolokia Endpoint on Broker | JMX-over-HTTP interface exposing broker MBeans | `messageBusBrokers_9f42` (Jolokia port — default 8161) |

## Steps

1. **Operator selects broker in admin UI**: The admin UI iterates `BrokersInfoContainer` to render the broker drop-down. Operator selects a broker (registered in `brokerInfo.properties`).
   - From: `adminUi`
   - To: `routeManager` / `brokerDiscovery`
   - Protocol: Direct (JSF managed bean)

2. **Create `BrokerDiscoverer`**: `BrokerDiscovererFactory` creates a `BrokerDiscoverer` instance for the selected broker, configured with the broker's Jolokia hosts, port, credentials, and client type (`mbus` or `jms`). A `ClusterManagementClient` is created (selecting between `JolokiaArtemis12ManagementClient` for HornetQ/Artemis 1.x and `JolokiaArtemis25ManagementClient` for Artemis 2.x based on version detection).
   - From: `brokerDiscovery`
   - To: Jolokia endpoint
   - Protocol: HTTP (Jolokia REST)

3. **Detect broker version**: `ManagementClientFactory.createClusterManagementClient()` iterates compatible `ManagementClient` implementations and calls `isCompatible()` on each. For Artemis 2.x, it reads the `Version` attribute from `org.apache.activemq.artemis:broker="0.0.0.0"`. For HornetQ, it detects `hornetq` in the factory class name of acceptors.
   - From: `brokerDiscovery` (Jolokia client)
   - To: Broker MBean server via Jolokia HTTP
   - Protocol: HTTP GET to `/jolokia/read/<mbean>/<attribute>`

4. **Fetch acceptors**: `managementClient.getAcceptors()` reads acceptor configurations from the broker MBean. For Artemis 2.x: `org.apache.activemq.artemis:broker="0.0.0.0",component=acceptors,name="*"`. For HornetQ: equivalent MBean path. Acceptors are used to determine connection type (INTERNATIONAL, MBUS_HOST, or MBUS_VIP) and broker port.
   - From: `brokerDiscovery`
   - To: Broker Jolokia endpoint
   - Protocol: HTTP

5. **Determine connection type**: `BrokerDiscoverer.getConnectionType()` inspects the active acceptor's factory class name to classify the connection as `INTERNATIONAL` (HornetQ/JMS client), `MBUS_HOST` (direct mbus connection), or `MBUS_VIP` (VIP-based mbus connection).
   - From: `brokerDiscovery`
   - To: `brokerDiscovery` (in-process)
   - Protocol: Direct

6. **Enumerate destinations**: `BrokerDiscoverer.getDestinations(DestinationType.QUEUE)` or `getDestinations(DestinationType.TOPIC)` calls `managementClient.findAllDestinations()`. For Artemis 2.x, this queries `org.apache.activemq.artemis:broker="0.0.0.0",component=addresses,address="<prefix>*"` and returns a set of destination names stripped of the address prefix.
   - From: `brokerDiscovery`
   - To: Broker Jolokia endpoint
   - Protocol: HTTP

7. **Return destination list to admin UI**: The set of queue or topic names is returned to the JSF admin UI for display in the destination picker.
   - From: `brokerDiscovery`
   - To: `adminUi`
   - Protocol: Direct

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Jolokia endpoint unreachable | `Optional.empty()` returned from `readValue()`; `orElseThrow()` raises `RuntimeException` | Exception propagates to admin UI; destination picker shows error or empty list |
| No acceptors found on broker | `"No available connection factories in the cluster"` exception | Route creation blocked; admin UI shows error |
| No compatible connection factory | `"Could not find supported connection factory in the cluster"` exception | Route creation blocked |
| Artemis version check returns empty | Falls back to next `ManagementClient` implementation | Transparent; handled by `ManagementClientFactory` iteration |

## Sequence Diagram

```
Operator -> Admin UI: select broker for destination picker
Admin UI -> BrokerDiscovererFactory: createBrokerDiscoverer(brokerInfo)
BrokerDiscovererFactory -> ManagementClientFactory: createClusterManagementClient(jolokiaHosts, port)
ManagementClientFactory -> JolokiaArtemis25Client: isCompatible()
JolokiaArtemis25Client -> Broker Jolokia: GET /jolokia/read/org.apache.activemq.artemis:broker="0.0.0.0"/Version
Broker Jolokia --> JolokiaArtemis25Client: "2.6.4"
JolokiaArtemis25Client --> ManagementClientFactory: compatible=true
ManagementClientFactory --> BrokerDiscovererFactory: Artemis25ManagementClient
BrokerDiscovererFactory --> Admin UI: BrokerDiscoverer instance
Admin UI -> BrokerDiscoverer: getDestinations(QUEUE)
BrokerDiscoverer -> BrokerDiscoverer: initIfNeeded() [fetch acceptors]
BrokerDiscoverer -> Broker Jolokia: GET /jolokia/read/.../acceptors
Broker Jolokia --> BrokerDiscoverer: acceptor map
BrokerDiscoverer -> Broker Jolokia: GET /jolokia/read/.../addresses (queues)
Broker Jolokia --> BrokerDiscoverer: queue name set
BrokerDiscoverer --> Admin UI: Set<String> of queue names
Admin UI --> Operator: destination drop-down populated
```

## Related

- Architecture dynamic view: `components-continuumDynamicRoutingWebApp`
- Related flows: [Route Creation](route-creation.md)
