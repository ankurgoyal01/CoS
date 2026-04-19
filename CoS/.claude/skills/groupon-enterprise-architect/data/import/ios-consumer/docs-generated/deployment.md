---
service: "ios-consumer"
title: Deployment
generated: "2026-03-03"
type: deployment
containerized: false
orchestration: "app-store"
environments: ["catfood", "production"]
---

# Deployment

## Overview

The iOS Consumer App is a native iOS application deployed via the Apple App Store (production) and Apple TestFlight (catfood/QA). Builds are produced by Jenkins CI at `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/` and triggered via the `mobilebot` Hubot bot in Slack. Fastlane automates code signing (via Fastlane Match), IPA generation, Nexus upload, and App Store submission. There is no Docker containerization or Kubernetes orchestration — the app runs on end-user iOS devices.

## Infrastructure

| Component | Technology | Details |
|-----------|-----------|---------|
| Container | None | Native iOS .ipa distribution |
| Orchestration | Apple App Store / TestFlight | Consumer distribution via `com.groupon.grouponapp` |
| Build server | Jenkins | `https://cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters` |
| CI automation | Fastlane | IPA build, code signing, App Store upload |
| Code signing | Fastlane Match | Certificates stored at `github.groupondev.com:mobile-consumer/ios-consumer-development-certificates` |
| Artifact storage | Nexus + Google Drive | IPA artifacts uploaded to Nexus; manual upload to Google Drive QA folder |
| CDN | Apple CDN | App Store binary distribution (Apple-managed) |

## Environments

| Environment | Purpose | Region | URL |
|-------------|---------|--------|-----|
| catfood | Internal QA/staging — distributed via TestFlight and AppTester | Global | TestFlight (App Store Connect) |
| production | Public release — distributed via Apple App Store | Global (APAC, EMEA, US/Canada) | `https://apps.apple.com` (com.groupon.grouponapp) |

## CI/CD Pipeline

- **Tool**: Jenkins (cloud-jenkins.groupondev.com) + Fastlane + mobilebot (Hubot)
- **Config**: `fastlane/` directory (Matchfile, Fastfile — not present in DSL inventory)
- **Trigger**: Manual via mobilebot command `@mobilebot upload {branch_name}` in `#mobile-ios-release` Slack channel; also `nx run mobile-expo:release:catfood/prod`

### Pipeline Stages

1. **Trigger**: mobilebot posts to Jenkins at `cloud-jenkins.groupondev.com/job/mobile/job/ios-consumer/buildWithParameters` with parameters: `LABEL=core-mobile-ios-app-submission`, `MODULE=MGA`, `GIT_REF={branch}`, `Build_Config=AppStore`, `UPLOAD_TO_ITUNES=true`, `BUILD_IPA=true`, `UPLOAD_TO_NEXUS=true`
2. **Code Signing**: Fastlane Match downloads certificates for `com.groupon.grouponapp`, `com.groupon.grouponapp.iMessage`, `com.groupon.grouponapp.notificationServiceExtension` from `ios-consumer-development-certificates` git repo
3. **Build**: Xcode builds the IPA with the specified `Build_Config` and `GIT_REF`
4. **Upload to Nexus**: Artifact stored for distribution
5. **Upload to TestFlight / App Store**: Fastlane uploads IPA to App Store Connect via `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`
6. **GPROD ticket**: Release engineer creates GPROD Jira change ticket via `@mobilebot gprod ios {Major.Minor} {BuildNumber}`
7. **QA verification**: TestRail milestone checked; release report pulled from Jira IOSCON project

### OTA Updates (MBNXT mode only)

When embedded as `groupon-legacy` in `next-pwa-app`, the MBNXT wrapper supports Expo OTA updates for JS-only changes. Native code changes still require a full App Store release.

## Scaling

| Dimension | Strategy | Config |
|-----------|----------|--------|
| Horizontal | Not applicable — mobile app | N/A |
| Memory | iOS OS-managed | N/A |
| CPU | iOS OS-managed | N/A |

## Resource Requirements

> Not applicable — the iOS app runs on end-user devices managed by the iOS operating system.

## Versioning

- **Release branches**: `release/Major.Minor` (e.g., `release/22.12`)
- **Patch releases**: `release/Major.Minor.Patch` (e.g., `release/22.12.1`)
- **Legacy app versioning (v2x)**: `25.x.y` format — launches legacy iOS app first
- **MBNXT versioning (v4x)**: `40.x.y` format — launches MBNXT app first
- **Build number**: Incremented for each TestFlight or App Store submission; tracked in `lastAppVersion` NSUserDefaults key
- **Branch cut detection**: mobilebot auto-updates stored release branch when it hears: `HURRAY.. New release branch "{branch}" has been cut`
