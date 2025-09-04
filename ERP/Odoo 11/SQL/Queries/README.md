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

## Force Uncancel Sales Order and Restore All Associated Records to Active States

- **Issue**: A sales order was forcibly cancelled using `cancel_sales_order()`, but needs to be reversed due to correction or reversal of business decision. Standard Odoo does not support restoring fully cancelled and posted transactions.
- **Solution**: Use a PostgreSQL function to restore the sales order and all related records to their original operational states.

  - **Function**:

    ```sql
    CREATE OR REPLACE FUNCTION uncancel_sales_order(so_name TEXT)
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

        -- Step 1: Restore Invoices
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
            UPDATE account_invoice SET state = 'paid' WHERE id = v_invoice_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'account_invoice';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;

            -- Restore journal entry
            UPDATE account_move
            SET state = 'posted'
            WHERE id = (SELECT move_id FROM account_invoice WHERE id = v_invoice_id);
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'account_move';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;
        END LOOP;

        -- Step 2: Restore Delivery Orders
        FOR v_picking_id IN
            SELECT id FROM stock_picking WHERE origin = so_name
        LOOP
            UPDATE stock_picking SET state = 'done' WHERE id = v_picking_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'stock_picking';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;

            UPDATE stock_move SET state = 'done' WHERE picking_id = v_picking_id;
            GET DIAGNOSTICS rows_affected = ROW_COUNT;
            table_name := 'stock_move';
            IF rows_affected > 0 THEN RETURN NEXT; END IF;
        END LOOP;

        -- Step 3: Restore Sales Order Lines
        UPDATE sale_order_line SET state = 'confirmed' WHERE order_id = v_so_id;
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        table_name := 'sale_order_line';
        IF rows_affected > 0 THEN RETURN NEXT; END IF;

        -- Step 4: Restore Sales Order
        UPDATE sale_order SET state = 'sent' WHERE id = v_so_id;
        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        table_name := 'sale_order';
        IF rows_affected > 0 THEN RETURN NEXT; END IF;

        RETURN;
    END;
    $$ LANGUAGE plpgsql;
    ```

  - **Usage**:
    ```sql
    SELECT * FROM uncancel_sales_order('SOV-51483');
    COMMIT;
    ```
  - **States Restored**:
    - `sale_order` → `'sent'`
    - `account_invoice` → `'paid'`
    - `account_move` → `'posted'`
    - `stock_picking` → `'done'`
    - `stock_move` → `'done'`
    - `sale_order_line` → `'confirmed'`
  - **Warning**: Only use on orders previously cancelled via `cancel_sales_order`. **`COMMIT;` is required** for persistence. This bypasses Odoo's audit trail — use only as last resort and with full backup.

---

## Incorrect Sales Price Due to Fixed Pricelist Rule Override for Specific Product

- **Issue**: Sales order lines for _Steel Nail – 5 CM_ display an incorrect unit price (`407.67`) instead of the expected list price (`113.044`), while similar products are unaffected. The discrepancy is caused by a hidden fixed-price pricelist rule.
- **Solution**: Identify and remove the overriding pricelist rule from the database.
  - **Step 1**: Locate the product template ID:
    ```sql
    SELECT id FROM product_template WHERE name = 'Steel Nail - 5 CM';
    ```
  - **Step 2**: Find the offending pricelist rule:
    ```sql
    SELECT * FROM product_pricelist_item
    WHERE product_tmpl_id = (
        SELECT id FROM product_template WHERE name = 'Steel Nail - 5 CM'
    );
    ```
  - **Step 3**: Confirm the rule has:
    - `compute_price = 'fixed'`
    - `fixed_price` set to the incorrect value (e.g., `407.67`)
    - Optional: Check if `date_start`/`date_end` makes it still active.
  - **Step 4**: Delete the rule:
    ```sql
    DELETE FROM product_pricelist_item WHERE id = <offending_rule_id>;
    ```
  - **Step 5**: Run `COMMIT;` to apply changes.
  - After deletion, the product will fall back to the correct list price from its pricelist or product configuration.
  - **Note**: A similar override was found for _Bottle handle_ — verify and clean as needed.

---

## Batch Set Payment Terms for Partners Missing Payment Terms Configuration

- **Issue**: Many customers lack configured payment terms, causing default or incorrect terms to be applied in quotations and invoices.
- **Solution**: Identify partners without payment terms and assign them in bulk using direct database operations.

  - **Step 1**: Find partners missing payment terms:
    ```sql
    SELECT
        p.id AS partner_id,
        p.name AS partner_name
    FROM res_partner p
    WHERE p.customer = TRUE
      AND p.id NOT IN (
        SELECT CAST(SUBSTRING(ip.res_id FROM 'res\.partner,(\d+)') AS INTEGER)
        FROM ir_property ip
        WHERE ip.name = 'property_payment_term_id'
          AND ip.type = 'many2one'
          AND ip.value_reference ~ '^account\.payment\.term,\d+$'
          AND ip.res_id ~ '^res\.partner,\d+$'
      );
    ```
  - **Step 2**: List available payment terms and note the target `id`:
    ```sql
    SELECT id, name FROM account_payment_term ORDER BY name;
    ```
  - **Step 3**: Create helper function to assign payment term:

    ```sql
    CREATE OR REPLACE FUNCTION set_payment_term_for_partner(partner_id INTEGER)
    RETURNS TEXT AS $$
    DECLARE
        field_id INTEGER;
        payment_term CONSTANT TEXT := 'account.payment.term,1'; -- Change '1' to desired term ID
    BEGIN
        -- Get fields_id for property_payment_term_id
        SELECT id INTO field_id
        FROM ir_model_fields
        WHERE model = 'res.partner' AND name = 'property_payment_term_id';

        IF field_id IS NULL THEN
            RAISE EXCEPTION 'Field property_payment_term_id not found in ir_model_fields';
        END IF;

        -- Insert property record (skip if exists)
        INSERT INTO ir_property (
            name, type, res_id, company_id, value_reference,
            fields_id, create_uid, create_date, write_uid, write_date
        )
        VALUES (
            'property_payment_term_id', 'many2one', 'res.partner,' || partner_id::TEXT,
            NULL, payment_term, field_id, 1, NOW(), 1, NOW()
        )
        ON CONFLICT DO NOTHING;

        RETURN 'Payment term set for partner ID ' || partner_id;
    END;
    $$ LANGUAGE plpgsql;
    ```

  - **Step 4**: Apply to target partners:
    ```sql
    SELECT set_payment_term_for_partner(id)
    FROM res_partner
    WHERE id IN (1679, 1697, ...); -- Replace with actual partner IDs
    ```
  - **Step 5**: Run `COMMIT;` to finalize changes.
  - After execution, new quotations for these partners will automatically use the assigned payment terms.

---
