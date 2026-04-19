---
service: "api-proxy-config"
title: "Clean Experiments"
generated: "2026-03-03"
type: flow
flow_name: "clean-experiments"
flow_type: batch
trigger: "Manual operator invocation via cleanExperimentsCli.js after an A/B experiment has fully rolled out"
participants:
  - "routeMutationScripts"
  - "routingConfigFileResolver"
  - "routingConfigArtifacts"
architecture_ref: "components-api-proxy-config-tools"
---

# Clean Experiments

## Summary

The clean experiments flow removes completed A/B routing experiments from `routingConf.json`, promoting the winning variant's destination as the permanent route group destination and deleting the losing variant's destination if it is no longer referenced elsewhere. An experiment is considered fully rolled out when its `startBucket` is 0, `endBucket` is 999, and its `type` is `"rollout"`. Operators can clean a specific experiment by ID or clean all fully-rolled-out experiments at once with `--exp=All`.

## Trigger

- **Type**: manual
- **Source**: Operator invokes `cleanExperimentsCli.js --env=<env> --region=<region> --exp=<experimentId|All> [--isCloud=true]`
- **Frequency**: On-demand, once per experiment lifecycle after the experiment owner signals that rollout is complete

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Route Mutation Scripts | Orchestrates the experiment cleanup: resolves files, iterates layers/experiments, promotes winning destination | `routeMutationScripts` |
| Routing Config File Resolver | Resolves target `routingConf.json` file paths for all zones in the given region/environment | `routingConfigFileResolver` |
| Routing Configuration Artifacts | JSON files read from disk and written back with experiment entries removed | `routingConfigArtifacts` |

## Steps

1. **Resolve target file paths**: Calls `getRoutingConfigFiles(region, env, isCloudRequest)` to resolve all zone-specific `routingConf.json` paths (e.g., both `production-us-west-1` and `production-us-central1` for NA production cloud)
   - From: `routeMutationScripts`
   - To: `routingConfigFileResolver`
   - Protocol: direct (Node.js function call)

2. **Read existing config**: Parses each target `routingConf.json` file from disk into a JavaScript object
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.readFileSync`)

3. **Iterate experiment layers**: Scans `config.layers` for each layer; within each layer iterates `layer.experiments` to find matching experiments
   - Matches `experimentIdWanted === "All"` with `startBucket === 0 && endBucket === 999 && type === "rollout"`
   - Matches specific ID with `experiments[j].id === experimentIdWanted`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

4. **Remove experiment from realm references**: Removes the composite experiment ID (e.g., `lazlo_v2_experiments.groupons_put`) from all `realm.experiments[]` arrays
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

5. **Promote winning variant destination**: Reads the experiment's first variant (`variants[0]`) settings to get the target route group and its winning destination; calls `replaceRouteGroupDestination` to update the route group's `destination` field permanently
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

6. **Identify and remove losing variant destination**: Reads the second variant (`variants[1]`) settings to identify the potentially-unused destination; after the experiment is deleted, calls `removeUnusedDestination` which runs `hasUnusedDestination` to check if any route group or other experiment variant still references this destination before removing it from `config.destinations`
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

7. **Delete experiment entry**: Removes the experiment from `layer.experiments` array using `experiments.splice(j, 1)` and decrements the iteration index
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts` (in-memory)
   - Protocol: direct

8. **Persist updated config**: Writes the mutated config back to each zone-specific `routingConf.json` file with 4-space JSON indentation
   - From: `routeMutationScripts`
   - To: `routingConfigArtifacts`
   - Protocol: File I/O (`fs.writeFileSync`)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| Experiment ID not found in any layer | Outer `forEach` iterates without match; no changes applied | Silent no-op |
| Losing variant destination still referenced by another route group or experiment | `hasUnusedDestination` returns false; destination NOT removed | Destination preserved; experiment deleted |
| Experiment marked `--exp=All` but no fully-rolled-out experiments present | Condition `startBucket === 0 && endBucket === 999 && type === "rollout"` matches nothing | Silent no-op; files written unchanged |

## Sequence Diagram

```
Operator -> routeMutationScripts: Invoke cleanExperiments({region, env, isCloudRequest, experiments: [experimentId|"All"]})
routeMutationScripts -> routingConfigFileResolver: getRoutingConfigFiles(region, env, isCloudRequest)
routingConfigFileResolver --> routeMutationScripts: [filePaths]
routeMutationScripts -> routingConfigArtifacts: Read routingConf.json (per zone file)
routingConfigArtifacts --> routeMutationScripts: parsedConfig
routeMutationScripts -> routeMutationScripts: For each layer.experiment matching criteria:
routeMutationScripts -> routeMutationScripts: removeEmptyExperimentFromRealms(realms, compositeId)
routeMutationScripts -> routeMutationScripts: replaceRouteGroupDestination(routeGroups, routeGroup, winningDestination)
routeMutationScripts -> routeMutationScripts: experiments.splice(j, 1) — delete experiment
routeMutationScripts -> routeMutationScripts: removeUnusedDestination(config, losingDestination)
routeMutationScripts -> routingConfigArtifacts: Write mutated routingConf.json
```

## Related

- Architecture component view: `components-api-proxy-config-tools`
- Related flows: [Add New Route](add-new-route.md)
- Source: `config_tools/cleanExperiments.js`, `config_tools/cleanExperimentsCli.js`
