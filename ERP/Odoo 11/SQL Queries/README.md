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

##
