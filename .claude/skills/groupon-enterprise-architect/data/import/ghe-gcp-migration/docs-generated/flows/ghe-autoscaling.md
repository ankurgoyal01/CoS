---
service: "ghe-gcp-migration"
title: "GHE Autoscaling"
generated: "2026-03-03"
type: flow
flow_name: "ghe-autoscaling"
flow_type: event-driven
trigger: "GCP Autoscaler detects CPU utilization on the github-core-manager instance group exceeds or drops below the 60% target"
participants:
  - "continuumGithubAutoscaler"
  - "continuumGithubInstanceGroup"
  - "continuumGithubVm"
architecture_ref: "dynamic-ghe-gcp-migration"
---

# GHE Autoscaling

## Summary

The GCP Autoscaler (`github-core-autoscaler`) continuously monitors CPU utilization across instances in the `github-core-manager` managed instance group. When average CPU utilization exceeds 60%, the autoscaler increases the target replica count (up to a maximum of 3). When utilization drops, it scales back down to a minimum of 1 instance. New instances are launched from the `github-core-template` instance template which includes the GHE 3.10.6 image and the external persistent disk attachment.

## Trigger

- **Type**: event (GCP Autoscaler metric threshold)
- **Source**: GCP Cloud Monitoring CPU utilization metric on `github-core-manager` instance group
- **Frequency**: Evaluated continuously by the GCP Autoscaler on a platform-managed polling interval

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| GCP Autoscaler | Monitors CPU metric and issues scale-up / scale-down signals | `continuumGithubAutoscaler` |
| GitHub Instance Group | Managed instance group that receives the resize target | `continuumGithubInstanceGroup` |
| GitHub Core VM | Running GHE instance(s); new instances launched from template | `continuumGithubVm` |
| GitHub External Disk | Persistent disk attached to instances via template | `continuumGithubExternalDisk` |

## Steps

1. **Autoscaler samples CPU utilization**: GCP Autoscaler (`github-core-autoscaler`) polls the average CPU utilization across all running instances in `github-core-manager` (zone `us-central1-b`)
   - From: `continuumGithubAutoscaler`
   - To: `GCP Cloud Monitoring API`
   - Protocol: GCP internal monitoring

2. **Threshold breach detected (scale-up path)**: Average CPU exceeds 60% target; autoscaler calculates required replica count (up to max 3)
   - From: `continuumGithubAutoscaler`
   - To: `continuumGithubInstanceGroup`
   - Protocol: GCP Autoscaler API signal

3. **Instance group manager launches new instance**: `github-core-manager` creates a new GCE instance from `github-core-template` (machine type `n2-highmem-16`, GHE 3.10.6 image, 500 GB boot disk, `github-core-external-disk` attached)
   - From: `continuumGithubInstanceGroup`
   - To: `GCP Compute Instances API`
   - Protocol: GCP REST API

4. **New instance boots and joins backend**: New GHE instance boots; GCP backend health check (`github-backend`) validates it is healthy; SSH TCP load balancer begins routing to it
   - From: `continuumGithubVm` (new instance)
   - To: `continuumSshLoadBalancer`
   - Protocol: TCP health check

5. **CPU returns below threshold (scale-down path)**: Average CPU drops below 60%; autoscaler calculates that fewer replicas are needed (down to min 1)
   - From: `continuumGithubAutoscaler`
   - To: `continuumGithubInstanceGroup`
   - Protocol: GCP Autoscaler API signal

6. **Instance group manager terminates excess instance**: `github-core-manager` gracefully terminates one of the running GHE instances; connections are drained before termination
   - From: `continuumGithubInstanceGroup`
   - To: `continuumGithubVm` (terminated instance)
   - Protocol: GCP instance lifecycle

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| New instance fails health check | GCP backend health check keeps instance out of rotation | Traffic only routes to healthy instances; autoscaler may attempt additional scale-up |
| Shared external disk conflict | Second instance template references same external disk (`github-core-external-disk`); GCP may reject attachment | Disk attachment fails; new instance may not start correctly — note: pd-standard is not multi-attach by default |
| Max replicas reached but CPU still high | Autoscaler cannot exceed `max_replicas = 3` | Instances remain at 3; CPU alert should be investigated manually |
| Scale-down interrupts active SSH session | GCP connection draining on backend service | Existing connections complete before instance termination (drain timeout from `timeout_sec = 30` on backend service) |

## Sequence Diagram

```
GCP_Monitoring -> github-core-autoscaler: CPU utilization sample > 60%
github-core-autoscaler -> github-core-manager: set target_size = N+1 (max 3)
github-core-manager -> GCP_Compute_API: create instance from github-core-template
GCP_Compute_API --> github-core-manager: new github-core instance running
github-core-manager -> github-backend_BackendService: register new instance
github-backend_BackendService -> GCP_HealthCheck: verify instance healthy (TCP 22)
GCP_HealthCheck --> github-backend_BackendService: healthy
github-backend_BackendService --> github-ssh-lb: new instance in rotation

GCP_Monitoring -> github-core-autoscaler: CPU utilization sample < 60%
github-core-autoscaler -> github-core-manager: set target_size = N-1 (min 1)
github-core-manager -> github-backend_BackendService: drain connections from instance
github-backend_BackendService --> github-core-manager: drain complete
github-core-manager -> GCP_Compute_API: delete excess instance
```

## Related

- Architecture dynamic view: `dynamic-ghe-gcp-migration`
- Related flows: [SSH Traffic Routing](ssh-traffic-routing.md), [Infrastructure Provisioning](infrastructure-provisioning.md)
