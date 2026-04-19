---
service: "api-proxy-config"
title: "Promote Route Request"
generated: "2026-03-03"
type: flow
flow_name: "promote-route-request"
flow_type: batch
trigger: "Manual operator invocation or CI pipeline with JSON request object"
participants:
  - "routeMutationScripts"
  - "regionEnvOptionParser"
  - "routingConfigFileResolver"
  - "routeReadScripts"
  - "routingConfigArtifacts"
architecture_ref: "dynamic-promote-route-request-flow"
---

# Promote Route Request

## Summary

The promote route request flow copies a route configuration from a lower environment (e.g., staging) into a higher environment (e.g., production) by reading the previous environment's `routingConf.json` as a reference and merging the specified route group and destination into the target environment's configuration file. This is the primary mechanism for safely propagating new routing rules up through the environment chain without manually duplicating JSON structures.

## Trigger

- **Type**: manual
- **Source**: Operator or CI pipeline invokes `promoteRouteRequest.js` with a JSON request object specifying the target region, environment, route group, routes, destination, and promotion case
- **Frequency**: On-demand, typically once per service onboarding or route change promotion cycle

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Route Mutation Scripts | Orchestrates the full promotion sequence: parses arguments, resolves files, checks for conflicts, applies mutations | `routeMutationScripts` |
| Region and Environment Option Parser | Resolves `--region`, `--env`, and `--isCloud` arguments to identify target and previous environments | `regionEnvOptionParser` |
| Routing Config File Resolver | Builds concrete `routingConf.json` file paths for both the target and previous environment | `routingConfigFileResolver` |
| Route Read Scripts | Checks for existing routes before applying mutations to prevent duplicate route entries | `routeReadScripts` |
| Routing Configuration Artifacts | JSON configuration files that are read from (previous env) and written to (target env) | `routingConfigArtifacts` |

## Steps

1. **Parse CLI arguments**: Receives the JSON request object containing `region`, `env`, `isCloudRequest`, `routeGroupId`, `routes`, `case`, and optionally `destinationInfo`
   - From: `routeMutationScripts`
   - To: `regionEnvOptionParser`
   - Protocol: direct (Node.js function call)

2. **Resolve target and previous environment file paths**: Calls `getRoutingConfigFiles` for the target environment and `getPreviousEnvironmentRoutingConfigFiles` for the environment immediately below it in the chain (UAT → Staging → Production for NA; Staging → Production for EMEA)
   - From: `routeMutationScripts`
   - To: `routingConfigFileResolver`
   - Protocol: direct (Node.js function call)

3. **Check for existing routes**: Calls `doRoutesExist` to verify the routes being promoted do not already exist in the target environment's `routingConf.json`; throws an error listing conflicting routes if any are found
   - From: `routeMutationScripts`
   - To: `routeReadScripts`
   - Protocol: direct (Node.js function call)

4. **Apply mutation based on case**: Selects one of three promotion cases and mutates the parsed target environment config object in memory:
   - **Case `routeGroupExists`**: Adds the specified routes to the matching route group in the target config
   - **Case `routeGroupDoesntExistDestinationExists`**: Deep-clones the route group from the previous environment config, assigns new routes, pushes the new route group to the target config, and adds the route group to the appropriate realm(s)
   - **Case `routeGroupDoesntExistDestinationDoesntExist`**: Performs the above plus creates a new destination entry in the target config, deriving the `host` VIP from `destinationInfo.destination_vips` and colo-adjusting for `sac1` vs `snc1`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory mutation)
   - Protocol: direct (Node.js function call)

5. **Persist mutated config**: Writes the updated config object back to each target environment `routingConf.json` file using `fs.writeFileSync` with 4-space JSON indentation
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (file system)
   - Protocol: File I/O

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Route already exists in target environment | `doRoutesExist` returns true; `promoteRouteRequest.js` throws `"Existing route(s): [...] found"` | Aborts without modifying any files |
| Unknown promotion case value | `switch` default branch throws `"Couldn't find the route promoter case: ..."` | Aborts without modifying any files |
| Destination not found in previous environment | `assert` throws with message referencing the missing destination name | Aborts without modifying any files |
| Invalid `destination_vips` array | `assert.ok` on `destination_vips.length === 1` fails | Aborts without modifying any files |
| No routing files found for region/env combo | `getRoutingConfigFiles` returns empty array; `assert.ok(fileNames.length > 0)` fails | Aborts without modifying any files |

## Sequence Diagram

```
Operator -> routeMutationScripts: Invoke promoteRouteRequest(requestJson)
routeMutationScripts -> regionEnvOptionParser: Parse region, env, isCloudRequest
routeMutationScripts -> routingConfigFileResolver: getRoutingConfigFiles(region, env, isCloud)
routingConfigFileResolver --> routeMutationScripts: [targetEnvFilePaths]
routeMutationScripts -> routingConfigFileResolver: getPreviousEnvironmentRoutingConfigFiles(region, env, isCloud)
routingConfigFileResolver --> routeMutationScripts: [prevEnvFilePaths]
routeMutationScripts -> routeReadScripts: doRoutesExist(region, env, isCloud, routes, routeGroupId)
routeReadScripts -> routingConfigArtifacts: Read target routingConf.json
routeReadScripts --> routeMutationScripts: [routeExistenceBooleans]
routeMutationScripts -> routingConfigArtifacts: Read prevEnv routingConf.json
routeMutationScripts -> routeMutationScripts: Apply mutation (case: routeGroupExists | routeGroupDoesntExistDestinationExists | routeGroupDoesntExistDestinationDoesntExist)
routeMutationScripts -> routingConfigArtifacts: Write mutated routingConf.json
```

## Related

- Architecture dynamic view: `dynamic-promote-route-request-flow`
- Related flows: [Add New Route](add-new-route.md), [Remove Routes](remove-routes.md)
- Source: `config_tools/promoteRouteRequest.js`
