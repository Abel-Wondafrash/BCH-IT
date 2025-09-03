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

## Force Cancel Sales Order and All Associated Records via PostgreSQL Function

- **Issue**: Standard Odoo cancellation fails for fully processed sales orders (e.g., invoiced, delivered), requiring manual state changes across multiple models to achieve full cancellation.
- **Solution**: Use a PostgreSQL function to forcibly cancel a sales order and all related records in `sale_order`, `account_invoice`, `account_move`, `stock_picking`, `stock_move`, and `sale_order_line`.

  - **Function**:

    ```sql
    CREATE OR REPLACE FUNCTION cancel_sales_order(so_name TEXT)
    RETURNS TABLE(table_name TEXT, rows_affected BIGINT) AS $$
    DECLARE
        v_so_id INT;
        v_invoice_id INT;
        v_picking_id INT;
    BEGIN
        -- Get Sales Order ID
        SELECT id INTO v_so_id FROM sale_order WHERE name = so_name;
        IF v_so_id IS NULL THEN
            RAISE NOTICE 'Sales Order % not found.', so_name;
            RETURN;
        END IF;

        -- Step 1: Cancel Invoices
        FOR v_invoice_id IN
            SELECT ai.id
            FROM account_invoice ai
            JOIN account_invoice_line ail ON ail.invoice_id = ai.id
            WHERE ail.id IN (
                SELECT invoice_line_id
                FROM sale_order_line_invoice_rel
                WHERE order_line_id IN (
                    SELECT id FROM sale_order_line WHERE order_id = v_so_id
                )
            )
        LOOP
            UPDATE account_invoice SET state = 'cancel' WHERE id = v_invoice_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'account_invoice';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;

            -- Cancel associated journal entry
            UPDATE account_move
            SET state = 'cancel'
            WHERE id = (SELECT move_id FROM account_invoice WHERE id = v_invoice_id);
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'account_move';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;
        END LOOP;

        -- Step 2: Cancel Delivery Orders
        FOR v_picking_id IN
            SELECT id FROM stock_picking WHERE origin = so_name
        LOOP
            UPDATE stock_picking SET state = 'cancel' WHERE id = v_picking_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'stock_picking';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;

            UPDATE stock_move SET state = 'cancel' WHERE picking_id = v_picking_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'stock_move';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;
        END LOOP;

        -- Step 3: Cancel Sales Order Lines
        UPDATE sale_order_line SET state = 'cancel' WHERE order_id = v_so_id;
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        table_name := 'sale_order_line';
        IF rows_affected > 0 THEN RETURN NEXT; END IF;

        -- Step 4: Cancel Sales Order
        UPDATE sale_order SET state = 'cancel' WHERE id = v_so_id;
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        table_name := 'sale_order';
        IF rows_affected > 0 THEN RETURN NEXT; END IF;

        RETURN;
    END;
    $$ LANGUAGE plpgsql;
    ```

  - **Usage**:
    ```sql
    SELECT * FROM cancel_sales_order('SOV-61476');
    COMMIT;
    ```
  - **Warning**: Only use on **fully processed orders** where standard cancellation is blocked. **`COMMIT;` is required** for changes to persist. Use with extreme caution — bypasses Odoo business logic and constraints.

---
