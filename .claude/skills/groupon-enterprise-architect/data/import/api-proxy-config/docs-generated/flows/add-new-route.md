---
service: "api-proxy-config"
title: "Add New Route"
generated: "2026-03-03"
type: flow
flow_name: "add-new-route"
flow_type: batch
trigger: "Manual operator invocation with JSON request object specifying destination, routes, and realm"
participants:
  - "routeMutationScripts"
  - "routingConfigFileResolver"
  - "routeReadScripts"
  - "routingConfigArtifacts"
architecture_ref: "components-api-proxy-config-tools"
---

# Add New Route

## Summary

The add new route flow registers a new API route in the target environment's `routingConf.json`, either by adding routes to an existing route group or by creating a new route group and optionally a new destination. It enforces that no duplicate routes are added, correctly assigns the route group to the appropriate realm (internal, external, or both), and handles VIP host assignment for cloud vs. data center deployments.

## Trigger

- **Type**: manual
- **Source**: Operator invokes `addNewRouteRequest.js` with a JSON request object containing destination name, destination VIPs, routes (with `routing_path` and `http_methods`), realm, region, environment, and cloud mode
- **Frequency**: On-demand, once per new service route onboarding

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Route Mutation Scripts | Orchestrates the add-route sequence: resolves files, manages destination and route group creation, assigns realms | `routeMutationScripts` |
| Routing Config File Resolver | Resolves target `routingConf.json` file paths for the given region, environment, and cloud mode | `routingConfigFileResolver` |
| Route Read Scripts | Not directly called, but destination and route group existence checks are performed inline | `routeReadScripts` |
| Routing Configuration Artifacts | JSON files read from disk and written back with the new route, route group, and destination entries | `routingConfigArtifacts` |

## Steps

1. **Validate request**: Validates that `destination_vips` is a non-empty array and all required fields (`destinationPort`, `sslSupport`, `connectionTimeout`, `requestTimeout`, `authHeaderSupport`) are present
   - From: `routeMutationScripts`
   - To: `routeMutationScripts` (internal assertion)
   - Protocol: direct (Node.js `assert`)

2. **Resolve target file paths**: Calls `getRoutingConfigFiles(region, env, isCloudRequest)` to build the list of `routingConf.json` file paths to update (one per zone for the given region/env combination)
   - From: `routeMutationScripts`
   - To: `routingConfigFileResolver`
   - Protocol: direct (Node.js function call)

3. **Read existing config**: Parses each target `routingConf.json` file from disk into a JavaScript object
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.readFileSync`)

4. **Create or reuse destination**: If `isNewDestination` is true, creates a new destination entry with `type: "static"`, VIP host, port, SSL, timeouts, heartbeat URI, and — for cloud requests — a `forcedHeaders.Host` entry; pushes it to `config.destinations`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

5. **Create or reuse route group**: Checks for an existing route group serving the same destination within the specified realm; if found, adds new methods to matching route paths or appends new routes; if not found, creates a new route group with `id`, `name`, `destination`, and `routes[]`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

6. **Assign route group to realm**: Finds the realm entries in `config.realms` matching the requested `realm` (internal → `us_api_internal`/`api_groupon_de_internal`; external → `us_api`/`api_groupon_de`; both → both); adds the route group ID to `realm.routeGroups` if not already present
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

7. **Persist updated config**: Writes the mutated config object back to each zone-specific `routingConf.json` file using `fs.writeFileSync` with 4-space JSON indentation
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.writeFileSync`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Duplicate route methods on existing path | `addMethodsToExistingRoutesAndGetNewRoutes` collects conflicting routes and throws `"One or more requested routes already exist: ..."` | Aborts without writing |
| Missing required destination fields | `assert.ok` fails with a descriptive message for each missing field | Aborts without writing |
| No realm found for the requested realm name | `assert.ok(realm !== null)` fails with `"No realm found for <name>"` | Aborts without writing |
| Route group added under different realm than requested | `assert(isNewRouteGroup)` fails with message explaining cross-realm conflict | Aborts without writing |
| Empty `destination_vips` array | `assert.ok` fails | Aborts without writing |

## Sequence Diagram

```
Operator -> routeMutationScripts: Invoke addNewRouteRequest(json)
routeMutationScripts -> routeMutationScripts: Validate request fields (assert)
routeMutationScripts -> routingConfigFileResolver: getRoutingConfigFiles(region, env, isCloudRequest)
routingConfigFileResolver --> routeMutationScripts: [filePaths]
routeMutationScripts -> routingConfigArtifacts: Read routingConf.json (per zone file)
routingConfigArtifacts --> routeMutationScripts: parsedConfig
routeMutationScripts -> routeMutationScripts: addNewDestination (if isNewDestination)
routeMutationScripts -> routeMutationScripts: getOrCreateRouteGroup (find existing or create new)
routeMutationScripts -> routeMutationScripts: addRouteGroup to realm (internal | external | both)
routeMutationScripts -> routingConfigArtifacts: Write mutated routingConf.json
```

## Related

- Architecture component view: `components-api-proxy-config-tools`
- Related flows: [Promote Route Request](promote-route-request.md), [Remove Routes](remove-routes.md)
- Source: `config_tools/addNewRouteRequest.js`
