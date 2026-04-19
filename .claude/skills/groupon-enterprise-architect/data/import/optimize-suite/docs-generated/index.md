---
service: "optimize-suite"
title: "optimize-suite Documentation"
generated: "2026-03-03"
type: index
architecture_refs:
  system: "continuumSystem"
  containers: [continuumOptimizeSuiteClientBundle]
tech_stack:
  language: "JavaScript ES2015+"
  framework: "Webpack 5"
  runtime: "Node.js >=12.17"
---

# Optimize Suite Documentation

A browser-side JavaScript bundle that bundles client-side user tracking, A/B experimentation, and analytics for Groupon's I-Tier and standalone web applications.

## Contents

| Document | Description |
|----------|-------------|
| [Overview](overview.md) | Service identity, purpose, domain context, tech stack |
| [Architecture Context](architecture-context.md) | Containers, components, C4 references |
| [API Surface](api-surface.md) | Public JavaScript API exposed on `window.OptimizeSuite` |
| [Events](events.md) | Browser DOM events published and internal event bus |
| [Data Stores](data-stores.md) | Browser cookies and session/local storage usage |
| [Integrations](integrations.md) | External and internal library dependencies |
| [Configuration](configuration.md) | Runtime config object, cookies, and feature flags |
| [Flows](flows/index.md) | Process and flow documentation |
| [Deployment](deployment.md) | Build artifacts, npm publishing, Layout Service delivery |
| [Runbook](runbook.md) | Operations, monitoring, troubleshooting |

## Quick Facts

| Property | Value |
|----------|-------|
| Language | JavaScript ES2015+ |
| Framework | Webpack 5 |
| Runtime | Node.js >=12.17 |
| Build tool | Webpack 5 (`@grpn/itier-webpack`) |
| Platform | Continuum (I-Tier / Browser) |
| Domain | Optimize — User Tracking & Experimentation |
| Team | Optimize (optimize@groupon.com) |
