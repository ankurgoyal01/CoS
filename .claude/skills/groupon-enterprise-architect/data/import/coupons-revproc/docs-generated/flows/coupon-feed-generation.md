---
service: "coupons-revproc"
title: "Coupon Feed Generation and Upload"
generated: "2026-03-03"
type: flow
flow_name: "coupon-feed-generation"
flow_type: scheduled
trigger: "Kubernetes cron job fires daily at 04:00 UTC (schedule: 0 4 * * *)"
participants:
  - "continuumCouponsRevprocService"
  - "revproc_feedService"
  - "revproc_feedExporter"
  - "revproc_sftpClient"
  - "continuumCouponsRevprocDatabase"
architecture_ref: "dynamic-coupons-revproc-coupon-feed-generation"
---

# Coupon Feed Generation and Upload

## Summary

The Coupon Feed Generation and Upload flow runs as a standalone Kubernetes cron job (`coupons-feed-generator`) once daily at 04:00 UTC. It reads processed transactions from MySQL, builds coupon feed export files for both the VoucherCloud and Groupon feed domains, and uploads the resulting files to the Dotidot SFTP server at IP `178.77.214.157` on port 22. The cron job runs in the same Docker image as the main API service, selected by `JTIER_RUN_CMD=coupons-feed-generator --`. An egress-only network policy restricts outbound traffic to the Dotidot SFTP endpoint.

## Trigger

- **Type**: schedule
- **Source**: Kubernetes CronJob resource (`jobSchedule: "0 4 * * *"`)
- **Frequency**: Daily at 04:00 UTC

## Participants

| Participant | Role in Flow | Architecture Ref |
|-------------|-------------|-----------------|
| Kubernetes CronJob | Schedules and launches the feed generator container | Infrastructure |
| Coupons Feed Service (`revproc_feedService`) | Reads processed transactions from MySQL and builds feed content | `revproc_feedService` |
| MySQL | Source of processed transaction records for feed generation | `continuumCouponsRevprocDatabase` |
| Coupons Feed Exporter (`revproc_feedExporter`) | Assembles feed files (VoucherCloud and Groupon domains) and triggers SFTP upload | `revproc_feedExporter` |
| SFTP Client (`revproc_sftpClient`) | Uploads generated feed files to Dotidot SFTP server | `revproc_sftpClient` |
| Dotidot SFTP Server | External destination for coupon feed files | External (IP: 178.77.214.157, port 22) |

## Steps

1. **Container starts**: Kubernetes CronJob launches the `coupons-feed-generator` container. The `CouponsFeedGeneratorCommand` Dropwizard command is executed.
   - From: Kubernetes CronJob
   - To: `revproc_feedExporter`
   - Protocol: Container exec

2. **Read processed transactions**: `CouponsFeedService` queries MySQL via `revproc_transactionDao` to retrieve the relevant processed transactions for the feed period (date range determined by `CouponsFeedConfiguration`).
   - From: `revproc_feedService`
   - To: `continuumCouponsRevprocDatabase`
   - Protocol: JDBC

3. **Build VoucherCloud feed**: `CouponsFeedExporter.buildExportContent` calls `CouponsFeedService` to generate the VoucherCloud-domain feed payload using `couponsFeed.voucherCloudFeed` configuration (country-specific settings from `CouponsFeedCountryConfiguration` and `CouponsFeedDomainConfiguration`).
   - From: `revproc_feedExporter`
   - To: `revproc_feedService`
   - Protocol: Direct

4. **Build Groupon feed**: `CouponsFeedExporter` calls `CouponsFeedService` again for the Groupon-domain feed using `couponsFeed.grouponFeed` configuration.
   - From: `revproc_feedExporter`
   - To: `revproc_feedService`
   - Protocol: Direct

5. **Upload feeds via SFTP**: `CouponsFeedExporter` calls `SftpClient` (backed by JSch) to connect to the Dotidot SFTP server (`dotidot.sftpCredentials.host` / port) and upload both feed files.
   - From: `revproc_feedExporter`
   - To: `revproc_sftpClient`
   - Protocol: Direct

6. **Establish SFTP connection and transfer file**: `SftpClient` opens a JSch SSH session using the configured host, port, user, and password credentials, then transfers the feed file.
   - From: `revproc_sftpClient`
   - To: Dotidot SFTP Server (178.77.214.157:22)
   - Protocol: SFTP (JSch over TCP/22)

7. **Container exits**: On completion (or error), the container writes to `/tmp/signals/terminated` and exits.
   - From: Container
   - To: Kubernetes
   - Protocol: Container exit

## Error Handling

| Error Scenario | Handling Strategy | Outcome |
|---------------|-------------------|---------|
| MySQL read failure | Exception logged; feed not generated | No file uploaded; retry at next daily run |
| Feed build failure | Exception logged | Partial or no upload; retry at next daily run |
| SFTP connection failure | JSch exception logged | Files not uploaded; Dotidot does not receive data for that day |
| SFTP authentication failure | JSch exception logged | Files not uploaded |
| Container OOM | Kubernetes marks job failed | Feed not uploaded; no automatic retry until next scheduled run |

## Sequence Diagram

```
KubernetesCronJob -> CouponsFeedGeneratorContainer: exec (04:00 UTC daily)
CouponsFeedGeneratorContainer -> MySQL: SELECT processed_transactions JDBC
MySQL --> CouponsFeedGeneratorContainer: List<ProcessedTransaction>
CouponsFeedGeneratorContainer -> CouponsFeedService: buildVoucherCloudFeed()
CouponsFeedService --> CouponsFeedGeneratorContainer: feed content
CouponsFeedGeneratorContainer -> CouponsFeedService: buildGrouponFeed()
CouponsFeedService --> CouponsFeedGeneratorContainer: feed content
CouponsFeedGeneratorContainer -> SftpClient: upload(voucherCloudFeedFile)
SftpClient -> DotidotSFTP: SSH + SFTP PUT (TCP/22)
DotidotSFTP --> SftpClient: ACK
CouponsFeedGeneratorContainer -> SftpClient: upload(grouponFeedFile)
SftpClient -> DotidotSFTP: SSH + SFTP PUT (TCP/22)
DotidotSFTP --> SftpClient: ACK
CouponsFeedGeneratorContainer -> Filesystem: touch /tmp/signals/terminated
KubernetesCronJob <-- CouponsFeedGeneratorContainer: exit 0
```

## Related

- Architecture dynamic view: `dynamic-coupons-revproc-coupon-feed-generation`
- Related flows: [Redirect Cache Prefill](redirect-cache-prefill.md)
