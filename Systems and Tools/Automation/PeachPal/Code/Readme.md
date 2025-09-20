# PeachPal | Multi Version – Vendor Beginning Balances Automation

## Overview

The **Multi** version extends the original _Singles_ automation by introducing the capability to handle **multiple invoices per vendor**, instead of being limited to a single balance entry.

## Key Differences in Operation

- **Search Key**

  - _Singles_: Looks up vendors by **partner code**.
  - _Multi_: Looks up vendors by **vendor name**.

- **Invoice Handling**

  - _Singles_: Enters a single balance record per vendor.
  - _Multi_: Supports **multiple invoice lines** for the same vendor, processing invoice number, date, balance, and account code directly from the data file.

- **Duplicate Management**

  - _Singles_: Assumes one record per vendor, no duplicate logic.
  - _Multi_: Detects when the current vendor matches the previous one, preventing unnecessary re-searching in the system.

- **Row Preparation**

  - _Singles_: Directly enters data into fields.
  - _Multi_: Clears out any pre-existing rows before inserting new invoice data, ensuring accurate entry for multiple lines.

- **Execution Flow**
  - _Singles_: Linear, one pass per vendor.
  - _Multi_: More dynamic, with conditional steps depending on whether the vendor changes or additional invoice rows need to be created.

## Capability Statement

The **Multi version** enables automation of **vendors with multiple beginning balance invoices**, improving efficiency and accuracy where more than one entry per vendor is required.

## Migration Note

The **Multi version** is a functional superset of _Singles_.

- If a vendor has only one invoice, the Multi version behaves the same as _Singles_.
- For vendors with multiple invoices, the Multi version ensures all lines are processed correctly.
- Existing _Singles_ use cases can be safely migrated to _Multi_ without loss of functionality.

---
