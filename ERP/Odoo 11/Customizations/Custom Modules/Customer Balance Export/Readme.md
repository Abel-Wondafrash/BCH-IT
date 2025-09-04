# Odoo 11 Custom Modules

This section documents custom-developed modules for Odoo 11, including new functionality, field extensions, and enhancements to support business-specific requirements.

---

## Added Customer Balance CSV Export Module for Accounting

- **Issue**: Finance teams lack a direct way to export customer balance reports (name, partner code, current balance) for reconciliation, analysis, or external reporting.
- **Solution**: Develop a custom module `customer_balance_export` that provides a downloadable CSV export via a new menu in the Accounting interface.

  - **Step 1**: Create controller `customer_balance_export/controllers/export_balance.py`:

    ```python
    from odoo import http
    from odoo.http import request
    import csv
    import io
    from datetime import datetime

    class ExportCustomerBalanceController(http.Controller):

        @http.route('/export/customers_balance', type='http', auth='user')
        def export_customers_balance(self, **kwargs):
            query = """
            SELECT
                p.name,
                p.partner_code,
                COALESCE(
                    p.inital_balance
                    + COALESCE((
                        SELECT SUM(am.amount_val)
                        FROM account_move am
                        WHERE am.partner = p.id
                          AND am.state = 'posted'
                          AND am.ref LIKE 'BKDP%'
                    ), 0)
                    - COALESCE((
                        SELECT SUM(amr.amount_val)
                        FROM account_move am
                        JOIN account_move amr ON amr.ref = CONCAT('reversal of: ', am.name)
                        WHERE am.partner = p.id
                          AND am.state = 'posted'
                          AND am.ref LIKE 'BKDP%'
                          AND amr.state = 'posted'
                          AND amr.partner = p.id
                    ), 0)
                    - COALESCE((
                        SELECT SUM(ai.amount_total)
                        FROM account_invoice ai
                        WHERE ai.partner_id = p.id
                          AND ai.state = 'paid'
                          AND ai.type = 'out_invoice'
                    ), 0)
                    + COALESCE((
                        SELECT SUM(ai.amount_total)
                        FROM account_invoice ai
                        WHERE ai.partner_id = p.id
                          AND ai.state = 'open'
                          AND ai.type = 'out_refund'
                    ), 0)
                , 0) AS current_balance
            FROM res_partner p
            WHERE p.customer = 't'
              AND p.active = 't'
              AND p.partner_code IS NOT NULL
              AND p.vat IS NOT NULL
            """
            request.cr.execute(query)
            rows = request.cr.fetchall()

            output = io.StringIO()
            writer = csv.writer(output)
            writer.writerow(['Name', 'Partner Code', 'Current Balance'])
            for row in rows:
                writer.writerow(row)

            csv_data = output.getvalue()
            output.close()

            timestamp = datetime.now().strftime("ccb-%b-%d-%Y-%H-%M-%S").upper()
            filename = f"{timestamp}.csv"

            return request.make_response(
                csv_data,
                headers=[
                    ('Content-Disposition', f'attachment; filename="{filename}"'),
                    ('Content-Type', 'text/csv')
                ]
            )
    ```

  - **Step 2**: Create menu and route:
    - In `views/menu.xml`:
      ```xml
      <menuitem id="menu_csv_export_root" name="CSV Export" parent="account.menu_finance"/>
      <menuitem id="menu_export_customer_balance" name="Customer Balance"
                parent="menu_csv_export_root" action="action_export_customer_balance"/>
      ```
    - In `controllers/main.py` or route registration, ensure route is loaded.
  - **Step 3**: Define `__manifest__.py`:
    ```python
    {
        'name': 'Customer Balance Export',
        'version': '1.0',
        'category': 'Accounting',
        'depends': ['account'],
        'data': [
            'views/menu.xml',
        ],
        'controllers': [
            'controllers/export_balance.py'
        ],
        'installable': True,
        'application': False,
    }
    ```
  - Restart Odoo and install the module.
  - After installation, users can access **Accounting > CSV Export > Customer Balance** to download a timestamped CSV with `Name`, `Partner Code`, and `Current Balance` for all active, valid customers.

---

## Added Customer Balance CSV Export via Dedicated Menu in Accounting

- **Issue**: Finance users require a reliable way to export customer balance data (name, partner code, current balance) for reconciliation and reporting, but no built-in export exists.
- **Solution**: Implement a custom module that adds a **Customer Balance** export menu under **CSV Export**, generating a downloadable CSV with calculated balances.

  - **Step 1**: Create `customer_balance_export/views/export_menu.xml`:

    ```xml
    <?xml version="1.0" encoding="utf-8"?>
    <odoo>
        <!-- Parent menu for CSV Export -->
        <record id="menu_account_csv_export" model="ir.ui.menu">
            <field name="name">CSV Export</field>
            <field name="parent_id" ref="account.menu_finance_reports"/>
            <field name="sequence">60</field>
        </record>

        <!-- URL action to trigger the CSV export -->
        <record id="action_url_export_customer_balance" model="ir.actions.act_url">
            <field name="name">Export Customer Balance</field>
            <field name="url">/export/customers_balance</field>
            <field name="target">self</field>
        </record>

        <!-- Menu item for Customer Balance CSV Export -->
        <record id="menu_export_customer_balance" model="ir.ui.menu">
            <field name="name">Customer Balance</field>
            <field name="parent_id" ref="menu_account_csv_export"/>
            <field name="action" ref="action_url_export_customer_balance"/>
            <field name="sequence">10</field>
        </record>
    </odoo>
    ```

  - **Step 2**: Define `customer_balance_export/__manifest__.py`:
    ```python
    {
        'name': 'Customer Balance Export',
        'version': '1.0',
        'category': 'Accounting',
        'depends': ['account'],
        'data': [
            'views/export_menu.xml'
        ],
        'installable': True,
        'application': False,
    }
    ```
  - **Step 3**: Ensure the controller (`controllers/export_balance.py`) is present and correctly computes the balance using initial balance, posted bank deposits, reversals, paid invoices, and open refunds.
  - **Step 4**: Restart Odoo, update the Apps list, and install **Customer Balance Export**.
  - **Usage**:
    - Go to **Accounting > Reporting > CSV Export > Customer Balance**
    - Click to download a timestamped CSV: `ccb-MMM-DD-YYYY-HH-MM-SS.csv`
    - Contains columns: _Name, Partner Code, Current Balance_
  - Provides a secure, user-friendly export accessible only to authorized finance users.

---
