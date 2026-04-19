---
service: "sem-gtm"
title: "Container Startup and Configuration Load"
generated: "2026-03-03"
type: flow
flow_name: "container-startup"
flow_type: synchronous
trigger: "Kubernetes pod start event — triggered by a new deployment rollout, pod restart, or HPA scale-out"
participants:
  - "continuumSemGtmTaggingServer"
  - "continuumSemGtmPreviewServer"
  - "gtmApiUnknown_ab3a36"
architecture_ref: "dynamic-semGtmContainerStartup"
---

# Container Startup and Configuration Load

## Summary

When a new pod starts for either the tagging server or the preview server, the GTM Cloud image reads the `CONTAINER_CONFIG` environment variable to authenticate with Google's Tag Manager infrastructure and load the GTM workspace configuration. This startup process takes a significant amount of time (hence the 300-second initial delay on health probes), after which the container begins serving HTTP requests. The `RUN_AS_PREVIEW_SERVER` environment variable controls whether the container starts in preview mode or tagging mode.

## Trigger

- **Type**: event
- **Source**: Kubernetes pod scheduling event (new deployment rollout, pod crash recovery, or HPA-triggered scale-out)
- **Frequency**: Per pod start — triggered on every deployment, pod restart, or horizontal scale-out event

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes Scheduler | Schedules the new pod onto a GKE node | External (GKE infrastructure) |
| GTM Cloud Container (tagging or preview) | Reads startup environment variables; loads GTM workspace configuration | `continuumSemGtmTaggingServer` or `continuumSemGtmPreviewServer` |
| Google Tag Manager Cloud API | Authenticates the container and serves the GTM workspace configuration | `gtmApiUnknown_ab3a36` (stub) |
| Kubernetes Health Probe | Polls `/healthz` to determine when the container is ready for traffic | External (GKE infrastructure) |

## Steps

1. **Pod scheduled and container created**: Kubernetes schedules the pod; Docker pulls `docker-conveyor.groupondev.com/transam/sem-gtm` (built from `gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable`)
   - From: Kubernetes Scheduler
   - To: GKE node
   - Protocol: Kubernetes API

2. **Detect startup mode**: The GTM Cloud image reads `RUN_AS_PREVIEW_SERVER` — if `"true"`, starts in preview server mode; otherwise starts in tagging server mode
   - From: Container runtime
   - To: `continuumSemGtmPreviewServer` or `continuumSemGtmTaggingServer`
   - Protocol: In-process (environment variable read)

3. **Authenticate and load workspace configuration**: The container decodes `CONTAINER_CONFIG` (base64-encoded GTM container ID + auth token) and connects to the GTM Cloud API to download the active workspace configuration (tags, triggers, variables)
   - From: `continuumSemGtmTaggingServer` or `continuumSemGtmPreviewServer`
   - To: `gtmApiUnknown_ab3a36` (Google Tag Manager Cloud API)
   - Protocol: HTTPS

4. **Await readiness**: Kubernetes readiness probe polls `/healthz` every 30 seconds after the initial 300-second delay. The container returns `200 OK` only after workspace configuration is fully loaded and the HTTP server is ready
   - From: Kubernetes health probe
   - To: `continuumSemGtmTaggingServer` or `continuumSemGtmPreviewServer` (`/healthz`)
   - Protocol: HTTP

5. **Container enters serving state**: Once `/healthz` returns healthy, Kubernetes adds the pod to the Service endpoints and begins routing traffic to it
   - From: Kubernetes control plane
   - To: Pod endpoint
   - Protocol: Kubernetes API

6. **Configure preview server URL (tagging server only)**: On startup, the tagging server registers the `PREVIEW_SERVER_URL` (`https://gtm.groupon.com/preview/`) for routing debug session requests
   - From: `continuumSemGtmTaggingServer` (internal config read)
   - To: In-process
   - Protocol: In-process (environment variable read)

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| `CONTAINER_CONFIG` missing or malformed | GTM Cloud image fails to decode credentials; container cannot authenticate | Container never becomes healthy; readiness probe fails; pod is restarted by Kubernetes |
| GTM Cloud API unreachable during startup | Container cannot load workspace configuration | Readiness probe fails indefinitely; Kubernetes does not route traffic to the pod; pod eventually restarted |
| Startup takes longer than 300s initial delay | Health probes begin polling at 300s; probe may fail before startup completes | Pod marked unhealthy; Kubernetes restarts — mitigated by the 300s delay which covers typical startup time |
| HPA scale-out during high traffic | New pods start the full startup sequence; readiness delay means new capacity takes ~5+ minutes to become available | Existing replicas absorb load during scale-out startup period |

## Sequence Diagram

```
KubernetesScheduler -> GKENode: Schedule pod
GKENode -> GTMContainer: Start container (docker-conveyor.groupondev.com/transam/sem-gtm)
GTMContainer -> GTMContainer: Read RUN_AS_PREVIEW_SERVER (determine mode)
GTMContainer -> GTMContainer: Decode CONTAINER_CONFIG (GTM container ID + auth)
GTMContainer -> gtmApiUnknown_ab3a36: Authenticate and fetch workspace configuration (HTTPS)
gtmApiUnknown_ab3a36 --> GTMContainer: GTM workspace configuration (tags, triggers, variables)
GTMContainer -> GTMContainer: Initialize HTTP server on port 8080
Note over GTMContainer: 300s initial delay before probes begin
KubernetesHealthProbe -> GTMContainer: GET /healthz
GTMContainer --> KubernetesHealthProbe: HTTP 200 OK (ready)
KubernetesScheduler -> GTMContainer: Add to Service endpoints; begin routing traffic
```

## Related

- Architecture dynamic view: `dynamic-semGtmContainerStartup`
- Related flows: [Tag Event Processing](tag-event-processing.md), [Preview Session Debugging](preview-session-debugging.md)
