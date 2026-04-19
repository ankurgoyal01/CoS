# Financial Systems Domain

> Tier 3 reference — factual, concise, architect-focused

## Overview

The Financial Systems & Analytics (FSA) domain comprises three core systems handling accounting, revenue reporting, and merchant payments across NA and INTL markets. All three systems ultimately feed into NetSuite as the general ledger. The domain bridges operational transaction data (from Orders, Inventory, Salesforce) with financial reporting and compliance requirements.

## Core Systems

| System | Full Name | Region | Responsibility | Data Sources | Technology |
|--------|-----------|--------|---------------|-------------|-----------|
| **JLA** | Journal Ledger Accounting | NA | Daily ETL pipeline, web application, event-based accounting, O2C (Order-to-Cash) reconciliation, NetSuite integration | Teradata Data Mart | Teradata → Data Mart, NetSuite API |
| **FDE** | Financial Data Engine | INTL | Daily revenue postings, AR (Accounts Receivable) reporting, Financial Data Mart | EDW via Falcon frontend | EDW, Falcon frontend, NetSuite |
| **FED** | Financial Entity Data | Global | Merchant payment calculation, P2P (Procure-to-Pay) bill creation, tax authority payments | Salesforce imports, Orders/Inventory unit data | Salesforce, Orders/Inventory, NetSuite |

JLA and FDE serve the same function (revenue accounting) but for different markets — JLA for North America, FDE for International. FED is the only global system, handling merchant-facing financial operations across all markets.

## Integration Flow

The three systems connect through distinct data pipelines, all converging on NetSuite:

**FED (Global — Merchant Payments):**
Salesforce contracts → FED imports merchant/deal contract data → Orders/Inventory provides unit-level transaction data → FED calculates invoices and merchant payment amounts → creates P2P bills → sends to NetSuite → tax authority payment processing.

**JLA (NA — Revenue Accounting):**
Teradata Data Mart provides transaction data → JLA reconciles PSP (Payment Service Provider) settlements from Adyen, PayPal, and Amex → generates journal entries for event-based accounting → posts to NetSuite. The O2C reconciliation ensures that orders, payments, and revenue recognition align.

**FDE (INTL — Revenue Reporting):**
EDW (Enterprise Data Warehouse) sources feed through the Falcon frontend → FDE produces daily revenue reports and AR postings → sends to NetSuite. The Financial Data Mart serves as an intermediate reporting layer for INTL revenue analysis.

## Source Links

| Document | Link |
|----------|------|
| Overall Architecture & Teams | [FSA](https://groupondev.atlassian.net/wiki/spaces/FSA/pages/81910136860/Overall+architecture+and+teams+overview) |
