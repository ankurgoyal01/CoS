---
service: "api-proxy-config"
title: "Remove Routes"
generated: "2026-03-03"
type: flow
flow_name: "remove-routes"
flow_type: batch
trigger: "Manual operator invocation via removeRoutesCli.js with region, environment, and route specifications"
participants:
  - "routeMutationScripts"
  - "routingConfigFileResolver"
  - "routingConfigArtifacts"
architecture_ref: "components-api-proxy-config-tools"
---

# Remove Routes

## Summary

The remove routes flow deletes one or more route path/method combinations from a named route group in the target environment's `routingConf.json`. If a route group is left empty after route removal, it and its destination (if unused by any other route group) are also removed, and the route group is cleaned from all realm entries. This ensures routing config stays consistent and free of orphaned entries.

## Trigger

- **Type**: manual
- **Source**: Operator invokes `removeRoutesCli.js` with `--env`, `--region`, `--routeGroup`, `[--isCloud]`, and route path/method specifications
- **Frequency**: On-demand, during service decommissioning, route cleanup, or traffic migration

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Route Mutation Scripts | Orchestrates the remove sequence: resolves files, iterates routes, applies deletions | `routeMutationScripts` |
| Routing Config File Resolver | Resolves target `routingConf.json` file paths for the given region, environment, and cloud mode | `routingConfigFileResolver` |
| Routing Configuration Artifacts | JSON files read from disk and written back with routes removed | `routingConfigArtifacts` |

## Steps

1. **Resolve target file paths**: Calls `getRoutingConfigFiles(region, env, isCloudRequest)` to build the list of `routingConf.json` file paths for the specified region/environment/zone combination
   - From: `routeMutationScripts`
   - To: `routingConfigFileResolver`
   - Protocol: direct (Node.js function call)

2. **Read existing config**: Parses each target `routingConf.json` file from disk
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.readFileSync`)

3. **Iterate over routes to remove**: For each `{path, method, exact}` in the request, calls `removePathFromRouteGroup` on the parsed config targeting the specified `routeGroupId`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

4. **Determine removal scope per route**:
   - If the route group has only one route remaining and that route matches the removal request exactly (path and method match): the entire route group is removed
   - If multiple routes remain: only the matching path/method combination is removed from `routes[]`
   - If the route has multiple methods and only one method is being removed: `lodash.without` removes just that method from `methods[]`
   - If no methods are configured (wildcard route) and a specific method is requested for deletion: all other methods (`GET`, `POST`, `PUT`, `DELETE`, `PATCH`) are explicitly assigned, then the specified method is removed
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

5. **Clean up orphaned route group and destination** (when route group becomes empty):
   - Removes the route group from `config.routeGroups`
   - Checks if the destination is still referenced by any other route group; if not, removes it from `config.destinations`
   - Removes the route group ID from all realm `routeGroups[]` arrays
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

6. **Persist updated config**: Writes the mutated config back to each zone-specific `routingConf.json` file with 4-space JSON indentation
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.writeFileSync`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Route group ID not found in config | `routeGroups.forEach` iterates without match; no changes applied for that route group | Silent no-op for unmatched route groups |
| Path not found in route group | `routes.forEach` iterates without match; no changes applied | Silent no-op for unmatched paths |
| Destination still used by other route groups | `hasUnusedDestination` returns false; destination is NOT removed | Destination preserved; only route group entry is removed |

## Sequence Diagram

```
Operator -> routeMutationScripts: Invoke removeRoutes(requestJson)
routeMutationScripts -> routingConfigFileResolver: getRoutingConfigFiles(region, env, isCloudRequest)
routingConfigFileResolver --> routeMutationScripts: [filePaths]
routeMutationScripts -> routingConfigArtifacts: Read routingConf.json (per zone file)
routingConfigArtifacts --> routeMutationScripts: parsedConfig
routeMutationScripts -> routeMutationScripts: For each route: removePathFromRouteGroup(config, routeGroupId, path, method, exact)
routeMutationScripts -> routeMutationScripts: handleRemovePath OR handleRemoveRouteGroup (if last route)
routeMutationScripts -> routeMutationScripts: removeRouteGroupFromRealm (if route group deleted)
routeMutationScripts -> routeMutationScripts: removeUnusedDestination (if destination orphaned)
routeMutationScripts -> routingConfigArtifacts: Write mutated routingConf.json
```

## Related

- Architecture component view: `components-api-proxy-config-tools`
- Related flows: [Add New Route](add-new-route.md), [Promote Route Request](promote-route-request.md)
- Source: `config_tools/removeRoutes.js`, `config_tools/removeRoutesCli.js`
