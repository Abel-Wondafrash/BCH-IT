# Odoo 11 SQL Queries

This section contains SQL queries used to manage and troubleshoot Odoo 11 database issues, including invoice state updates, sales order exports, BOM duplicate resolution, and more.

⚠ Use with caution.

- Do not run any command you do not understand.
- Do not run any command unless you have a backup you can revert to

---

## Set an OPEN Invoice state to Paid

--SELECT \* FROM account_invoice WHERE origin='SOV-938'
--UPDATE account_invoice SET state='paid' WHERE origin='SOV-938'

---

## Find Duplicate Active Bill of Materials (BOMs) by Product Template and Code

- **Purpose**: Identifies BOM records that share the same `product_tmpl_id` and `code`, which can cause system errors due to ambiguous BOM lookups (e.g., "Expected singleton" during MO validation).
- **Use Case**: Diagnose BOM-related errors in manufacturing, especially when multiple BOMs exist for the same product unintentionally.
- **SQL Query**:
  ```sql
  SELECT id, product_tmpl_id, product_id, code, type, active
  FROM mrp_bom
  WHERE product_tmpl_id IN (
      SELECT product_tmpl_id
      FROM mrp_bom
      GROUP BY product_tmpl_id, code
      HAVING COUNT(*) > 1
  )
  ORDER BY product_tmpl_id, code;
  ```
- **Output**: Lists all BOMs linked to product templates with duplicate entries under the same code, enabling cleanup via archiving obsolete versions.

---
